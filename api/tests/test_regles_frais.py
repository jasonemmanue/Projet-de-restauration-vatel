"""Tests de l'estimation des frais GeniusPay : exemple de l'exploitant, arrondi, opérateur inconnu."""

from app.services.regles_frais import GrilleFrais, arrondi, estimer

GRILLE = GrilleFrais(
    geniuspay_pdm=100,
    geniuspay_fixe_xof=100,
    retrait_pdm=100,
    passerelles_pdm={"wave": 150, "orange": 350, "mtn": 350},
)


def test_exemple_de_l_exploitant_wave_500() -> None:
    frais = estimer(500, "wave", GRILLE)
    assert frais is not None
    assert (frais.passerelle_xof, frais.geniuspay_xof, frais.retrait_xof) == (8, 105, 4)
    assert frais.total_frais_xof == 117 and frais.net_xof == 383


def test_les_lignes_s_additionnent_toujours() -> None:
    for montant in (500, 1000, 1500, 2500, 9999, 60000):
        frais = estimer(montant, "orange", GRILLE)
        assert frais is not None
        assert frais.passerelle_xof + frais.geniuspay_xof + frais.retrait_xof == frais.total_frais_xof
        assert frais.total_frais_xof + frais.net_xof == montant


def test_arrondi_demie_vers_le_haut() -> None:
    assert arrondi(75000, 10000) == 8
    assert arrondi(74999, 10000) == 7
    assert arrondi(0, 10000) == 0


def test_operateur_sans_taux() -> None:
    assert estimer(1000, "moov", GRILLE) is None
