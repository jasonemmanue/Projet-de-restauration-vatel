"""Routes des liens de paiement, de l'estimation des frais et du mode de paiement de l'admin.

/liens-paiement : le convive ou le parent crée et suit ses liens. /public/liens-paiement : la page du proche,
publique, qui ne montre que « Prénom I. », le montant et le message. /admin/mode-paiement : bascule entre
test et réel, protégée par le mot de passe des actions et journalisée.
"""

import uuid
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.core.dependances import Admin, AdminAvecActions, Connecte, adresse_client, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import LienPaiement, Parametre, Utilisateur
from app.routes.reservations import CleGeste
from app.services import liens_paiement, paiements
from app.services.journal import ecrire_journal
from app.services.parametres import lire_parametres
from app.services.regles_comptes import IdentifiantInvalideError, normaliser_telephone
from app.services.regles_frais import GrilleFrais, estimer

routeur = APIRouter(prefix="/api/v1", tags=["liens de paiement"])
Titulaire = Annotated[Connecte, Depends(exiger_role("convive", "parent"))]
Operateur = Literal["orange", "mtn", "moov", "wave"]


class LienEntree(BaseModel):
    """Corps de POST /liens-paiement ; sans montant, le proche choisit."""

    beneficiaire_id: uuid.UUID | None = None
    montant_xof: int | None = Field(default=None, ge=1, le=10_000_000)
    message: str = Field(default="", max_length=300)
    expire_dans_heures: int = Field(default=72, ge=1, le=720)


class PaiementLienEntree(BaseModel):
    """Corps de POST /public/liens-paiement/{jeton}/payer."""

    operateur: Operateur
    telephone_payeur: str = Field(min_length=8, max_length=20)
    montant_xof: int | None = Field(default=None, ge=1, le=10_000_000)


class ModeEntree(BaseModel):
    """Corps de PUT /admin/mode-paiement."""

    mode: Literal["test", "reel"]


def _vue(config, lien: LienPaiement) -> dict[str, Any]:
    return {
        "id": str(lien.id),
        "url_publique": liens_paiement.url_publique(config, lien.jeton_public),
        "montant_xof": lien.montant_xof,
        "message": lien.message,
        "etat": lien.etat,
        "expire_le": lien.expire_le.isoformat(),
    }


@routeur.post("/liens-paiement", status_code=201)
async def creer(corps: LienEntree, titulaire: Titulaire, request: Request, session: SessionBase) -> dict:
    """Crée un lien à envoyer à un proche, pour soi ou pour un enfant lié."""
    lien = await liens_paiement.creer(
        session,
        titulaire.utilisateur,
        corps.beneficiaire_id,
        corps.montant_xof,
        corps.message,
        corps.expire_dans_heures,
    )
    return _vue(request.app.state.config, lien)


@routeur.get("/liens-paiement")
async def lister(titulaire: Titulaire, request: Request, session: SessionBase) -> list[dict[str, Any]]:
    """Les 50 derniers liens créés par le compte."""
    lignes = await session.scalars(
        select(LienPaiement)
        .where(LienPaiement.createur_id == titulaire.utilisateur.id)
        .order_by(LienPaiement.cree_le.desc())
        .limit(50)
    )
    return [_vue(request.app.state.config, lien) for lien in lignes.all()]


@routeur.delete("/liens-paiement/{lien_id}")
async def annuler(lien_id: uuid.UUID, titulaire: Titulaire, session: SessionBase) -> dict[str, bool]:
    """Annule un lien non payé."""
    await liens_paiement.annuler(session, titulaire.utilisateur.id, lien_id)
    return {"annule": True}


@routeur.get("/public/liens-paiement/{jeton}")
async def lire_public(jeton: str, session: SessionBase) -> dict[str, Any]:
    """Ce que voit le proche : « Prénom I. », le montant, le message et l'état."""
    lien = await liens_paiement.lien_public(session, jeton)
    beneficiaire = await session.get(Utilisateur, lien.beneficiaire_id)
    return {
        "beneficiaire_prenom": liens_paiement.prenom_initiale(beneficiaire) if beneficiaire else "",
        "montant_xof": lien.montant_xof,
        "message": lien.message,
        "etat": lien.etat,
        "expire_le": lien.expire_le.isoformat(),
    }


