"""Tests du format d'erreur unique {"code", "message"} sur tous les types d'échec."""

import httpx
from fastapi import FastAPI
from pydantic import BaseModel

from app.main import creer_application
from tests.conftest import client_pour, configuration_test


class _Corps(BaseModel):
    nombre: int


def _application_avec_routes_de_test(**reglages: object) -> FastAPI:
    application = creer_application(configuration_test(**reglages))

    @application.post("/essai/validation")
    async def _validation(corps: _Corps) -> dict[str, int]:
        return {"nombre": corps.nombre}

    @application.get("/essai/ok")
    async def _ok() -> dict[str, bool]:
        return {"ok": True}

    @application.get("/essai/panne")
    async def _panne() -> None:
        raise RuntimeError("détail technique secret")

    return application


def _format_unique(reponse: httpx.Response) -> dict[str, str]:
    corps = reponse.json()
    assert set(corps) == {"code", "message"}
    return corps


async def test_route_inconnue_404(client: httpx.AsyncClient) -> None:
    reponse = await client.get("/n-existe-pas")
    assert reponse.status_code == 404
    assert _format_unique(reponse)["code"] == "introuvable"


async def test_methode_refusee_405(client: httpx.AsyncClient) -> None:
    reponse = await client.delete("/health")
    assert reponse.status_code == 405
    assert _format_unique(reponse)["code"] == "methode_non_autorisee"


async def test_message_en_anglais_sur_demande(client: httpx.AsyncClient) -> None:
    reponse = await client.get("/n-existe-pas", headers={"Accept-Language": "en-US,en;q=0.9"})
    assert _format_unique(reponse)["message"] == "Resource not found."


async def test_validation_422_sans_detail() -> None:
    async with client_pour(_application_avec_routes_de_test()) as client:
        reponse = await client.post("/essai/validation", json={"nombre": "pas un nombre"})
    assert reponse.status_code == 422
    assert _format_unique(reponse)["code"] == "validation"
    assert "pas un nombre" not in reponse.text


async def test_erreur_inattendue_500_sans_trace() -> None:
    async with client_pour(_application_avec_routes_de_test()) as client:
        reponse = await client.get("/essai/panne")
    assert reponse.status_code == 500
    assert _format_unique(reponse)["code"] == "erreur_serveur"
    assert "secret" not in reponse.text
    assert "Traceback" not in reponse.text
    assert reponse.headers["x-frame-options"] == "DENY"


async def test_corps_trop_lourd_413() -> None:
    async with client_pour(_application_avec_routes_de_test(TAILLE_REQUETE_MAX_KO=1)) as client:
        reponse = await client.post("/essai/validation", content=b"x" * 4096)
    assert reponse.status_code == 413
    assert _format_unique(reponse)["code"] == "requete_trop_lourde"


async def test_limite_de_debit_429() -> None:
    async with client_pour(_application_avec_routes_de_test(LIMITE_DEBIT_DEFAUT="2/minute")) as client:
        statuts = [(await client.get("/essai/ok")).status_code for _ in range(2)]
        reponse = await client.get("/essai/ok")
    assert statuts == [200, 200]
    assert reponse.status_code == 429
    assert _format_unique(reponse)["code"] == "trop_de_requetes"
