"""Back office : commandes du jour pour la cuisine et tableau de bord de la cantine.

Tout se calcule à la demande sur les commandes, leurs lignes et les mouvements, avec les index existants.
Une commande annulée avant le gel ne compte ni en parts ni en recettes ; une commande supprimée après le gel
ou non réclamée compte : elle a été préparée et payée.
"""

from datetime import date, timedelta
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import LigneReservation, Plat, Reservation
from app.models.menus import SERVICES
from app.services.menus_lecture import ETATS_QUI_COMPTENT


async def commandes_du_jour(session: AsyncSession, jour: date) -> dict[str, Any]:
    """Parts à préparer pour un jour, par service puis par plat, et nombre de commandes."""
    lignes = await session.execute(
        select(
            LigneReservation.service, Plat.id, Plat.nom_fr, Plat.nom_en, func.sum(LigneReservation.quantite)
        )
        .join(Reservation, Reservation.id == LigneReservation.reservation_id)
        .join(Plat, Plat.id == LigneReservation.plat_id)
        .where(Reservation.date_service == jour, Reservation.etat.in_(ETATS_QUI_COMPTENT))
        .group_by(LigneReservation.service, Plat.id, Plat.nom_fr, Plat.nom_en)
        .order_by(func.sum(LigneReservation.quantite).desc())
    )
    services: dict[str, list[dict[str, Any]]] = {s: [] for s in SERVICES}
    for service, plat_id, nom_fr, nom_en, parts in lignes.all():
        services[service].append(
            {"plat_id": str(plat_id), "nom_fr": nom_fr, "nom_en": nom_en, "parts": int(parts)}
        )
    nombre = await session.scalar(
        select(func.count())
        .select_from(Reservation)
        .where(Reservation.date_service == jour, Reservation.etat.in_(ETATS_QUI_COMPTENT))
    )
    return {
        "date": jour.isoformat(),
        "commandes": int(nombre or 0),
        "total_parts": sum(p["parts"] for liste in services.values() for p in liste),
        "services": services,
    }


async def tableau_de_bord(session: AsyncSession, du: date, au: date) -> dict[str, Any]:
    """Chiffres d'une période : commandes par état, recettes, plats les plus commandés, courbe par jour."""
    periode = (Reservation.date_service >= du, Reservation.date_service <= au)
    par_etat = dict(
        (
            await session.execute(
                select(Reservation.etat, func.count()).where(*periode).group_by(Reservation.etat)
            )
        ).all()
    )
    recettes = await session.scalar(
        select(func.coalesce(func.sum(Reservation.total_xof), 0)).where(
            *periode, Reservation.etat.in_(ETATS_QUI_COMPTENT)
        )
    )
    top = await session.execute(
        select(Plat.id, Plat.nom_fr, Plat.nom_en, func.sum(LigneReservation.quantite).label("parts"))
        .join(LigneReservation, LigneReservation.plat_id == Plat.id)
        .join(Reservation, Reservation.id == LigneReservation.reservation_id)
        .where(*periode, Reservation.etat.in_(ETATS_QUI_COMPTENT))
        .group_by(Plat.id, Plat.nom_fr, Plat.nom_en)
        .order_by(func.sum(LigneReservation.quantite).desc())
        .limit(5)
    )
    jours = dict(
        (r[0], (int(r[1]), int(r[2])))
        for r in (
            await session.execute(
                select(
                    Reservation.date_service, func.count(), func.coalesce(func.sum(Reservation.total_xof), 0)
                )
                .where(*periode, Reservation.etat.in_(ETATS_QUI_COMPTENT))
                .group_by(Reservation.date_service)
            )
        ).all()
    )
    courbe = []
    jour = du
    while jour <= au:
        commandes, montant = jours.get(jour, (0, 0))
        courbe.append({"date": jour.isoformat(), "commandes": commandes, "recettes_xof": montant})
        jour += timedelta(days=1)
    servis = int(par_etat.get("servie", 0))
    non_reclames = int(par_etat.get("non_reclamee", 0))
    return {
        "du": du.isoformat(),
        "au": au.isoformat(),
        "commandes": sum(int(par_etat.get(e, 0)) for e in ETATS_QUI_COMPTENT),
        "servies": servis,
        "non_reclamees": non_reclames,
        "annulees": int(par_etat.get("annulee", 0)),
        "supprimees": int(par_etat.get("supprimee", 0)),
        "taux_presence": round(servis / (servis + non_reclames), 3) if servis + non_reclames else None,
        "recettes_xof": int(recettes or 0),
        "plats_les_plus_commandes": [
            {"plat_id": str(p), "nom_fr": fr, "nom_en": en, "parts": int(n)} for p, fr, en, n in top.all()
        ],
        "courbe": courbe,
    }
