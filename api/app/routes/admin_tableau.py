"""Routes /api/v1/admin/commandes-jour et /admin/tableau-bord, réservées à l'admin, en lecture seule."""

from datetime import UTC, date, datetime, timedelta
from typing import Annotated, Any

from fastapi import APIRouter, Query

from app.core.dependances import Admin
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.services.tableau_bord import commandes_du_jour, tableau_de_bord

routeur = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@routeur.get("/commandes-jour")
async def lire_commandes_du_jour(
    admin: Admin, session: SessionBase, jour: Annotated[date | None, Query(alias="date")] = None
) -> dict[str, Any]:
    """Parts à préparer pour un jour (aujourd'hui par défaut), par service et par plat."""
    return await commandes_du_jour(session, jour or datetime.now(UTC).date())


@routeur.get("/tableau-bord")
async def lire_tableau_de_bord(
    admin: Admin,
    session: SessionBase,
    du: Annotated[date | None, Query()] = None,
    au: Annotated[date | None, Query()] = None,
) -> dict[str, Any]:
    """Chiffres d'une période ; par défaut les 7 derniers jours, aujourd'hui compris."""
    fin = au or datetime.now(UTC).date()
    debut = du or fin - timedelta(days=6)
    if debut > fin or (fin - debut).days > 366:
        raise ErreurApi("validation", 422)
    return await tableau_de_bord(session, debut, fin)
