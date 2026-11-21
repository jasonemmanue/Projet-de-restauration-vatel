"""Estimation des frais GeniusPay d'une recharge, en fonction pure testée sans base.

Chaque ligne est arrondie à l'entier XOF le plus proche (une demie monte), puis le total est la somme des
lignes arrondies : ce qui s'affiche s'additionne toujours. Le retrait se calcule sur ce qui reste après la
passerelle et GeniusPay.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class GrilleFrais:
    """Taux en parts pour dix mille (150 = 1,5 %) et part fixe en XOF."""

    geniuspay_pdm: int
    geniuspay_fixe_xof: int
    retrait_pdm: int
    passerelles_pdm: dict[str, int]


@dataclass(frozen=True)
class FraisEstimes:
    """Détail des frais d'une recharge et net attendu pour la cantine."""

    montant_xof: int
    passerelle_xof: int
    geniuspay_xof: int
    retrait_xof: int
    total_frais_xof: int
    net_xof: int


def arrondi(numerateur: int, denominateur: int) -> int:
    """Division entière arrondie au plus proche, une demie vers le haut, sans flottant."""
    return (2 * numerateur + denominateur) // (2 * denominateur)


def estimer(montant: int, operateur: str, grille: GrilleFrais) -> FraisEstimes | None:
    """Frais attendus d'une recharge ; None si l'opérateur n'a pas de taux dans la grille."""
    taux = grille.passerelles_pdm.get(operateur)
    if taux is None:
        return None
    passerelle = arrondi(montant * taux, 10_000)
    geniuspay = grille.geniuspay_fixe_xof + arrondi(montant * grille.geniuspay_pdm, 10_000)
    reste = max(montant - passerelle - geniuspay, 0)
    retrait = arrondi(reste * grille.retrait_pdm, 10_000)
    total = passerelle + geniuspay + retrait
    return FraisEstimes(montant, passerelle, geniuspay, retrait, total, montant - total)
