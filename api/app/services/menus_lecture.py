"""Lecture des menus : la semaine vue par un convive, un parent ou un agent, et la semaine de l'admin.

Seuls les menus publiés sont visibles hors de l'admin. Le prix vient du serveur, selon le profil du compte ;
les portions restantes et le moment du gel sont calculés ici, jamais par le client.
"""

import uuid
from collections import defaultdict
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Avis, LigneReservation, Menu, MenuPlat, Plat, Reservation, Tarif, Utilisateur
from app.models.menus import SERVICES
from app.schemas.menus import JourSortie, PlatDuJourSortie, SemaineSortie
from app.services.catalogue import chemin_photo
from app.services.parametres import lire_parametres
from app.services.regles_menus import (
    TarifLu,
    allergenes_en_commun,
    lire_heure,
    moment_du_gel,
    portions_restantes,
    prix_du_jour,
    semaine,
)

# Une commande annulée avant le gel libère sa part ; toutes les autres la gardent, servie ou non.
ETATS_QUI_COMPTENT = ("confirmee", "servie", "supprimee", "non_reclamee")


async def _portions_commandees(session: AsyncSession, menu_ids: list[uuid.UUID]) -> dict[tuple, int]:
    if not menu_ids:
        return {}
    lignes = await session.execute(
        select(Reservation.menu_id, LigneReservation.plat_id, func.sum(LigneReservation.quantite))
        .join(Reservation, Reservation.id == LigneReservation.reservation_id)
        .where(Reservation.menu_id.in_(menu_ids), Reservation.etat.in_(ETATS_QUI_COMPTENT))
        .group_by(Reservation.menu_id, LigneReservation.plat_id)
    )
    return {(m, p): int(n) for m, p, n in lignes.all()}


async def _notes(session: AsyncSession, plat_ids: set[uuid.UUID]) -> dict[uuid.UUID, float]:
    if not plat_ids:
        return {}
    moyenne = func.avg(
        (Avis.note_gout + Avis.note_quantite + Avis.note_temperature + Avis.note_attente) / 4.0
    )
    lignes = await session.execute(
        select(Avis.plat_id, moyenne)
        .where(Avis.plat_id.in_(plat_ids), Avis.etat == "publie")
        .group_by(Avis.plat_id)
    )
    return {p: round(float(n), 1) for p, n in lignes.all()}


async def _tarifs(session: AsyncSession, profil: str | None) -> list[TarifLu]:
    if profil is None:
        return []
    lignes = (await session.execute(select(Tarif).where(Tarif.profil == profil))).scalars().all()
    return [TarifLu(t.profil, t.prix_xof, t.menu_id, t.actif_du, t.actif_au) for t in lignes]


async def lire_semaine(
    session: AsyncSession, debut: date, lecteur: Utilisateur, avec_brouillons: bool = False
) -> SemaineSortie:
    """Sept jours à partir de `debut` ; un jour sans menu visible garde sa place, sans plats ni prix."""
    jours = semaine(debut)
    reglages = await lire_parametres(session, "gel_jours_avant_service", "heure_gel_commandes")
    jours_avant = int(reglages["gel_jours_avant_service"])
    heure_gel = lire_heure(str(reglages["heure_gel_commandes"]))
    requete = select(Menu).where(Menu.date_service >= jours[0], Menu.date_service <= jours[-1])
    if not avec_brouillons:
        requete = requete.where(Menu.etat == "publie")
    menus = {m.date_service: m for m in (await session.execute(requete)).scalars().all()}
    ids = [m.id for m in menus.values()]
    plats_par_menu: dict[uuid.UUID, list[tuple[MenuPlat, Plat]]] = defaultdict(list)
    if ids:
        lignes = await session.execute(
            select(MenuPlat, Plat)
            .join(Plat, Plat.id == MenuPlat.plat_id)
            .where(MenuPlat.menu_id.in_(ids))
            .order_by(MenuPlat.ordre)
        )
        for menu_plat, plat in lignes.all():
            plats_par_menu[menu_plat.menu_id].append((menu_plat, plat))
    commandees = await _portions_commandees(session, ids)
    notes = await _notes(session, {p.id for liste in plats_par_menu.values() for _, p in liste})
    tarifs = await _tarifs(session, lecteur.statut_convive)
    maintenant = datetime.now(UTC)
    sortie = []
    for jour in jours:
        gel = moment_du_gel(jour, jours_avant, heure_gel)
        menu = menus.get(jour)
        services: dict[str, list[PlatDuJourSortie]] = {s: [] for s in SERVICES}
        prix = None
        if menu is not None:
            # Prix lu à minuit du jour servi : un tarif posé en cours de semaine vaut pour la suite.
            instant = datetime.combine(jour, datetime.min.time(), tzinfo=UTC)
            if tarifs and lecteur.statut_convive:
                prix = prix_du_jour(tarifs, lecteur.statut_convive, menu.id, instant)
            for menu_plat, plat in plats_par_menu[menu.id]:
                communs = allergenes_en_commun(plat.allergenes, lecteur.allergies)
                services[plat.categorie].append(
                    PlatDuJourSortie(
                        plat_id=plat.id,
                        nom_fr=plat.nom_fr,
                        nom_en=plat.nom_en,
                        description_fr=plat.description_fr,
                        description_en=plat.description_en,
                        allergenes=plat.allergenes,
                        regimes=plat.regimes,
                        calories=plat.calories,
                        prix_supplement_xof=plat.prix_supplement_xof,
                        image_url=chemin_photo(plat),
                        quantite_prevue=menu_plat.quantite_prevue,
                        portions_restantes=portions_restantes(
                            menu_plat.quantite_prevue, commandees.get((menu.id, plat.id), 0)
                        ),
                        allergenes_declares=communs,
                        contient_allergene=bool(communs),
                        note_moyenne=notes.get(plat.id),
                    )
                )
        sortie.append(
            JourSortie(
                date_service=jour,
                menu_id=menu.id if menu else None,
                etat=menu.etat if menu else None,
                gele_le=gel,
                gele=maintenant >= gel,
                prix_xof=prix,
                services=services,  # type: ignore[arg-type]
            )
        )
    return SemaineSortie(du=debut, jours=sortie)


def debut_par_defaut(aujourd_hui: date) -> date:
    """Lundi de la semaine en cours."""
    return aujourd_hui - timedelta(days=aujourd_hui.weekday())
