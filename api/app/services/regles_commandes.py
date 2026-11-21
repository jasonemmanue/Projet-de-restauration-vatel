"""Règles métier des commandes et du porte-monnaie, en fonctions pures testées sans base.

Prix d'un jour (menu du profil plus suppléments), période couverte par un lot, solde après un mouvement.
"""

import calendar
from dataclasses import dataclass
from datetime import date, timedelta


@dataclass(frozen=True)
class LigneCommandee:
    """Un plat commandé un jour, avec son service, sa quantité et son prix de part supplémentaire."""

    plat_id: object
    service: str
    quantite: int
    prix_supplement_xof: int


def supplements(lignes: list[LigneCommandee]) -> list[int]:
    """Supplément de chaque ligne : le menu couvre une part par service, chaque part au-delà est facturée.

    Dans un service, la part couverte va à la ligne la plus chère en supplément, pour que le convive ne paie
    jamais plus que le juste prix.
    """
    resultat = [0] * len(lignes)
    par_service: dict[str, list[int]] = {}
    for indice, ligne in enumerate(lignes):
        par_service.setdefault(ligne.service, []).append(indice)
    for indices in par_service.values():
        ordre = sorted(indices, key=lambda i: lignes[i].prix_supplement_xof, reverse=True)
        couverte = False
        for i in ordre:
            parts = lignes[i].quantite - (0 if couverte else 1)
            couverte = True
            resultat[i] = max(parts, 0) * lignes[i].prix_supplement_xof
    return resultat


def total_du_jour(prix_menu: int, lignes: list[LigneCommandee]) -> int:
    """Prix du menu du jour plus les suppléments ; prendre moins que le menu ne baisse jamais le prix."""
    return prix_menu + sum(supplements(lignes))


def fin_de_periode(portee: str, debut: date) -> date:
    """Dernier jour couvert par un lot : le jour même, sept jours, ou jusqu'à la fin du mois du début."""
    if portee == "jour":
        return debut
    if portee == "semaine":
        return debut + timedelta(days=6)
    if portee == "mois":
        return debut.replace(day=calendar.monthrange(debut.year, debut.month)[1])
    raise ValueError("portée inconnue")


def solde_apres(solde: int, sens: str, montant: int) -> int:
    """Solde après un mouvement ; le montant est toujours positif, le sens dit s'il entre ou sort."""
    if montant <= 0:
        raise ValueError("montant positif attendu")
    return solde + montant if sens == "credit" else solde - montant
