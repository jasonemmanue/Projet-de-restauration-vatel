"""Liens de paiement : un convive ou un parent demande à un proche de payer une recharge.

La page publique du lien ne montre que « Prénom I. », le montant et le message : rien qui permette de
retrouver le compte. Un lien expiré, payé ou annulé ne sert plus.
"""

import secrets
import uuid
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.models import LienPaiement, Paiement, Utilisateur
from app.services import paiements


def prenom_initiale(utilisateur: Utilisateur) -> str:
    """« Prénom I. » : assez pour que le proche reconnaisse, rien de plus."""
    initiale = f" {utilisateur.nom[:1]}." if utilisateur.nom else ""
    return f"{utilisateur.prenom}{initiale}".strip()


def url_publique(config: Configuration, jeton: str) -> str:
    """Adresse à partager : la page du site public si elle existe, sinon la lecture publique de l'API."""
    if config.site_url_publique:
        return f"{config.site_url_publique.rstrip('/')}/payer/{jeton}"
    return f"{config.api_url_publique}/api/v1/public/liens-paiement/{jeton}"


async def creer(
    session: AsyncSession,
    createur: Utilisateur,
    beneficiaire_id: uuid.UUID | None,
    montant: int | None,
    message: str,
    heures: int,
) -> LienPaiement:
    """Crée un lien pour soi, ou pour un enfant lié si l'on est parent."""
    beneficiaire = await paiements._beneficiaire(session, createur, beneficiaire_id)
    if montant is not None:
        await paiements.controler_montant(session, montant)
    lien = LienPaiement(
        createur_id=createur.id,
        beneficiaire_id=beneficiaire.id,
        jeton_public=secrets.token_urlsafe(24),
        montant_xof=montant,
        message=message,
        etat="actif",
        expire_le=datetime.now(UTC) + timedelta(hours=heures),
    )
    session.add(lien)
    await session.flush()
    return lien


async def lien_public(session: AsyncSession, jeton: str, verrou: bool = False) -> LienPaiement:
    """Le lien d'un jeton public ; 404 s'il n'existe pas, 410 s'il a expiré ou ne sert plus."""
    requete = select(LienPaiement).where(LienPaiement.jeton_public == jeton)
    if verrou:
        requete = requete.with_for_update()
    lien = (await session.execute(requete)).scalar_one_or_none()
    if lien is None:
        raise ErreurApi("introuvable", 404)
    if lien.etat == "actif" and lien.expire_le <= datetime.now(UTC):
        lien.etat = "expire"
    if lien.etat == "paye":
        raise ErreurApi("deja_paye", 409)
    if lien.etat != "actif":
        raise ErreurApi("lien_expire", 410)
    return lien


async def payer(
    session: AsyncSession,
    config: Configuration,
    client: httpx.AsyncClient,
    jeton: str,
    montant: int | None,
    operateur: str,
    telephone: str,
    cle_geste: str,
) -> Paiement:
    """Le proche paie le lien : un paiement sans payeur connu, crédité au bénéficiaire par le webhook."""
    deja = (
        await session.execute(select(Paiement).where(Paiement.cle_geste == cle_geste))
    ).scalar_one_or_none()
    if deja is not None:
        return deja
    lien = await lien_public(session, jeton, verrou=True)
    a_payer = lien.montant_xof or montant
    if a_payer is None:
        raise ErreurApi("montant_invalide", 422)
    await paiements.controler_montant(session, a_payer)
    paiement = Paiement(
        payeur_id=None,
        beneficiaire_id=lien.beneficiaire_id,
        lien_paiement_id=lien.id,
        montant_xof=a_payer,
        operateur=operateur,
        telephone_payeur=telephone,
        mode=await paiements.mode_courant(session, config),
        etat="initie",
        cle_geste=cle_geste,
    )
    return await paiements.initier_chez_geniuspay(session, config, client, paiement)


async def annuler(session: AsyncSession, createur_id: uuid.UUID, lien_id: uuid.UUID) -> None:
    """Annule un lien de son créateur ; un lien payé ne s'annule plus."""
    lien = (
        await session.execute(
            select(LienPaiement)
            .where(LienPaiement.id == lien_id, LienPaiement.createur_id == createur_id)
            .with_for_update()
        )
    ).scalar_one_or_none()
    if lien is None:
        raise ErreurApi("introuvable", 404)
    if lien.etat == "paye":
        raise ErreurApi("deja_paye", 409)
    lien.etat = "annule"
