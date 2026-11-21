"""Tests des règles pures des menus : prix du jour, allergènes, portions, gel, semaine, type de photo."""

import typing
import uuid
from datetime import UTC, date, datetime, time

from app.models.menus import ALLERGENES, REGIMES
from app.schemas.catalogue import Allergene, Regime
from app.services.regles_menus import (
    TarifLu,
    allergenes_en_commun,
    lundi_de,
    moment_du_gel,
    portions_restantes,
    prix_du_jour,
    semaine,
    type_de_photo,
)

JANVIER = datetime(2026, 1, 1, tzinfo=UTC)
JUIN = datetime(2026, 6, 1, tzinfo=UTC)


def test_prix_general_du_profil() -> None:
    tarifs = [TarifLu("eleve", 1500, None, JANVIER, None), TarifLu("employe", 2500, None, JANVIER, None)]
    assert prix_du_jour(tarifs, "eleve", uuid.uuid4(), JUIN) == 1500
    assert prix_du_jour(tarifs, "employe", uuid.uuid4(), JUIN) == 2500


def test_prix_absent_quand_aucun_tarif() -> None:
    assert prix_du_jour([TarifLu("eleve", 1500, None, JANVIER, None)], "visiteur", uuid.uuid4(), JUIN) is None


def test_le_plus_recent_l_emporte_et_le_futur_ne_compte_pas() -> None:
    tarifs = [
        TarifLu("eleve", 1500, None, JANVIER, None),
        TarifLu("eleve", 1700, None, datetime(2026, 5, 1, tzinfo=UTC), None),
        TarifLu("eleve", 2000, None, datetime(2026, 9, 1, tzinfo=UTC), None),
    ]
    assert prix_du_jour(tarifs, "eleve", uuid.uuid4(), JUIN) == 1700


def test_tarif_propre_au_menu_prioritaire() -> None:
    menu = uuid.uuid4()
    tarifs = [TarifLu("eleve", 1500, None, JANVIER, None), TarifLu("eleve", 1000, menu, JANVIER, None)]
    assert prix_du_jour(tarifs, "eleve", menu, JUIN) == 1000
    assert prix_du_jour(tarifs, "eleve", uuid.uuid4(), JUIN) == 1500


def test_tarif_clos_ignore() -> None:
    tarifs = [TarifLu("eleve", 1500, None, JANVIER, datetime(2026, 3, 1, tzinfo=UTC))]
    assert prix_du_jour(tarifs, "eleve", uuid.uuid4(), JUIN) is None


def test_allergenes_en_commun() -> None:
    assert allergenes_en_commun(["lait", "arachide", "gluten"], ["gluten", "arachide"]) == [
        "arachide",
        "gluten",
    ]
    assert allergenes_en_commun(["lait"], []) == []


def test_portions_jamais_negatives() -> None:
    assert portions_restantes(40, 12) == 28
    assert portions_restantes(10, 15) == 0


def test_gel_la_veille_a_l_heure_reglee() -> None:
    assert moment_du_gel(date(2026, 11, 24), 1, time(18, 0)) == datetime(2026, 11, 23, 18, 0, tzinfo=UTC)
    assert moment_du_gel(date(2026, 11, 24), 2, time(9, 30)) == datetime(2026, 11, 22, 9, 30, tzinfo=UTC)


def test_semaine_du_lundi() -> None:
    assert lundi_de(date(2026, 11, 26)) == date(2026, 11, 23)
    jours = semaine(date(2026, 11, 23))
    assert len(jours) == 7 and jours[-1] == date(2026, 11, 29)


def test_type_de_photo_par_les_premiers_octets() -> None:
    assert type_de_photo(b"\xff\xd8\xff\xe0" + b"0" * 20) == "image/jpeg"
    assert type_de_photo(b"\x89PNG\r\n\x1a\n" + b"0" * 20) == "image/png"
    assert type_de_photo(b"RIFF\x00\x00\x00\x00WEBPVP8 ") == "image/webp"
    assert type_de_photo(b"<svg onload=alert(1)>") is None


def test_listes_du_schema_egales_au_modele() -> None:
    assert set(typing.get_args(Allergene)) == set(ALLERGENES)
    assert set(typing.get_args(Regime)) == set(REGIMES)
