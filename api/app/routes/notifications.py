"""Routes /api/v1/appareils, /notifications et /admin/notifications.

Chaque compte n'atteint que ses appareils et ses notifications. L'envoi ciblé de l'admin est journalisé.
"""

import uuid
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import func, select, update

from app.core.dependances import Admin, UtilisateurCourant, UtilisateurVerifie, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Appareil, Notification, Utilisateur
from app.services.journal import ecrire_journal
from app.services.notifications import notifier

routeur = APIRouter(prefix="/api/v1", tags=["notifications"])


class AppareilEntree(BaseModel):
    """Corps de POST /appareils."""

    jeton_fcm: str = Field(min_length=20, max_length=4096)
    plateforme: Literal["android", "ios", "web"]
    modele: str = Field(default="", max_length=120)
    version_app: str = Field(default="", max_length=40)


class CibleEntree(BaseModel):
    """Qui reçoit un envoi de l'admin : un rôle, un statut, ou une liste de comptes."""

    role: Literal["convive", "parent", "agent", "admin"] | None = None
    statut: Literal["eleve", "etudiant", "employe", "autre"] | None = None
    utilisateur_ids: list[uuid.UUID] = Field(default_factory=list, max_length=1000)


class EnvoiEntree(BaseModel):
    """Corps de POST /admin/notifications."""

    cible: CibleEntree
    titre: str = Field(min_length=1, max_length=80)
    corps: str = Field(min_length=1, max_length=400)


@routeur.post("/appareils", status_code=201)
async def enregistrer(
    corps: AppareilEntree, connecte: UtilisateurCourant, session: SessionBase
) -> dict[str, str]:
    """Enregistre l'appareil du compte connecté ; un jeton déjà connu change de propriétaire."""
    appareil = (
        await session.execute(select(Appareil).where(Appareil.jeton_fcm == corps.jeton_fcm).with_for_update())
    ).scalar_one_or_none()
    if appareil is None:
        appareil = Appareil(
            utilisateur_id=connecte.utilisateur.id, session_id=connecte.session_id, **corps.model_dump()
        )
        session.add(appareil)
    else:
        appareil.utilisateur_id = connecte.utilisateur.id
        appareil.session_id = connecte.session_id
        appareil.plateforme = corps.plateforme
        appareil.modele = corps.modele
        appareil.version_app = corps.version_app
    await session.flush()
    return {"id": str(appareil.id)}


@routeur.delete("/appareils/{appareil_id}")
async def oublier(
    appareil_id: uuid.UUID, connecte: UtilisateurCourant, session: SessionBase
) -> dict[str, bool]:
    """Oublie un appareil du compte : il ne reçoit plus de notification."""
    appareil = await session.get(Appareil, appareil_id)
    if appareil is None or appareil.utilisateur_id != connecte.utilisateur.id:
        raise ErreurApi("introuvable", 404)
    await session.delete(appareil)
    return {"supprime": True}


@routeur.get("/notifications")
async def lister(
    connecte: UtilisateurVerifie,
    session: SessionBase,
    page: Annotated[int, Query(ge=1)] = 1,
    taille: Annotated[int, Query(ge=1, le=100)] = 20,
) -> dict[str, Any]:
    """Les notifications du compte, les plus récentes d'abord, avec le nombre de non lues."""
    condition = Notification.destinataire_id == connecte.utilisateur.id
    total = await session.scalar(select(func.count()).select_from(Notification).where(condition))
    non_lues = await session.scalar(
        select(func.count()).select_from(Notification).where(condition, Notification.lue_le.is_(None))
    )
    lignes = await session.scalars(
        select(Notification)
        .where(condition)
        .order_by(Notification.cree_le.desc())
        .offset((page - 1) * taille)
        .limit(taille)
    )
    elements = [
        {
            "id": str(n.id),
            "type": n.type,
            "titre": n.titre,
            "corps": n.corps,
            "donnees": n.donnees,
            "lue": n.lue_le is not None,
            "cree_le": n.cree_le.isoformat(),
        }
        for n in lignes.all()
    ]
    return {
        "elements": elements,
        "page": page,
        "taille": taille,
        "total": int(total or 0),
        "non_lues": int(non_lues or 0),
    }


@routeur.post("/notifications/{notification_id}/lue")
async def lire(
    notification_id: uuid.UUID, connecte: UtilisateurVerifie, session: SessionBase
) -> dict[str, bool]:
    """Marque une notification du compte comme lue."""
    resultat = await session.execute(
        update(Notification)
        .where(Notification.id == notification_id, Notification.destinataire_id == connecte.utilisateur.id)
        .values(lue_le=func.coalesce(Notification.lue_le, func.now()))
    )
    if resultat.rowcount == 0:
        raise ErreurApi("introuvable", 404)
    return {"lue": True}


@routeur.post("/notifications/toutes-lues")
async def tout_lire(connecte: UtilisateurVerifie, session: SessionBase) -> dict[str, int]:
    """Marque toutes les notifications du compte comme lues."""
    resultat = await session.execute(
        update(Notification)
        .where(Notification.destinataire_id == connecte.utilisateur.id, Notification.lue_le.is_(None))
        .values(lue_le=func.now())
    )
    return {"lues": int(resultat.rowcount or 0)}


@routeur.post("/admin/notifications")
async def envoyer(corps: EnvoiEntree, admin: Admin, request: Request, session: SessionBase) -> dict[str, int]:
    """Envoie un message aux comptes ciblés ; une cible vide est refusée, jamais « tout le monde »."""
    cible = corps.cible
    if not cible.role and not cible.statut and not cible.utilisateur_ids:
        raise ErreurApi("cible_vide", 422)
    condition = [Utilisateur.actif.is_(True), Utilisateur.supprime_le.is_(None)]
    if cible.role:
        condition.append(Utilisateur.role == cible.role)
    if cible.statut:
        condition.append(Utilisateur.statut_convive == cible.statut)
    if cible.utilisateur_ids:
        condition.append(Utilisateur.id.in_(cible.utilisateur_ids))
    ids = (await session.scalars(select(Utilisateur.id).where(*condition))).all()
    nombre = await notifier(session, ids, "message_admin", {"titre": corps.titre, "corps": corps.corps})
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "notification_ciblee",
        "notification",
        None,
        None,
        {"cible": cible.model_dump(mode="json"), "destinataires": nombre},
        adresse_client(request),
    )
    return {"destinataires": nombre}
