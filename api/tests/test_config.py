"""Tests de la configuration : URL de base, commit, valeurs d'exemple et origines CORS."""

import pytest
from pydantic import ValidationError

from app.core.config import (
    Configuration,
    est_valeur_exemple,
    lire_origines,
    normaliser_url_base,
    raccourcir_commit,
)
from tests.conftest import configuration_test


@pytest.mark.parametrize(
    ("entree", "attendu"),
    [
        ("postgres://u:p@h:5432/b", "postgresql+asyncpg://u:p@h:5432/b"),
        ("postgresql://u:p@h/b", "postgresql+asyncpg://u:p@h/b"),
        ("postgresql+asyncpg://u:p@h/b", "postgresql+asyncpg://u:p@h/b"),
    ],
)
def test_url_railway_convertie_pour_asyncpg(entree: str, attendu: str) -> None:
    assert normaliser_url_base(entree) == attendu


def test_url_non_postgres_refusee() -> None:
    with pytest.raises(ValueError):
        normaliser_url_base("mysql://u:p@h/b")


def test_commit_raccourci_ou_local() -> None:
    assert raccourcir_commit("0123456789abcdef") == "0123456"
    assert raccourcir_commit(None) == "local"
    assert raccourcir_commit("  ") == "local"


@pytest.mark.parametrize(
    "valeur", ["", "changeme", "<votre-secret>", "a_remplacer", "postgresql://user:password@host:5432/db"]
)
def test_valeurs_exemple_reconnues(valeur: str) -> None:
    assert est_valeur_exemple(valeur)


def test_vrai_secret_accepte() -> None:
    assert not est_valeur_exemple("9f2c41d07be35a6e88c1f0d2b4a7e6c3")


def test_origines_decoupees_et_joker_refuse() -> None:
    assert lire_origines("https://a.ci, https://b.ci/") == ["https://a.ci", "https://b.ci"]
    with pytest.raises(ValueError):
        lire_origines("*")
    with pytest.raises(ValueError):
        lire_origines("a.ci")


def test_demarrage_refuse_sans_variable_obligatoire(monkeypatch: pytest.MonkeyPatch) -> None:
    for nom in (
        "DATABASE_URL",
        "SECRET_KEY",
        "JWT_SECRET",
        "ADMIN_ACTIONS_PASSWORD",
        "CORS_ORIGINS",
        "CORS_ORIGINES",
    ):
        monkeypatch.delenv(nom, raising=False)
    with pytest.raises(ValidationError):
        Configuration(_env_file=None)  # type: ignore[call-arg]


def test_demarrage_refuse_avec_secret_exemple() -> None:
    with pytest.raises(ValidationError):
        configuration_test(SECRET_KEY="changeme-changeme-changeme-changeme-changeme")


def test_configuration_complete_lue() -> None:
    config = configuration_test()
    assert config.database_url.startswith("postgresql+asyncpg://")
    assert config.commit == "abcdef1"
    assert config.cors_origins == ["https://app.vatel.test"]
