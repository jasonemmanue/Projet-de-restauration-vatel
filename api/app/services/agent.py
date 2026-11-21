"""Service au comptoir : ticket QR signé, scan par l'agent, service du jour, scans faits hors ligne.

Le QR porte le code du ticket suivi de sa signature HMAC : un ticket inventé ou recopié de travers est
reconnu sans appel à la base. Chaque scan est rangé dans file_scans sous sa clé unique : un renvoi, en ligne
ou depuis la file hors ligne, rend le résultat déjà enregistré sans servir deux fois.
"""

import uuid
from datetime import UTC, date, datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.hachage import egal_en_temps_constant, hmac_hex
from app.models import FileScan, LigneReservation, Plat, Reservation, Utilisateur
from app.services.menus_lecture import ETATS_QUI_COMPTENT

LONGUEUR_SIGNATURE = 16


def contenu_qr(secret: str, code_ticket: str) -> str:
    """Contenu du QR : le code du ticket et sa signature, séparés par un point."""
    return f"{code_ticket}.{hmac_hex(secret, 'ticket:' + code_ticket)[:LONGUEUR_SIGNATURE]}"


def lire_qr(secret: str, contenu: str) -> str | None:
    """Rend le code du ticket si la signature est juste, None sinon."""
    code, _, signature = contenu.strip().rpartition(".")
    if not code or len(signature) != LONGUEUR_SIGNATURE:
        return None
    attendue = hmac_hex(secret, "ticket:" + code)[:LONGUEUR_SIGNATURE]
    return code if egal_en_temps_constant(signature, attendue) else None


async def _plats(session: AsyncSession, reservation_id: uuid.UUID) -> list[dict[str, Any]]:
    lignes = await session.execute(
        select(Plat.nom_fr, Plat.nom_en, LigneReservation.service, LigneReservation.quantite)
        .join(LigneReservation, LigneReservation.plat_id == Plat.id)
        .where(LigneReservation.reservation_id == reservation_id)
    )
    return [{"nom_fr": fr, "nom_en": en, "service": s, "quantite": q} for fr, en, s, q in lignes.all()]


def _nom_court(utilisateur: Utilisateur) -> str:
    """Prénom et initiale du nom : assez pour reconnaître au comptoir, sans tout afficher."""
    initiale = f" {utilisateur.nom[:1]}." if utilisateur.nom else ""
    return f"{utilisateur.prenom or utilisateur.nom_complet}{initiale}"


async def scanner(
    session: AsyncSession,
    secret: str,
    agent_id: uuid.UUID,
    contenu: str,
    scanne_le: datetime,
    cle_unique: str,
) -> dict[str, Any]:
    """Traite un scan : sert, ou dit pourquoi le ticket est refusé ; un renvoi rend le même résultat."""
    deja = (
        await session.execute(select(FileScan).where(FileScan.cle_unique == cle_unique))
    ).scalar_one_or_none()
    if deja is not None:
        return {"resultat": deja.resultat, "detail": deja.detail, "rejoue": True}
    code = lire_qr(secret, contenu)
    reservation = None
    if code is not None:
        reservation = (
            await session.execute(
                select(Reservation).where(Reservation.code_ticket == code).with_for_update()
            )
        ).scalar_one_or_none()
    reponse: dict[str, Any] = {"rejoue": False}
    if reservation is None:
        resultat, detail = "inconnu", ""
    elif reservation.etat in ("annulee", "supprimee"):
        resultat, detail = "annule", ""
    elif reservation.etat == "servie":
        resultat, detail = "deja_servi", reservation.servie_le.isoformat() if reservation.servie_le else ""
    elif reservation.date_service != scanne_le.astimezone(UTC).date():
        resultat, detail = "mauvais_jour", reservation.date_service.isoformat()
    else:
        reservation.etat = "servie"
        reservation.servie_le = scanne_le
        reservation.servie_par = agent_id
        resultat, detail = "accepte", ""
    if reservation is not None:
        convive = await session.get(Utilisateur, reservation.convive_id)
        reponse |= {
            "convive": _nom_court(convive) if convive else "",
            "date_service": reservation.date_service.isoformat(),
            "plats": await _plats(session, reservation.id),
        }
    session.add(
        FileScan(
            agent_id=agent_id,
            code_ticket=(code or contenu)[:200],
            reservation_id=reservation.id if reservation else None,
            scanne_le=scanne_le,
            cle_unique=cle_unique,
            resultat=resultat,
            detail=detail,
        )
    )
    await session.flush()
    return reponse | {"resultat": resultat, "detail": detail}


async def service_du_jour(session: AsyncSession, jour: date) -> dict[str, Any]:
    """Attendus, servis et restants du jour ; sans créneau, le convive vient quand il veut."""
    par_etat = dict(
        (
            await session.execute(
                select(Reservation.etat, func.count())
                .where(Reservation.date_service == jour)
                .group_by(Reservation.etat)
            )
        ).all()
    )
    attendus = sum(int(par_etat.get(e, 0)) for e in ETATS_QUI_COMPTENT if e != "supprimee")
    servis = int(par_etat.get("servie", 0))
    return {"date": jour.isoformat(), "attendus": attendus, "servis": servis, "restants": attendus - servis}


async def liste_hors_ligne(session: AsyncSession, secret: str, jour: date) -> list[dict[str, Any]]:
    """Tickets du jour à garder sur l'appareil de l'agent, pour servir sans réseau."""
    lignes = await session.execute(
        select(Reservation, Utilisateur)
        .join(Utilisateur, Utilisateur.id == Reservation.convive_id)
        .where(Reservation.date_service == jour, Reservation.etat.in_(("confirmee", "servie")))
        .order_by(Utilisateur.prenom)
    )
    return [
        {
            "contenu_qr": contenu_qr(secret, reservation.code_ticket),
            "convive": _nom_court(utilisateur),
            "plats": await _plats(session, reservation.id),
            "etat": reservation.etat,
        }
        for reservation, utilisateur in lignes.all()
    ]