@routeur.post("/public/liens-paiement/{jeton}/payer", status_code=201)
async def payer_public(
    jeton: str, corps: PaiementLienEntree, cle: CleGeste, request: Request, session: SessionBase
) -> dict[str, Any]:
    """Le proche paie : il est envoyé chez l'opérateur, le bénéficiaire est crédité au webhook."""
    try:
        telephone = normaliser_telephone(corps.telephone_payeur)
    except IdentifiantInvalideError as exc:
        raise ErreurApi("identifiant_invalide", 422) from exc
    paiement = await liens_paiement.payer(
        session,
        request.app.state.config,
        request.app.state.client_http,
        jeton,
        corps.montant_xof,
        corps.operateur,
        telephone,
        f"lien:{jeton}:{cle}",
    )
    return {"paiement_id": str(paiement.id), "etat": paiement.etat, "url_redirection": paiement.url_paiement}


async def _grille(session: SessionBase) -> GrilleFrais:
    reglages = await lire_parametres(
        session,
        "frais_geniuspay_pdm",
        "frais_geniuspay_fixe_xof",
        "frais_retrait_pdm",
        "frais_passerelles_pdm",
    )
    return GrilleFrais(
        geniuspay_pdm=int(reglages["frais_geniuspay_pdm"]),
        geniuspay_fixe_xof=int(reglages["frais_geniuspay_fixe_xof"]),
        retrait_pdm=int(reglages["frais_retrait_pdm"]),
        passerelles_pdm={k: int(v) for k, v in dict(reglages["frais_passerelles_pdm"]).items()},
    )


@routeur.get("/paiements-estimation")
async def estimation(
    session: SessionBase,
    lecteur: Annotated[Connecte, Depends(exiger_role("convive", "parent", "admin"))],
    montant: Annotated[int, Query(ge=1, le=10_000_000)],
    operateur: Annotated[str, Query(max_length=20)],
) -> dict[str, Any]:
    """Frais attendus d'une recharge selon la grille : ce que la cantine supporte et ce qu'il lui reste."""
    frais = estimer(montant, operateur, await _grille(session))
    if frais is None:
        raise ErreurApi("operateur_inconnu", 422)
    return frais.__dict__


@routeur.get("/admin/mode-paiement")
async def lire_mode(admin: Admin, request: Request, session: SessionBase) -> dict[str, Any]:
    """Mode en vigueur et présence des clés de chaque mode (jamais leur valeur)."""
    config = request.app.state.config
    mode = (await lire_parametres(session, "mode_paiement"))["mode_paiement"]
    return {
        "mode": mode,
        "cles_test": all(paiements.cles_du_mode(config, "test")),
        "cles_reelles": all(paiements.cles_du_mode(config, "reel")),
        "webhook_test": bool(config.geniuspay_secret_webhook_test),
        "webhook_reel": bool(config.geniuspay_secret_webhook_reel),
    }


@routeur.put("/admin/mode-paiement")
async def changer_mode(
    corps: ModeEntree, admin: AdminAvecActions, request: Request, session: SessionBase
) -> dict[str, str]:
    """Bascule entre test et réel ; le réel est refusé tant que ses clés ou son secret de webhook manquent."""
    config = request.app.state.config
    if corps.mode == "reel" and not (
        all(paiements.cles_du_mode(config, "reel")) and config.geniuspay_secret_webhook_reel
    ):
        raise ErreurApi("cles_absentes", 409)
    parametre = await session.get(Parametre, "mode_paiement", with_for_update=True)
    if parametre is None:
        raise ErreurApi("erreur_serveur", 500)
    avant = {"mode": parametre.valeur}
    parametre.valeur = corps.mode
    parametre.modifie_par = admin.utilisateur.id
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "mode_paiement",
        "parametre",
        None,
        avant,
        {"mode": corps.mode},
        adresse_client(request),
    )
    return {"mode": corps.mode}
