"""Commandes : un lot couvre une période, une réservation par jour, des lignes par service.

Tout se joue dans une transaction, sous le verrou du porte-monnaie du convive : contrôles, création du lot et
de ses jours, puis un seul débit. Soit toute la période passe, soit rien. La même clé de geste rend le même
lot sans rien débiter de plus.
"""

import secrets
import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.models import LigneReservation, LotReservation, Menu, MenuPlat, Plat, Reservation, Utilisateur
from app.schemas.commandes import CommandeEntree
from app.services import porte_monnaie
from app.services.menus_lecture import ETATS_QUI_COMPTENT, tarifs_du_profil
from app.services.parametres import lire_parametres
from app.services.regles_commandes import LigneCommandee, fin_de_periode, supplements
from app.services.regles_menus import lire_heure, moment_du_gel, prix_du_jour

ETATS_VIVANTS = ("confirmee", "servie")


async def reglages_gel(session: AsyncSession) -> tuple[int, object]:
    """Jours avant le service et heure du gel, réglés par l'admin."""
    reglages = await lire_parametres(session, "gel_jours_avant_service", "heure_gel_commandes")
    return int(reglages["gel_jours_avant_service"]), lire_heure(str(reglages["heure_gel_commandes"]))


async def commander(
    session: AsyncSession, convive: Utilisateur, corps: CommandeEntree, cle_geste: str
) -> uuid.UUID:
    """Crée un lot de commandes et le débite ; rend l'identifiant du lot, même lot pour la même clé."""
    if convive.statut_convive is None:
        raise ErreurApi("acces_refuse", 403)
    # Le verrou passe avant la recherche de la clé : deux envois du même geste se rangent l'un après l'autre,
    # et le second trouve le lot du premier au lieu d'en créer un autre.
    portefeuille = await porte_monnaie.verrouiller(session, convive.id)
    deja = (
        await session.execute(select(LotReservation).where(LotReservation.cle_unique == cle_geste))
    ).scalar()
    if deja is not None:
        if deja.convive_id != convive.id:
            raise ErreurApi("conflit", 409)
        return deja.id
    fin = fin_de_periode(corps.portee, corps.debut)
    dates = [j.date_service for j in corps.jours]
    if len(set(dates)) != len(dates) or any(d < corps.debut or d > fin for d in dates):
        raise ErreurApi("validation", 422)

    pris = await session.scalars(
        select(Reservation.date_service).where(
            Reservation.convive_id == convive.id,
            Reservation.date_service.in_(dates),
            Reservation.etat.in_(ETATS_VIVANTS),
        )
    )
    deja_pris = sorted(pris.all())
    if deja_pris:
        raise ErreurApi("reservation_existante", 409)

    jours_avant, heure_gel = await reglages_gel(session)
    menus = {
        m.date_service: m
        for m in (await session.execute(select(Menu).where(Menu.date_service.in_(dates)))).scalars().all()
    }
    tarifs = await tarifs_du_profil(session, convive.statut_convive)
    maintenant = datetime.now(UTC)
    a_creer = []
    total_lot = 0
    for jour in corps.jours:
        menu = menus.get(jour.date_service)
        if menu is None or menu.etat != "publie":
            raise ErreurApi("menu_non_publie", 409)
        if maintenant >= moment_du_gel(jour.date_service, jours_avant, heure_gel):
            raise ErreurApi("commande_gelee", 409)
        if not jour.plats:
            raise ErreurApi("aucun_service", 422)
        instant = datetime.combine(jour.date_service, datetime.min.time(), tzinfo=UTC)
        prix = prix_du_jour(tarifs, convive.statut_convive, menu.id, instant)
        if prix is None:
            raise ErreurApi("tarif_absent", 409)
        lignes = await _lignes_du_jour(session, menu, jour.plats)
        total = prix + sum(supplements(lignes))
        total_lot += total
        a_creer.append((jour.date_service, menu, lignes, total))

    lot = LotReservation(
        convive_id=convive.id,
        portee=corps.portee,
        debut=corps.debut,
        fin=fin,
        jours_reserves=len(a_creer),
        total_xof=total_lot,
        etat="confirme",
        cle_unique=cle_geste,
    )
    session.add(lot)
    await session.flush()
    for jour_service, menu, lignes, total in a_creer:
        reservation = Reservation(
            lot_id=lot.id,
            convive_id=convive.id,
            menu_id=menu.id,
            date_service=jour_service,
            total_xof=total,
            etat="confirmee",
            code_ticket=secrets.token_urlsafe(18),
        )
        session.add(reservation)
        await session.flush()
        for ligne, supplement in zip(lignes, supplements(lignes), strict=True):
            session.add(
                LigneReservation(
                    reservation_id=reservation.id,
                    plat_id=ligne.plat_id,
                    service=ligne.service,
                    quantite=ligne.quantite,
                    supplement_xof=supplement,
                )
            )
    if total_lot > 0:
        await porte_monnaie.ecrire(
            session,
            portefeuille,
            "debit",
            total_lot,
            "reservation",
            f"lot:{lot.id}",
            "lot_reservation",
            lot.id,
        )
    return lot.id


async def _lignes_du_jour(session: AsyncSession, menu: Menu, plats: list) -> list[LigneCommandee]:
    """Contrôle que chaque plat est au menu et qu'il en reste assez ; verrouille ses portions."""
    identifiants = [p.plat_id for p in plats]
    if len(set(identifiants)) != len(identifiants):
        raise ErreurApi("validation", 422)
    offres = {
        mp.plat_id: (mp, plat)
        for mp, plat in (
            await session.execute(
                select(MenuPlat, Plat)
                .join(Plat, Plat.id == MenuPlat.plat_id)
                .where(MenuPlat.menu_id == menu.id, MenuPlat.plat_id.in_(identifiants))
                .with_for_update(of=MenuPlat)
            )
        ).all()
    }
    commandees = dict(
        (
            await session.execute(
                select(LigneReservation.plat_id, func.sum(LigneReservation.quantite))
                .join(Reservation, Reservation.id == LigneReservation.reservation_id)
                .where(
                    Reservation.menu_id == menu.id,
                    Reservation.etat.in_(ETATS_QUI_COMPTENT),
                    LigneReservation.plat_id.in_(identifiants),
                )
                .group_by(LigneReservation.plat_id)
            )
        ).all()
    )
    lignes = []
    for demande in plats:
        offre = offres.get(demande.plat_id)
        if offre is None:
            raise ErreurApi("plat_hors_menu", 422)
        menu_plat, plat = offre
        if menu_plat.quantite_prevue - int(commandees.get(plat.id, 0)) < demande.quantite:
            raise ErreurApi("plat_epuise", 409)
        lignes.append(LigneCommandee(plat.id, plat.categorie, demande.quantite, plat.prix_supplement_xof))
    return lignes
