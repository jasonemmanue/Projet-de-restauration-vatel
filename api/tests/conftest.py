"""Montage commun des tests : configuration de test, base migrée et client HTTP sur l'application.

Les tests qui touchent la base lisent TEST_DATABASE_URL (jamais la base de production) et appliquent la
migration au premier usage. Sans cette variable, ils sont ignorés avec la raison affichée.
"""

import os
import secrets
import subprocess
import sys
import tempfile
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI

from app.core.config import Configuration
from app.main import creer_application

DOSSIER_API = Path(__file__).resolve().parent.parent
# Médias des tests dans un dossier temporaire du système, jamais dans le dépôt.
SECRET_WEBHOOK_TEST = "whsec_test_" + "x" * 24
DOSSIER_MEDIAS_TEST = str(Path(tempfile.gettempdir()) / "vatel-medias-tests")
ORIGINE_CONNUE = "https://app.vatel.test"
URL_BASE_TEST = os.environ.get("TEST_DATABASE_URL", "")
# Base injoignable : sert aux tests qui ne lisent pas la base.
URL_SANS_BASE = "postgresql://test:mot_de_passe_test@127.0.0.1:1/aucune"

exige_base = pytest.mark.skipif(not URL_BASE_TEST, reason="TEST_DATABASE_URL absente")


def configuration_test(url_base: str = URL_SANS_BASE, **valeurs: object) -> Configuration:
    """Configuration complète et sûre pour les tests, sans lire de fichier .env."""
    reglages: dict[str, object] = {
        "DATABASE_URL": url_base,
        "SECRET_KEY": "k" * 48,
        "ADMIN_ACTIONS_PASSWORD": "mot-de-passe-actions-test",
        "CORS_ORIGINS": ORIGINE_CONNUE,
        "RAILWAY_GIT_COMMIT_SHA": "abcdef1234567890",
        "LOG_NIVEAU": "warning",
        "BCRYPT_TOURS": 4,
        "STOCKAGE_DOSSIER": DOSSIER_MEDIAS_TEST,
        "GENIUSPAY_CLE_PUBLIQUE_TEST": "pk_sandbox_test",
        "GENIUSPAY_CLE_SECRETE_TEST": "sk_sandbox_test",
        "GENIUSPAY_SECRET_WEBHOOK_TEST": SECRET_WEBHOOK_TEST,
    }
    reglages.update(valeurs)
    return Configuration(_env_file=None, **reglages)  # type: ignore[arg-type]


def adresse_aleatoire() -> str:
    """Adresse IP de test tirée au hasard : les compteurs par adresse ne se mélangent pas entre tests."""
    return "10.{}.{}.{}".format(*(secrets.randbelow(250) + 1 for _ in range(3)))


def client_pour(application: FastAPI, adresse: str | None = None) -> httpx.AsyncClient:
    """Client HTTP branché directement sur l'application, sans réseau, derrière un faux relais."""
    transport = httpx.ASGITransport(app=application, raise_app_exceptions=False)
    entetes = {"X-Forwarded-For": adresse or adresse_aleatoire()}
    return httpx.AsyncClient(transport=transport, base_url="https://testserver", headers=entetes)


@pytest.fixture(scope="session")
def base_migree() -> str:
    """Applique la migration sur la base de test et rend son URL."""
    if not URL_BASE_TEST:
        pytest.skip("TEST_DATABASE_URL absente")
    environnement = {**os.environ, "DATABASE_URL": URL_BASE_TEST}
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"], cwd=DOSSIER_API, env=environnement, check=True
    )
    return URL_BASE_TEST


@pytest.fixture
async def client() -> AsyncIterator[httpx.AsyncClient]:
    """Client sur une application sans base joignable."""
    application = creer_application(configuration_test())
    async with client_pour(application) as c:
        yield c
    await application.state.moteur.dispose()


@pytest.fixture
async def application_base(base_migree: str) -> AsyncIterator[FastAPI]:
    """Application branchée sur la base de test migrée."""
    application = creer_application(configuration_test(base_migree))
    yield application
    await application.state.moteur.dispose()


@pytest.fixture
async def client_base(application_base: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    """Client sur l'application branchée à la base de test, avec sa propre adresse IP."""
    async with client_pour(application_base) as c:
        yield c
