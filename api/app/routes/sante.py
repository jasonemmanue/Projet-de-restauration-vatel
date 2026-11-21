"""Route de santé, lue par Railway et par la recette pour connaître le commit déployé.

Elle répond sur /health (contrôle de Railway) et sur /api/v1/sante (nom du contrat d'API).
"""

from datetime import UTC, datetime

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from app import __version__
from app.db.session import SessionBase
from app.schemas.sante import EtatSante
from app.services.sante import base_repond

routeur = APIRouter(tags=["sante"])


@routeur.get("/health", response_model=EtatSante)
@routeur.get("/api/v1/sante", response_model=EtatSante, include_in_schema=False)
async def lire_sante(request: Request, session: SessionBase) -> JSONResponse:
    """Rend l'état de l'API ; 503 si la base ne répond pas, pour que Railway ne bascule pas dessus."""
    base_ok = await base_repond(session)
    etat = EtatSante(
        etat="ok" if base_ok else "degrade",
        version=__version__,
        commit=request.app.state.config.commit,
        base="ok" if base_ok else "indisponible",
        heure=datetime.now(UTC),
    )
    return JSONResponse(status_code=200 if base_ok else 503, content=etat.model_dump(mode="json"))
