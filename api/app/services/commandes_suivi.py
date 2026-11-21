"""Suivi des commandes : vues, listes, annulation avant ou après le gel, ajustement par l'admin.

Avant le gel, une annulation rembourse intégralement. Après le gel, la part est achetée et préparée : la
commande peut être supprimée, sans remboursement. Un convive n'atteint que ses propres commandes ; celle d'un
autre répond 404, comme si elle n'existait pas.
"""

import uuid
from datetime import UTC, date, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.models import LigneReservation, LotReservation, Plat, Reservation, Utilisateur
from app.schemas.commandes import AnnulationSortie, LigneSortie, LotSortie, ReservationSortie
from app.services import porte_monnaie
from app.services.commandes import reglages_gel
from app.services.journal import ecrire_journal
from app.services.regles_menus import moment_du_gel


async def vue_reservation(session: AsyncSession, reservation: Reservation) -> ReservationSortie:
    """Vue d'une commande du jour, avec ses plats et le moment de son gel."""
    jours_avant, heure_gel = await reglages_gel(session)
    lignes = await session.execute(
        select(LigneReservation, Plat)
        .join(Plat, Plat.id == LigneReservation.plat_id)
        .where(LigneReservation.reservation_id == reservation.id)
    )
    return ReservationSortie(
        id=reservation.id,
        lot_id=reservation.lot_id,
        date_service=reservation.date_service,
        etat=reservation.etat,
        total_xof=reservation.total_xof,
        code_ticket=reservation.code_ticket,
        gele_le=moment_du_gel(reservation.date_service, jours_avant, heure_gel),  # type: ignore[arg-type]
        plats=[
            LigneSortie(
                plat_id=plat.id,
                nom_fr=plat.nom_fr,
                nom_en=plat.nom_en,
                service=ligne.service,
                quantite=ligne.quantite,
                supplement_xof=ligne.supplement_xof,
            )
            for ligne, plat in lignes.all()
        ],
    )


async def vue_lot(session: AsyncSession, lot_id: uuid.UUID) -> LotSortie:
    """Vue d'un lot avec chacun de ses jours."""
    lot = await session.get(LotReservation, lot_id)
    if lot is None:
        raise ErreurApi("introuvable", 404)
    jours = await session.scalars(
        select(Reservation).where(Reservation.lot_id == lot.id).order_by(Reservation.date_service)
    )
    return LotSortie(
        id=lot.id,
        portee=lot.portee,
        debut=lot.debut,
        fin=lot.fin,
        jours_reserves=lot.jours_reserves,
        total_xof=lot.total_xof,
        etat=lot.etat,
        reservations=[await vue_reservation(session, r) for r in jours.all()],
    )


async def reservation_du_convive(
    session: AsyncSession, convive_id: uuid.UUID, reservation_id: uuid.UUID, verrou: bool = False
) -> Reservation:
    """Commande d'un convive, ou 404 : celle d'un autre n'existe pas pour lui."""
    requete = select(Reservation).where(
        Reservation.id == reservation_id, Reservation.convive_id == convive_id
    )
    if verrou:
        requete = requete.with_for_update()
    reservation = (await session.execute(requete)).scalar_one_or_none()
    if reservation is None:
        raise ErreurApi("introuvable", 404)
    return reservation


async def lister(
    session: AsyncSession, convive_id: uuid.UUID, du: date | None, au: date | None, page: int, taille: int
) -> tuple[list[Reservation], int]:
    """Commandes du convive sur une période, la plus proche d'abord."""
    condition = [Reservation.convive_id == convive_id]
    if du:
        condition.append(Reservation.date_service >= du)
    if au:
        condition.append(Reservation.date_service <= au)
    total = await session.scalar(select(func.count()).select_from(Reservation).where(*condition))
    lignes = await session.scalars(
        select(Reservation)
        .where(*condition)
        .order_by(Reservation.date_service.desc())
        .offset((page - 1) * taille)
        .limit(taille)
    )
    return list(lignes.all()), int(total or 0)


async def annuler(session: AsyncSession, convive: Utilisateur, reservation_id: uuid.UUID) -> AnnulationSortie:
    """Annule un jour : remboursé avant le gel, supprimé sans remboursement après ; renvoi sans effet."""
    portefeuille = await porte_monnaie.verrouiller(session, convive.id)
    reservation = await reservation_du_convive(session, convive.id, reservation_id, verrou=True)
    if reservation.etat in ("annulee", "supprimee"):
        rendu = reservation.total_xof if reservation.etat == "annulee" else 0
        return AnnulationSortie(etat=reservation.etat, rembourse_xof=rendu)  # type: ignore[arg-type]
    if reservation.etat != "confirmee":
        raise ErreurApi("deja_servie", 409)
    jours_avant, heure_gel = await reglages_gel(session)
    gele = datetime.now(UTC) >= moment_du_gel(reservation.date_service, jours_avant, heure_gel)  # type: ignore[arg-type]
    reservation.annulee_le = datetime.now(UTC)
    if gele:
        reservation.etat = "supprimee"
        rembourse = 0
    else:
        reservation.etat = "annulee"
        rembourse = reservation.total_xof
        if rembourse > 0:
            await porte_monnaie.ecrire(
                session,
                portefeuille,
                "credit",
                rembourse,
                "annulation",
                f"annulation:{reservation.id}",
                "reservation",
                reservation.id,
            )
    await _mettre_a_jour_lot(session, reservation.lot_id)
    return AnnulationSortie(etat=reservation.etat, rembourse_xof=rembourse)  # type: ignore[arg-type]


async def _mettre_a_jour_lot(session: AsyncSession, lot_id: uuid.UUID) -> None:
    await session.flush()
    restants = await session.scalar(
        select(func.count())
        .select_from(Reservation)
        .where(Reservation.lot_id == lot_id, Reservation.etat.not_in(("annulee", "supprimee")))
    )
    lot = await session.get(LotReservation, lot_id, with_for_update=True)
    if lot is not None:
        lot.etat = "annule" if not restants else "partiellement_annule"


async def ajuster(
    session: AsyncSession,
    admin_id: uuid.UUID,
    cible_id: uuid.UUID,
    sens: str,
    montant: int,
    motif: str,
    cle_geste: str,
    ip: str | None,
) -> int:
    """Crédite ou débite un compte à la main ; le motif va au journal. Rend le solde après."""
    cible = await session.get(Utilisateur, cible_id)
    if cible is None or cible.supprime_le is not None:
        raise ErreurApi("introuvable", 404)
    portefeuille = await porte_monnaie.verrouiller(session, cible.id)
    cle = f"ajustement:{cle_geste}"
    deja = await porte_monnaie.mouvement_existant(session, cle)
    if deja is not None:
        return deja.solde_apres_xof
    mouvement = await porte_monnaie.ecrire(
        session, portefeuille, sens, montant, "ajustement_admin", cle, cree_par=admin_id
    )
    apres = {
        "sens": sens,
        "montant_xof": montant,
        "motif": motif,
        "solde_apres_xof": mouvement.solde_apres_xof,
    }
    ecrire_journal(session, admin_id, "ajustement_porte_monnaie", "utilisateur", cible.id, None, apres, ip)
    return mouvement.solde_apres_xof
