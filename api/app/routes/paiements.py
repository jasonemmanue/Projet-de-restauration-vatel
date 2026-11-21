"""Routes /api/v1/paiements : recharge par Mobile Money, suivi, webhooks GeniusPay signés, page de retour.

Les webhooks sont publics mais signés : sans signature juste et récente, rien n'est lu. Le webhook de test
n'accepte que l'environnement « sandbox », celui de production que « live ».
"""

import json
import uuid
from datetime import datetime
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import or_, select

from app.core.dependances import Connecte, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Paiement
from app.routes.reservations import CleGeste
from app.services import geniuspay, paiements
from app.services.regles_comptes import IdentifiantInvalideError, normaliser_telephone

routeur = APIRouter(prefix="/api/v1/paiements", tags=["paiements"])
Titulaire = Annotated[Connecte, Depends(exiger_role("convive", "parent"))]


class RechargeEntree(BaseModel):
    """Corps de POST /paiements/recharge ; sans bénéficiaire, on se recharge soi-même."""

    beneficiaire_id: uuid.UUID | None = None
    montant_xof: int = Field(ge=1, le=10_000_000)
    operateur: Literal["orange", "mtn", "moov", "wave"]
    telephone_payeur: str = Field(min_length=8, max_length=20)


class PaiementSortie(BaseModel):
    """Vue d'un paiement."""

    paiement_id: uuid.UUID
    beneficiaire_id: uuid.UUID
    montant_xof: int
    operateur: str
    mode: str
    etat: str
    url_redirection: str | None
    cree_le: datetime
    confirme_le: datetime | None


def _vue(paiement: Paiement) -> PaiementSortie:
    return PaiementSortie(
        paiement_id=paiement.id,
        beneficiaire_id=paiement.beneficiaire_id,
        montant_xof=paiement.montant_xof,
        operateur=paiement.operateur,
        mode=paiement.mode,
        etat=paiement.etat,
        url_redirection=paiement.url_paiement,
        cree_le=paiement.cree_le,
        confirme_le=paiement.confirme_le,
    )


@routeur.post("/recharge", response_model=PaiementSortie, status_code=201)
async def recharger(
    corps: RechargeEntree, titulaire: Titulaire, cle: CleGeste, request: Request, session: SessionBase
) -> PaiementSortie:
    """Demande une recharge ; le client ouvre `url_redirection` pour payer chez l'opérateur."""
    try:
        telephone = normaliser_telephone(corps.telephone_payeur)
    except IdentifiantInvalideError as exc:
        raise ErreurApi("identifiant_invalide", 422) from exc
    paiement = await paiements.demander_recharge(
        session,
        request.app.state.config,
        request.app.state.client_http,
        titulaire.utilisateur,
        corps.beneficiaire_id,
        corps.montant_xof,
        corps.operateur,
        telephone,
        f"{titulaire.utilisateur.id}:{cle}",
    )
    return _vue(paiement)


@routeur.get("", response_model=list[PaiementSortie])
async def lister(titulaire: Titulaire, session: SessionBase) -> list[PaiementSortie]:
    """Les 50 derniers paiements faits ou reçus par le compte."""
    uid = titulaire.utilisateur.id
    lignes = await session.scalars(
        select(Paiement)
        .where(or_(Paiement.payeur_id == uid, Paiement.beneficiaire_id == uid))
        .order_by(Paiement.cree_le.desc())
        .limit(50)
    )
    return [_vue(p) for p in lignes.all()]


@routeur.get("/retour")
async def retour(paiement: uuid.UUID, session: SessionBase) -> dict[str, str]:
    """Page de retour après le paiement chez l'opérateur : l'état fait foi, le webhook a le dernier mot."""
    trouve = await session.get(Paiement, paiement)
    if trouve is None:
        raise ErreurApi("introuvable", 404)
    return {"etat": trouve.etat}


@routeur.get("/{paiement_id}", response_model=PaiementSortie)
async def lire(paiement_id: uuid.UUID, titulaire: Titulaire, session: SessionBase) -> PaiementSortie:
    """Un paiement du compte, payeur ou bénéficiaire ; sinon 404."""
    return _vue(await paiements.paiement_visible(session, titulaire.utilisateur.id, paiement_id))


@routeur.post("/webhook/{mode}")
async def webhook(mode: Literal["test", "reel"], request: Request, session: SessionBase) -> dict[str, Any]:
    """Reçoit un événement GeniusPay signé, pour le mode de ce chemin seulement."""
    config = request.app.state.config
    secret = config.geniuspay_secret_webhook_reel if mode == "reel" else config.geniuspay_secret_webhook_test
    corps = await request.body()
    entetes = request.headers
    if not geniuspay.signature_valide(
        secret or "", entetes.get("x-webhook-timestamp", ""), corps, entetes.get("x-webhook-signature", "")
    ):
        raise ErreurApi("signature_invalide", 401)
    environnement = entetes.get("x-webhook-environment")
    if environnement and environnement != geniuspay.ENVIRONNEMENTS[mode]:
        raise ErreurApi("signature_invalide", 401)
    try:
        charge = json.loads(corps)
    except ValueError as exc:
        raise ErreurApi("validation", 422) from exc
    await paiements.traiter_webhook(session, mode, charge)
    return {"recu": True}
