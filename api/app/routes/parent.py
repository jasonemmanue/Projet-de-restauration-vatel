"""Routes /api/v1/parent, /moi/code-liaison et /admin/utilisateurs/{id}/code-liaison.

Un parent n'atteint que ses enfants liés ; un convive ne voit que son propre code.
"""

import uuid
from datetime import date
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import Select, select

from app.core.dependances import Admin, Connecte, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import PorteMonnaie, Utilisateur
from app.schemas.catalogue import Allergene
from app.services import commandes_suivi, liaison

routeur = APIRouter(prefix="/api/v1", tags=["parent"])
Parent = Annotated[Connecte, Depends(exiger_role("parent"))]
Convive = Annotated[Connecte, Depends(exiger_role("convive"))]


class LiaisonEntree(BaseModel):
    """Corps de POST /parent/liaison."""

    code_liaison: str = Field(min_length=6, max_length=20)


class SeuilEntree(BaseModel):
    """Corps de PUT /parent/enfants/{id}/seuil."""

    seuil_alerte_solde: int | None = Field(default=None, ge=0, le=1_000_000)


class AllergiesEntree(BaseModel):
    """Corps de PUT /parent/enfants/{id}/allergies."""

    allergies: list[Allergene] = Field(max_length=11)


async def _vue_enfant(session: SessionBase, enfant: Utilisateur) -> dict[str, Any]:
    solde = await session.scalar(select_solde(enfant.id))
    return {
        "id": str(enfant.id),
        "prenom": enfant.prenom,
        "nom": enfant.nom,
        "statut_convive": enfant.statut_convive,
        "solde_xof": int(solde or 0),
        "allergies": enfant.allergies,
        "seuil_alerte_solde": enfant.seuil_alerte_solde,
    }


def select_solde(utilisateur_id: uuid.UUID) -> Select:
    """Solde de lecture rapide d'un compte, recalculé dans la transaction de chaque mouvement."""
    return select(PorteMonnaie.solde_cache_xof).where(PorteMonnaie.utilisateur_id == utilisateur_id)


@routeur.get("/moi/code-liaison")
async def mon_code(convive: Convive, request: Request, session: SessionBase) -> dict[str, str]:
    """Tire un nouveau code de liaison à donner à son parent ; l'ancien cesse de servir."""
    code, expire_le = await liaison.nouveau_code(
        session, request.app.state.config.secret_key, convive.utilisateur
    )
    return {"code_liaison": code, "expire_le": expire_le.isoformat()}


@routeur.post("/admin/utilisateurs/{utilisateur_id}/code-liaison")
async def code_par_admin(
    utilisateur_id: uuid.UUID, admin: Admin, request: Request, session: SessionBase
) -> dict:
    """L'admin tire le code de liaison d'un convive, à remettre au parent."""
    convive = await session.get(Utilisateur, utilisateur_id, with_for_update=True)
    if convive is None or convive.supprime_le is not None:
        raise ErreurApi("introuvable", 404)
    code, expire_le = await liaison.nouveau_code(session, request.app.state.config.secret_key, convive)
    return {"code_liaison": code, "expire_le": expire_le.isoformat()}


@routeur.post("/parent/liaison")
async def lier(
    corps: LiaisonEntree, parent: Parent, request: Request, session: SessionBase
) -> dict[str, Any]:
    """Lie le parent à l'enfant qui porte ce code."""
    enfant = await liaison.lier(
        session, request.app.state.config.secret_key, parent.utilisateur, corps.code_liaison
    )
    return {"enfant": await _vue_enfant(session, enfant), "etat": "actif"}


@routeur.get("/parent/enfants")
async def mes_enfants(parent: Parent, session: SessionBase) -> list[dict[str, Any]]:
    """Enfants liés, avec solde, allergies et seuil d'alerte."""
    return [await _vue_enfant(session, e) for e in await liaison.enfants(session, parent.utilisateur.id)]


@routeur.delete("/parent/enfants/{enfant_id}")
async def delier(enfant_id: uuid.UUID, parent: Parent, session: SessionBase) -> dict[str, bool]:
    """Coupe le lien avec un enfant."""
    await liaison.delier(session, parent.utilisateur.id, enfant_id)
    return {"delie": True}


@routeur.get("/parent/enfants/{enfant_id}/repas")
async def repas(
    enfant_id: uuid.UUID,
    parent: Parent,
    session: SessionBase,
    du: Annotated[date | None, Query()] = None,
    au: Annotated[date | None, Query()] = None,
) -> list[dict[str, Any]]:
    """Repas commandés et servis d'un enfant lié."""
    enfant = await liaison.enfant_lie(session, parent.utilisateur.id, enfant_id)
    lignes, _ = await commandes_suivi.lister(session, enfant.id, du, au, 1, 100)
    vues = [await commandes_suivi.vue_reservation(session, r) for r in lignes]
    # Le code du ticket reste au convive : le parent voit le repas, pas de quoi le retirer à sa place.
    return [v.model_dump(mode="json", exclude={"code_ticket"}) for v in vues]


@routeur.put("/parent/enfants/{enfant_id}/seuil")
async def regler_seuil(
    enfant_id: uuid.UUID, corps: SeuilEntree, parent: Parent, session: SessionBase
) -> dict:
    """Seuil d'alerte de solde bas d'un enfant lié."""
    enfant = await liaison.enfant_lie(session, parent.utilisateur.id, enfant_id)
    enfant.seuil_alerte_solde = corps.seuil_alerte_solde
    return {"seuil_alerte_solde": enfant.seuil_alerte_solde}


@routeur.put("/parent/enfants/{enfant_id}/allergies")
async def regler_allergies(
    enfant_id: uuid.UUID, corps: AllergiesEntree, parent: Parent, session: SessionBase
) -> dict:
    """Allergies d'un enfant lié, dans la liste fermée."""
    enfant = await liaison.enfant_lie(session, parent.utilisateur.id, enfant_id)
    enfant.allergies = list(dict.fromkeys(corps.allergies))
    return {"allergies": enfant.allergies}
