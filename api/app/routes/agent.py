"""Routes /api/v1/agent : scan des tickets, service du jour, liste et file des scans hors ligne.

Réservées au rôle agent (et à l'admin, qui peut dépanner le comptoir). Chaque scan porte une clé unique : un
renvoi rend le même résultat, sans servir deux fois.
"""

from datetime import UTC, date, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field

from app.core.dependances import Connecte, exiger_role
from app.db.session import SessionBase
from app.routes.reservations import CleGeste
from app.services import agent as service_agent

routeur = APIRouter(prefix="/api/v1/agent", tags=["agent"])
Agent = Annotated[Connecte, Depends(exiger_role("agent", "admin"))]


class ScanEntree(BaseModel):
    """Un scan : le contenu du QR et l'heure du scan sur l'appareil."""

    code_ticket: str = Field(min_length=10, max_length=200)
    scanne_le: datetime | None = None


class ScanEnFile(ScanEntree):
    """Un scan fait hors ligne, avec sa clé unique posée par l'appareil."""

    cle_unique: str = Field(min_length=8, max_length=100)


def _instant(valeur: datetime | None) -> datetime:
    if valeur is None:
        return datetime.now(UTC)
    return valeur if valeur.tzinfo else valeur.replace(tzinfo=UTC)


@routeur.post("/scan")
async def scanner(
    corps: ScanEntree, agent: Agent, cle: CleGeste, request: Request, session: SessionBase
) -> dict[str, Any]:
    """Scanne un ticket : `resultat` vaut accepte, deja_servi, mauvais_jour, annule ou inconnu."""
    return await service_agent.scanner(
        session,
        request.app.state.config.secret_key,
        agent.utilisateur.id,
        corps.code_ticket,
        _instant(corps.scanne_le),
        f"{agent.utilisateur.id}:{cle}",
    )


@routeur.post("/scan/file")
async def vider_la_file(
    corps: Annotated[list[ScanEnFile], Field(max_length=500)],
    agent: Agent,
    request: Request,
    session: SessionBase,
) -> list[dict[str, Any]]:
    """Rejoue les scans hors ligne un par un, dans l'ordre de l'appareil ; le premier scan l'emporte."""
    resultats = []
    for scan in corps:
        resultat = await service_agent.scanner(
            session,
            request.app.state.config.secret_key,
            agent.utilisateur.id,
            scan.code_ticket,
            _instant(scan.scanne_le),
            f"{agent.utilisateur.id}:{scan.cle_unique}",
        )
        resultats.append({"cle_unique": scan.cle_unique} | resultat)
    return resultats


@routeur.get("/service")
async def service(agent: Agent, session: SessionBase) -> dict[str, Any]:
    """Le service du jour : attendus, servis, restants."""
    return await service_agent.service_du_jour(session, datetime.now(UTC).date())


@routeur.get("/service/jour")
async def liste_du_jour(
    agent: Agent,
    request: Request,
    session: SessionBase,
    jour: Annotated[date | None, Query(alias="date")] = None,
) -> list[dict[str, Any]]:
    """Les tickets d'un jour (aujourd'hui par défaut), à garder sur l'appareil pour servir hors ligne."""
    return await service_agent.liste_hors_ligne(
        session, request.app.state.config.secret_key, jour or datetime.now(UTC).date()
    )
