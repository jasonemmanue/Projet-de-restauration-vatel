"""Notifications : écrites dans la transaction de l'événement, poussées par FCM après sa validation.

`notifier` ne fait aucun appel réseau : il ajoute les lignes et inscrit l'envoi à faire après la
validation. L'envoi relit ces lignes dans sa propre session, appareil par appareil, et oublie les jetons
que Firebase ne connaît plus.
"""

import logging
import uuid
from collections.abc import Iterable
from datetime import UTC, datetime
from typing import Any

import httpx
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Configuration
from app.core.messages_notifications import NOTIFICATIONS
from app.models import Appareil, LienParentEnfant, Notification, PorteMonnaie, Utilisateur
from app.services import fcm

journal = logging.getLogger("vatel.notifications")


def _textes(type_: str, langue: str, valeurs: dict[str, Any]) -> tuple[str, str]:
    modeles = NOTIFICATIONS[type_]
    titre, corps = modeles.get(langue) or modeles["fr"]
    return titre.format(**valeurs), corps.format(**valeurs)


async def notifier(
    session: AsyncSession,
    destinataires: Iterable[uuid.UUID],
    type_: str,
    valeurs: dict[str, Any],
    donnees: dict[str, Any] | None = None,
) -> int:
    """Ajoute une notification par destinataire et programme l'envoi push après la validation."""
    ids = list(dict.fromkeys(destinataires))
    if not ids:
        return 0
    comptes = (
        await session.execute(select(Utilisateur.id, Utilisateur.langue).where(Utilisateur.id.in_(ids)))
    ).all()
    avec_appareil = set(
        (await session.scalars(select(Appareil.utilisateur_id).where(Appareil.utilisateur_id.in_(ids)))).all()
    )
    lignes = []
    for utilisateur_id, langue in comptes:
        titre, corps = _textes(type_, langue, valeurs)
        ligne = Notification(
            destinataire_id=utilisateur_id,
            type=type_,
            titre=titre,
            corps=corps,
            donnees=donnees or {},
            envoi_push="en_attente" if utilisateur_id in avec_appareil else "non_demande",
        )
        session.add(ligne)
        lignes.append(ligne)
    await session.flush()
    a_pousser = [ligne.id for ligne in lignes if ligne.envoi_push == "en_attente"]
    if a_pousser:
        etat = session.info.setdefault("a_pousser", [])
        etat.extend(a_pousser)
        if "pousser" not in session.info:
            session.info["pousser"] = True
            session.info.setdefault("apres_validation", []).append(lambda: _pousser_depuis(session))
    return len(lignes)


async def _pousser_depuis(session: AsyncSession) -> None:
    ids = session.info.pop("a_pousser", [])
    session.info.pop("pousser", None)
    application = session.info.get("application")
    if application is None or not ids:
        return
    await pousser(
        application.state.fabrique_sessions, application.state.config, application.state.client_http, ids
    )


async def pousser(
    fabrique: async_sessionmaker[AsyncSession],
    config: Configuration,
    client: httpx.AsyncClient,
    ids: list[uuid.UUID],
) -> None:
    """Envoie par FCM les notifications données ; un échec est noté, jamais remonté à l'utilisateur."""
    if not config.fcm_actif or not config.firebase_compte_service:
        return
    try:
        compte = fcm.lire_compte(config.firebase_compte_service, config.firebase_projet_id)
    except (ValueError, KeyError):
        journal.error("compte de service Firebase illisible")
        return
    async with fabrique() as session, session.begin():
        notifications = (await session.scalars(select(Notification).where(Notification.id.in_(ids)))).all()
        for notification in notifications:
            appareils = (
                await session.scalars(
                    select(Appareil).where(
                        Appareil.utilisateur_id == notification.destinataire_id,
                        Appareil.jeton_fcm.is_not(None),
                    )
                )
            ).all()
            reussi = False
            for appareil in appareils:
                donnees = {"type": notification.type, "notification_id": str(notification.id)} | {
                    k: str(v) for k, v in (notification.donnees or {}).items()
                }
                try:
                    await fcm.envoyer(
                        client,
                        compte,
                        appareil.jeton_fcm or "",
                        notification.titre,
                        notification.corps,
                        donnees,
                    )
                    reussi = True
                except fcm.JetonInvalideError:
                    await session.execute(delete(Appareil).where(Appareil.id == appareil.id))
                except httpx.HTTPError as exc:
                    journal.warning("envoi FCM refusé : %s", type(exc).__name__)
            notification.envoi_push = "envoye" if reussi else "echoue"
            notification.envoye_le = datetime.now(UTC) if reussi else None


async def alerter_solde_bas(session: AsyncSession, convive: Utilisateur, seuil_defaut: int) -> None:
    """Prévient le convive et ses parents liés si son solde passe sous son seuil d'alerte."""
    solde = await session.scalar(
        select(PorteMonnaie.solde_cache_xof).where(PorteMonnaie.utilisateur_id == convive.id)
    )
    seuil = convive.seuil_alerte_solde if convive.seuil_alerte_solde is not None else seuil_defaut
    if solde is None or solde >= seuil:
        return
    parents = await session.scalars(
        select(LienParentEnfant.parent_id).where(
            LienParentEnfant.enfant_id == convive.id, LienParentEnfant.etat == "actif"
        )
    )
    await notifier(
        session, [convive.id, *parents.all()], "solde_bas", {"prenom": convive.prenom, "solde": solde}
    )
