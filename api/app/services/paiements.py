"""Recharges Mobile Money par GeniusPay : demande, webhook signé, crédit du porte-monnaie.

Tout convive recharge son propre porte-monnaie, quel que soit son statut ; un parent peut en plus recharger
celui d'un enfant lié. Le paiement est écrit et validé avant l'appel à GeniusPay, pour qu'un webhook rapide
le trouve. Le crédit se fait dans la transaction qui passe le paiement à réussi, une seule fois : un webhook
rejoué ne crédite rien de plus.
"""

import contextlib
import logging
import uuid
from datetime import UTC, datetime
from typing import Any

import httpx
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.models import Paiement, Utilisateur
from app.services import geniuspay, liaison, porte_monnaie
from app.services.parametres import lire_parametres

journal = logging.getLogger("vatel.paiements")
ETATS_FINAUX = ("reussi", "echoue", "expire")


def cles_du_mode(config: Configuration, mode: str) -> tuple[str | None, str | None]:
    """Clé publique et clé secrète GeniusPay du mode demandé."""
    if mode == "reel":
        return config.geniuspay_cle_publique_reelle, config.geniuspay_cle_secrete_reelle
    return config.geniuspay_cle_publique_test, config.geniuspay_cle_secrete_test


async def _beneficiaire(
    session: AsyncSession, payeur: Utilisateur, beneficiaire_id: uuid.UUID | None
) -> Utilisateur:
    if beneficiaire_id is None or beneficiaire_id == payeur.id:
        if payeur.role != "convive":
            raise ErreurApi("beneficiaire_interdit", 403)
        return payeur
    if payeur.role != "parent":
        raise ErreurApi("beneficiaire_interdit", 403)
    try:
        return await liaison.enfant_lie(session, payeur.id, beneficiaire_id)
    except ErreurApi as exc:
        raise ErreurApi("beneficiaire_interdit", 403) from exc


async def demander_recharge(
    session: AsyncSession,
    config: Configuration,
    client: httpx.AsyncClient,
    payeur: Utilisateur,
    beneficiaire_id: uuid.UUID | None,
    montant: int,
    operateur: str,
    telephone: str,
    cle_geste: str,
) -> Paiement:
    """Crée la recharge, la demande à GeniusPay et rend le paiement avec son adresse de paiement."""
    deja = (
        await session.execute(select(Paiement).where(Paiement.cle_geste == cle_geste))
    ).scalar_one_or_none()
    if deja is not None:
        if deja.payeur_id != payeur.id:
            raise ErreurApi("conflit", 409)
        return deja
    beneficiaire = await _beneficiaire(session, payeur, beneficiaire_id)
    reglages = await lire_parametres(session, "mode_paiement", "recharge_min_xof", "recharge_max_xof")
    if not int(reglages["recharge_min_xof"]) <= montant <= int(reglages["recharge_max_xof"]):
        raise ErreurApi("montant_invalide", 422)
    mode = str(reglages["mode_paiement"])
    if mode != "test":
        # Le mode réel arrive avec son garde-fou (API-13) : d'ici là, aucun argent réel ne circule.
        raise ErreurApi("mode_paiement_invalide", 409)
    cle_publique, cle_secrete = cles_du_mode(config, mode)
    if not cle_publique or not cle_secrete:
        raise ErreurApi("cles_absentes", 409)
    paiement = Paiement(
        payeur_id=payeur.id,
        beneficiaire_id=beneficiaire.id,
        montant_xof=montant,
        operateur=operateur,
        telephone_payeur=telephone,
        mode=mode,
        etat="initie",
        cle_geste=cle_geste,
    )
    session.add(paiement)
    await session.commit()
    retour = f"{config.api_url_publique}/api/v1/paiements/retour?paiement={paiement.id}"
    try:
        initie = await geniuspay.initier(
            client,
            config.geniuspay_url_base,
            cle_publique,
            cle_secrete,
            montant,
            operateur,
            telephone,
            f"Recharge CANTINE VATEL {montant} XOF",
            retour,
            {"paiement_id": str(paiement.id)},
        )
    except geniuspay.GeniusPayError as exc:
        journal.warning("initiation GeniusPay refusée pour %s : %s", paiement.id, exc)
        paiement.etat = "echoue"
        paiement.motif_echec = "initiation_refusee"
        await session.commit()
        raise ErreurApi("paiement_indisponible", 502) from exc
    paiement.etat = "en_attente"
    paiement.reference_geniuspay = initie.reference
    paiement.url_paiement = initie.url_paiement
    paiement.frais_xof = initie.frais_xof
    paiement.net_xof = initie.net_xof
    return paiement


async def traiter_webhook(session: AsyncSession, mode: str, charge: dict[str, Any]) -> None:
    """Applique un événement GeniusPay déjà authentifié ; un même événement rejoué ne crédite qu'une fois."""
    evenement = str(charge.get("event") or "")
    donnees = charge.get("data") or {}
    if not evenement.startswith("payment."):
        journal.info("événement GeniusPay ignoré : %s", evenement)
        return
    metadata = donnees.get("metadata") or {}
    conditions = [Paiement.reference_geniuspay == str(donnees.get("reference") or "")]
    # Une metadata absente ou mal formée laisse la seule référence GeniusPay pour retrouver le paiement.
    with contextlib.suppress(ValueError):
        conditions.append(Paiement.id == uuid.UUID(str(metadata.get("paiement_id"))))
    paiement = (
        await session.execute(
            select(Paiement).where(or_(*conditions), Paiement.mode == mode).with_for_update()
        )
    ).scalar_one_or_none()
    if paiement is None:
        journal.warning("webhook GeniusPay sans paiement connu : %s", donnees.get("reference"))
        return
    if paiement.etat in ETATS_FINAUX:
        return
    paiement.charge_utile_webhook = charge
    paiement.reference_geniuspay = paiement.reference_geniuspay or str(donnees.get("reference") or "") or None
    if evenement == "payment.success":
        if geniuspay.en_xof(donnees.get("amount")) != paiement.montant_xof:
            paiement.etat = "echoue"
            paiement.motif_echec = "montant_incoherent"
            journal.error("montant GeniusPay différent pour %s", paiement.id)
            return
        paiement.etat = "reussi"
        paiement.frais_xof = geniuspay.en_xof(donnees.get("fees"))
        paiement.net_xof = geniuspay.en_xof(donnees.get("net_amount"))
        paiement.confirme_le = datetime.now(UTC)
        portefeuille = await porte_monnaie.verrouiller(session, paiement.beneficiaire_id)
        await porte_monnaie.ecrire(
            session,
            portefeuille,
            "credit",
            paiement.montant_xof,
            "recharge",
            f"paiement:{paiement.id}",
            "paiement",
            paiement.id,
        )
    elif evenement == "payment.expired":
        paiement.etat = "expire"
    elif evenement in ("payment.failed", "payment.cancelled"):
        paiement.etat = "echoue"
        paiement.motif_echec = evenement.removeprefix("payment.")


async def paiement_visible(
    session: AsyncSession, utilisateur_id: uuid.UUID, paiement_id: uuid.UUID
) -> Paiement:
    """Un paiement dont le compte est payeur ou bénéficiaire, ou 404."""
    paiement = (
        await session.execute(
            select(Paiement).where(
                Paiement.id == paiement_id,
                or_(Paiement.payeur_id == utilisateur_id, Paiement.beneficiaire_id == utilisateur_id),
            )
        )
    ).scalar_one_or_none()
    if paiement is None:
        raise ErreurApi("introuvable", 404)
    return paiement
