"""Routes /api/v1/admin/avis et /admin/suggestions : modération des appréciations et lecture des suggestions.

Chaque décision de l'admin est journalisée ; une réponse de la cantine ne vaut que sur un avis publié.
"""

import uuid
from datetime import UTC, datetime
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.core.dependances import Admin, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Avis, Plat, Suggestion
from app.routes.avis import _vue
from app.services.journal import ecrire_journal

routeur = APIRouter(prefix="/api/v1", tags=["admin"])


@routeur.get("/admin/avis")
async def a_moderer(
    admin: Admin,
    session: SessionBase,
    etat: Annotated[Literal["a_examiner", "publie", "refuse"], Query()] = "a_examiner",
) -> list[dict[str, Any]]:
    """Appréciations d'un état, les plus récentes d'abord, avec le nom du plat."""
    lignes = await session.execute(
        select(Avis, Plat.nom_fr)
        .join(Plat, Plat.id == Avis.plat_id)
        .where(Avis.etat == etat)
        .order_by(Avis.cree_le.desc())
        .limit(200)
    )
    return [_vue(a) | {"plat": nom} for a, nom in lignes.all()]


class RefusEntree(BaseModel):
    """Corps de POST /admin/avis/{id}/refuser."""

    motif: str = Field(min_length=3, max_length=300)


class ReponseEntree(BaseModel):
    """Corps de POST /admin/avis/{id}/repondre."""

    reponse: str = Field(min_length=2, max_length=1000)


async def _avis(session: SessionBase, avis_id: uuid.UUID) -> Avis:
    avis = await session.get(Avis, avis_id, with_for_update=True)
    if avis is None:
        raise ErreurApi("introuvable", 404)
    return avis


@routeur.post("/admin/avis/{avis_id}/publier")
async def publier(avis_id: uuid.UUID, admin: Admin, request: Request, session: SessionBase) -> dict[str, Any]:
    """Publie une appréciation : elle compte dans la moyenne et devient visible."""
    avis = await _avis(session, avis_id)
    avant = {"etat": avis.etat}
    avis.etat = "publie"
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "publication_avis",
        "avis",
        avis.id,
        avant,
        {"etat": "publie"},
        adresse_client(request),
    )
    return _vue(avis)


@routeur.post("/admin/avis/{avis_id}/refuser")
async def refuser(
    avis_id: uuid.UUID, corps: RefusEntree, admin: Admin, request: Request, session: SessionBase
) -> dict:
    """Refuse une appréciation, motif obligatoire."""
    avis = await _avis(session, avis_id)
    avant = {"etat": avis.etat}
    avis.etat = "refuse"
    avis.motif_refus = corps.motif
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "refus_avis",
        "avis",
        avis.id,
        avant,
        {"etat": "refuse"},
        adresse_client(request),
    )
    return _vue(avis)


@routeur.post("/admin/avis/{avis_id}/repondre")
async def repondre(
    avis_id: uuid.UUID, corps: ReponseEntree, admin: Admin, session: SessionBase
) -> dict[str, Any]:
    """Répond au nom de la cantine à une appréciation publiée."""
    avis = await _avis(session, avis_id)
    if avis.etat != "publie":
        raise ErreurApi("avis_non_publie", 409)
    avis.reponse_cantine = corps.reponse
    avis.repondu_par = admin.utilisateur.id
    avis.repondu_le = datetime.now(UTC)
    return _vue(avis)


@routeur.get("/admin/suggestions")
async def suggestions_recues(admin: Admin, session: SessionBase) -> list[dict[str, str]]:
    """Les suggestions des convives, les plus récentes d'abord."""
    lignes = await session.scalars(select(Suggestion).order_by(Suggestion.cree_le.desc()).limit(200))
    return [
        {
            "id": str(s.id),
            "message": s.message,
            "plat_souhaite": s.plat_souhaite,
            "cree_le": s.cree_le.isoformat(),
        }
        for s in lignes.all()
    ]
