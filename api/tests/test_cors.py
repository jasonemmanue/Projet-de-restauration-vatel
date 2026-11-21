"""Tests du CORS en liste exacte et de la lecture de l'adresse réelle derrière le relais."""

import httpx
from starlette.requests import Request

from app.core.securite import adresse_reelle
from tests.conftest import ORIGINE_CONNUE

PRE_VERIFICATION = {"Access-Control-Request-Method": "GET"}


async def test_origine_inconnue_refusee(client: httpx.AsyncClient) -> None:
    reponse = await client.options(
        "/health", headers={"Origin": "https://pirate.example", **PRE_VERIFICATION}
    )
    assert reponse.status_code == 403
    assert reponse.json()["code"] == "origine_refusee"
    assert "access-control-allow-origin" not in reponse.headers


async def test_origine_inconnue_sans_autorisation_sur_requete_simple(client: httpx.AsyncClient) -> None:
    reponse = await client.get("/health", headers={"Origin": "https://pirate.example"})
    assert "access-control-allow-origin" not in reponse.headers


async def test_origine_connue_acceptee(client: httpx.AsyncClient) -> None:
    reponse = await client.options("/health", headers={"Origin": ORIGINE_CONNUE, **PRE_VERIFICATION})
    assert reponse.status_code == 200
    assert reponse.headers["access-control-allow-origin"] == ORIGINE_CONNUE


def _requete(entetes: dict[str, str]) -> Request:
    brutes = [(k.lower().encode(), v.encode()) for k, v in entetes.items()]
    return Request({"type": "http", "headers": brutes, "client": ("10.0.0.9", 1234)})


def test_adresse_reelle_prend_celle_du_relais() -> None:
    # Le client a inventé la première adresse ; le relais a ajouté la vraie à la fin.
    requete = _requete({"X-Forwarded-For": "1.2.3.4, 41.66.10.20"})
    assert adresse_reelle(requete, 1) == "41.66.10.20"


def test_adresse_reelle_sans_relais() -> None:
    assert adresse_reelle(_requete({}), 1) == "10.0.0.9"
