"""Tests des règles pures des comptes : identifiants, mot de passe, codes, masquage."""

import typing

import pytest

from app.models.comptes import STATUTS_CONVIVE
from app.schemas.comptes import StatutConvive
from app.services.regles_comptes import (
    ALPHABET_CODE_EMAIL,
    Identifiant,
    IdentifiantInvalideError,
    generer_code,
    masquer_identifiant,
    mot_de_passe_valide,
    normaliser_code,
    normaliser_email,
    normaliser_identifiant,
    normaliser_telephone,
)


@pytest.mark.parametrize(
    ("saisie", "attendu"),
    [
        ("+2250707070707", "+2250707070707"),
        ("07 07 07 07 07", "+2250707070707"),
        ("00225 05.01.02.03.04", "+2250501020304"),
        ("+33 6 12 34 56 78", "+33612345678"),
    ],
)
def test_telephone_normalise(saisie: str, attendu: str) -> None:
    assert normaliser_telephone(saisie) == attendu


@pytest.mark.parametrize("saisie", ["+2252707070707", "+225070707070", "0707", "abc", "+0123456789"])
def test_telephone_refuse(saisie: str) -> None:
    with pytest.raises(IdentifiantInvalideError):
        normaliser_telephone(saisie)


def test_email_en_minuscules_et_refus() -> None:
    assert normaliser_email("  Awa.Kone@Gmail.COM ") == "awa.kone@gmail.com"
    with pytest.raises(IdentifiantInvalideError):
        normaliser_email("pas-un-email")


def test_canal_devine_par_l_arobase() -> None:
    assert normaliser_identifiant("a@b.ci").canal == "email"
    assert normaliser_identifiant("0707070707").canal == "telephone"


@pytest.mark.parametrize(
    ("mot_de_passe", "valide"),
    [
        ("Cantine2026", True),
        ("court1", False),
        ("sanschiffre", False),
        ("12345678", False),
        ("a1" * 33, False),
    ],
)
def test_force_du_mot_de_passe(mot_de_passe: str, valide: bool) -> None:
    assert mot_de_passe_valide(mot_de_passe) is valide


def test_mot_de_passe_sans_reprendre_l_identifiant() -> None:
    email = Identifiant("email", "awakone@gmail.com")
    assert not mot_de_passe_valide("Awakone2026", email)
    telephone = Identifiant("telephone", "+2250707123456")
    assert not mot_de_passe_valide("x07123456", telephone)
    assert mot_de_passe_valide("Cantine2026", telephone)


def test_codes_au_bon_format() -> None:
    for _ in range(50):
        chiffres = generer_code("telephone")
        assert len(chiffres) == 6 and chiffres.isdigit()
        lettres = generer_code("email")
        assert len(lettres) == 5 and set(lettres) <= set(ALPHABET_CODE_EMAIL)


def test_code_lu_sans_casse_ni_espaces() -> None:
    assert normaliser_code(" ab 3c d ") == "AB3CD"


def test_masquage() -> None:
    assert masquer_identifiant(Identifiant("email", "jean@gmail.com")) == "j***@gmail.com"
    assert masquer_identifiant(Identifiant("telephone", "+2250707123412")) == "+225 07 XX XX 12"


def test_statuts_du_schema_egaux_au_modele() -> None:
    assert set(typing.get_args(StatutConvive)) == set(STATUTS_CONVIVE)
