"""Routes /api/v1/admin/utilisateurs : création et suppression de comptes par l'admin.

Rôle admin vérifié, compte vérifié et mot de passe des actions exigés sur chaque route.
"""

import uuid
from typing import Literal

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from app.core.dependances import AdminAvecActions, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.routes.auth import vue_utilisateur
from app.routes.reservations import CleGeste
from app.schemas.commandes import AjustementEntree
from app.schemas.comptes import Canal, StatutConvive, UtilisateurSortie
from app.services import administration_comptes, commandes_suivi, comptes

routeur = APIRouter(prefix="/api/v1/admin/utilisateurs", tags=["admin"])


class CreationCompteEntree(BaseModel):
    """Corps de POST /admin/utilisateurs."""

    type: Canal
    identifiant: str = Field(min_length=3, max_length=254)
    mot_de_passe: str = Field(min_length=1, max_length=128)
    prenom: str = Field(min_length=1, max_length=60)
    nom: str = Field(min_length=1, max_length=60)
    role: Literal["convive", "parent", "agent", "admin"]
    statut_convive: StatutConvive | None = None


@routeur.post("", response_model=UtilisateurSortie, status_code=201)
async def creer_compte(
    corps: CreationCompteEntree, admin: AdminAvecActions, request: Request, session: SessionBase
) -> UtilisateurSortie:
    """Crée un compte déjà vérifié, de n'importe quel rôle."""
    if (corps.role == "convive") != (corps.statut_convive is not None):
        raise ErreurApi("validation", 422)
    donnees = comptes.NouveauCompte(
        identifiant=comptes.lire_identifiant(corps.identifiant, corps.type),
        mot_de_passe=corps.mot_de_passe,
        prenom=corps.prenom.strip(),
        nom=corps.nom.strip(),
        role=corps.role,
        statut_convive=corps.statut_convive,
    )
    utilisateur = await administration_comptes.creer_par_admin(
        session, request.app.state.config, admin.utilisateur.id, donnees, adresse_client(request)
    )
    return vue_utilisateur(utilisateur)


@routeur.delete("/{utilisateur_id}")
async def supprimer_compte(
    utilisateur_id: uuid.UUID, admin: AdminAvecActions, request: Request, session: SessionBase
) -> dict[str, bool]:
    """Supprime logiquement un compte qui n'est pas admin."""
    await administration_comptes.supprimer_par_admin(
        session, request.app.state.config, admin.utilisateur.id, utilisateur_id, adresse_client(request)
    )
    return {"supprime": True}


@routeur.post("/{utilisateur_id}/ajustement")
async def ajuster(
    utilisateur_id: uuid.UUID,
    corps: AjustementEntree,
    admin: AdminAvecActions,
    cle: CleGeste,
    request: Request,
    session: SessionBase,
) -> dict[str, int]:
    """Crédite ou débite un porte-monnaie à la main, motif obligatoire, journalisé."""
    solde = await commandes_suivi.ajuster(
        session,
        admin.utilisateur.id,
        utilisateur_id,
        corps.sens,
        corps.montant_xof,
        corps.motif,
        cle,
        adresse_client(request),
    )
    return {"solde_apres_xof": solde}
