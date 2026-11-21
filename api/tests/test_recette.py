"""Tests du module de recette : nommage des comptes, secrets jamais affichés, exécuteur et bloc santé."""

from datetime import UTC, datetime

import httpx
import pytest

from recette.__main__ import principal
from recette.comptes import (
    IdentifiantsAdmin,
    SecretManquantError,
    lire_identifiants_admin,
    nom_compte_recette,
)
from recette.executeur import Recette


def test_nom_compte_recette_date_et_heure() -> None:
    assert nom_compte_recette(datetime(2026, 11, 21, 9, 5, 7, tzinfo=UTC)) == "recette-20261121-090507"


def test_identifiants_masques_a_l_affichage() -> None:
    identifiants = IdentifiantsAdmin(identifiant="admin@vatel.ci", mot_de_passe="tres-secret")
    assert "tres-secret" not in repr(identifiants)
    assert "admin@vatel.ci" not in repr(identifiants)


def test_secret_absent_nomme_la_variable(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("RECETTE_ADMIN_IDENTIFIANT", raising=False)
    monkeypatch.setenv("RECETTE_ADMIN_MOT_DE_PASSE", "tres-secret")
    with pytest.raises(SecretManquantError) as erreur:
        lire_identifiants_admin()
    assert "RECETTE_ADMIN_IDENTIFIANT" in str(erreur.value)
    assert "tres-secret" not in str(erreur.value)


def test_nettoyage_lance_meme_apres_echec(capsys: pytest.CaptureFixture[str]) -> None:
    supprimes: list[str] = []
    recette = Recette(url="https://x", client=httpx.Client())
    recette.a_nettoyer(lambda: supprimes.append("recette-1"))
    recette.verifier("contrôle raté", False)
    recette.nettoyer()
    assert supprimes == ["recette-1"]
    assert recette.total() == 1
    assert "1 contrôles, 1 échecs" in capsys.readouterr().out


def test_commit_attendu_different_arrete_la_recette(monkeypatch: pytest.MonkeyPatch) -> None:
    def _transport(requete: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"commit": "abc1234"})

    monkeypatch.setattr(
        "recette.__main__.creer_client",
        lambda url: httpx.Client(base_url=url, transport=httpx.MockTransport(_transport)),
    )
    assert principal(["--url", "https://api.test", "--bloc", "sante", "--commit", "fff0000"]) == 1
