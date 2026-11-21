"""Routes /api/v1/reservations et /api/v1/porte-monnaie, réservées au convive pour ses propres données.

Toute route qui crée de l'argent ou une commande exige l'en-tête Cle-Geste : un renvoi rend le même résultat.
"""

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Query, Request
from sqlalchemy import func, select

from app.core.dependances import Connecte, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import LotReservation, Mouvement, PorteMonnaie
from app.schemas.commandes import (
    AnnulationSortie,
    CommandeEntree,
    LotSortie,
    MouvementSortie,
    Page,
    PorteMonnaieSortie,
    ReservationSortie,
)
from app.services import commandes, commandes_suivi, porte_monnaie
from app.services.agent import contenu_qr

routeur = APIRouter(prefix="/api/v1", tags=["commandes"])
Convive = Annotated[Connecte, Depends(exiger_role("convive"))]
Titulaire = Annotated[Connecte, Depends(exiger_role("convive", "parent"))]


def cle_geste(cle_geste: Annotated[str | None, Header()] = None) -> str:
    """Lit l'en-tête Cle-Geste, unique par geste de l'utilisateur ; 428 s'il manque."""
    if not cle_geste or not 8 <= len(cle_geste) <= 100:
        raise ErreurApi("cle_geste_requise", 428)
    return cle_geste


CleGeste = Annotated[str, Depends(cle_geste)]


@routeur.post("/reservations", response_model=LotSortie, status_code=201)
async def commander(
    corps: CommandeEntree, convive: Convive, cle: CleGeste, session: SessionBase
) -> LotSortie:
    """Commande une période en une fois : le total est débité du porte-monnaie, tout ou rien."""
    lot_id = await commandes.commander(session, convive.utilisateur, corps, f"{convive.utilisateur.id}:{cle}")
    return await commandes_suivi.vue_lot(session, lot_id)


@routeur.get("/reservations", response_model=Page[ReservationSortie])
async def lister(
    convive: Convive,
    session: SessionBase,
    du: Annotated[date | None, Query()] = None,
    au: Annotated[date | None, Query()] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    taille: Annotated[int, Query(ge=1, le=100)] = 20,
) -> Page[ReservationSortie]:
    """Les commandes du convive, à venir et passées."""
    lignes, total = await commandes_suivi.lister(session, convive.utilisateur.id, du, au, page, taille)
    elements = [await commandes_suivi.vue_reservation(session, r) for r in lignes]
    return Page[ReservationSortie](elements=elements, page=page, taille=taille, total=total)


@routeur.get("/reservations/lots", response_model=list[LotSortie])
async def lister_lots(convive: Convive, session: SessionBase) -> list[LotSortie]:
    """Les lots du convive, du plus récent au plus ancien."""
    lots = await session.scalars(
        select(LotReservation.id)
        .where(LotReservation.convive_id == convive.utilisateur.id)
        .order_by(LotReservation.debut.desc())
        .limit(50)
    )
    return [await commandes_suivi.vue_lot(session, lot_id) for lot_id in lots.all()]


@routeur.get("/reservations/{reservation_id}", response_model=ReservationSortie)
async def lire(reservation_id: uuid.UUID, convive: Convive, session: SessionBase) -> ReservationSortie:
    """Une commande du convive ; celle d'un autre répond 404."""
    reservation = await commandes_suivi.reservation_du_convive(
        session, convive.utilisateur.id, reservation_id
    )
    return await commandes_suivi.vue_reservation(session, reservation)


@routeur.get("/reservations/{reservation_id}/ticket")
async def ticket(reservation_id: uuid.UUID, convive: Convive, request: Request, session: SessionBase) -> dict:
    """Le ticket du jour : contenu du QR signé, à montrer à l'agent, lisible hors ligne une fois chargé."""
    reservation = await commandes_suivi.reservation_du_convive(
        session, convive.utilisateur.id, reservation_id
    )
    vue = await commandes_suivi.vue_reservation(session, reservation)
    return {
        "contenu_qr": contenu_qr(request.app.state.config.secret_key, reservation.code_ticket),
        "date_service": vue.date_service.isoformat(),
        "etat": vue.etat,
        "plats": [p.model_dump(mode="json") for p in vue.plats],
    }


@routeur.post("/reservations/{reservation_id}/annuler", response_model=AnnulationSortie)
async def annuler(
    reservation_id: uuid.UUID, convive: Convive, cle: CleGeste, session: SessionBase
) -> AnnulationSortie:
    """Annule un jour : remboursé avant le gel, supprimé sans remboursement après."""
    return await commandes_suivi.annuler(session, convive.utilisateur, reservation_id)


@routeur.get("/porte-monnaie", response_model=PorteMonnaieSortie)
async def lire_porte_monnaie(titulaire: Titulaire, session: SessionBase) -> PorteMonnaieSortie:
    """Le solde du compte connecté, recalculé depuis ses mouvements."""
    portefeuille = await porte_monnaie.verrouiller(session, titulaire.utilisateur.id)
    return PorteMonnaieSortie(
        solde_xof=await porte_monnaie.solde_reel(session, portefeuille.id),
        devise=portefeuille.devise,
        gele=portefeuille.gele,
        a_jour_le=portefeuille.recalcule_le,
    )


@routeur.get("/porte-monnaie/mouvements", response_model=Page[MouvementSortie])
async def lister_mouvements(
    titulaire: Titulaire,
    session: SessionBase,
    page: Annotated[int, Query(ge=1)] = 1,
    taille: Annotated[int, Query(ge=1, le=100)] = 20,
) -> Page[MouvementSortie]:
    """Les mouvements du compte connecté, du plus récent au plus ancien."""
    portefeuille_id = await session.scalar(
        select(PorteMonnaie.id).where(PorteMonnaie.utilisateur_id == titulaire.utilisateur.id)
    )
    if portefeuille_id is None:
        return Page[MouvementSortie](elements=[], page=page, taille=taille, total=0)
    condition = Mouvement.porte_monnaie_id == portefeuille_id
    total = await session.scalar(select(func.count()).select_from(Mouvement).where(condition))
    lignes = await session.scalars(
        select(Mouvement)
        .where(condition)
        .order_by(Mouvement.cree_le.desc())
        .offset((page - 1) * taille)
        .limit(taille)
    )
    elements = [
        MouvementSortie(
            id=m.id,
            sens=m.sens,
            montant_xof=m.montant_xof,
            motif=m.motif,
            solde_apres_xof=m.solde_apres_xof,
            cree_le=m.cree_le,
        )
        for m in lignes.all()
    ]
    return Page[MouvementSortie](elements=elements, page=page, taille=taille, total=int(total or 0))
