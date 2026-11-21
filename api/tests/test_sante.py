"""Tests de la route de santé, avec et sans base joignable."""

import httpx

from tests.conftest import client_pour, exige_base


@exige_base
async def test_sante_ok_avec_commit(application_base) -> None:
    async with client_pour(application_base) as client:
        reponse = await client.get("/health")
    assert reponse.status_code == 200
    corps = reponse.json()
    assert corps["etat"] == "ok"
    assert corps["base"] == "ok"
    assert corps["commit"] == "abcdef1"
    assert corps["version"]
    assert reponse.headers["x-version-commit"] == "abcdef1"


@exige_base
async def test_sante_aussi_sur_le_chemin_du_contrat(application_base) -> None:
    async with client_pour(application_base) as client:
        reponse = await client.get("/api/v1/sante")
    assert reponse.status_code == 200
    assert reponse.json()["etat"] == "ok"


async def test_sante_503_sans_base(client: httpx.AsyncClient) -> None:
    reponse = await client.get("/health")
    assert reponse.status_code == 503
    assert reponse.json()["base"] == "indisponible"


async def test_entetes_de_securite_presents(client: httpx.AsyncClient) -> None:
    reponse = await client.get("/health")
    assert reponse.headers["strict-transport-security"].startswith("max-age=")
    assert reponse.headers["x-content-type-options"] == "nosniff"
    assert reponse.headers["x-frame-options"] == "DENY"
    assert reponse.headers["referrer-policy"] == "no-referrer"
