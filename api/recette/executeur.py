"""Exécuteur commun de la recette : une coche ou une croix par contrôle, puis le total.

Il ne lève pas d'exception sur un contrôle raté : il le compte, pour que la recette aille au bout et que le
nettoyage des comptes de recette se fasse toujours.
"""

import sys
from collections.abc import Callable
from dataclasses import dataclass, field

import httpx

COCHE = "✓"
CROIX = "✗"


@dataclass
class Recette:
    """État d'une passe de recette : client HTTP, résultats et comptes à supprimer à la fin."""

    url: str
    client: httpx.Client
    controles: int = 0
    echecs: list[str] = field(default_factory=list)
    nettoyages: list[Callable[[], object]] = field(default_factory=list)

    def verifier(self, libelle: str, condition: bool, detail: str = "") -> bool:
        """Enregistre un contrôle et affiche son résultat ; le détail ne contient jamais de secret."""
        self.controles += 1
        if condition:
            print(f"  {COCHE} {libelle}")
        else:
            self.echecs.append(libelle)
            suite = f" ({detail})" if detail else ""
            print(f"  {CROIX} {libelle}{suite}")
        return condition

    def a_nettoyer(self, action: Callable[[], object]) -> None:
        """Enregistre une action de suppression lancée à la fin, même après un échec."""
        self.nettoyages.append(action)

    def nettoyer(self) -> None:
        """Lance toutes les suppressions, la plus récente d'abord, sans s'arrêter sur une erreur."""
        for action in reversed(self.nettoyages):
            try:
                action()
            except Exception as exc:  # une suppression ratée ne doit pas masquer les autres
                print(f"  {CROIX} nettoyage impossible : {type(exc).__name__}")
                self.echecs.append("nettoyage")
        self.nettoyages.clear()

    def total(self) -> int:
        """Affiche le total et rend le code de sortie : 1 s'il y a au moins un échec."""
        print(f"\n{self.controles} contrôles, {len(self.echecs)} échecs")
        return 1 if self.echecs else 0


def preparer_console() -> None:
    """Force l'UTF-8 sur la sortie, pour que coches et croix s'affichent aussi sous Windows."""
    for flux in (sys.stdout, sys.stderr):
        reconfigurer = getattr(flux, "reconfigure", None)
        if reconfigurer:
            reconfigurer(encoding="utf-8")


def creer_client(url: str) -> httpx.Client:
    """Client HTTP de la recette, avec un délai large pour un démarrage à froid de Railway."""
    return httpx.Client(base_url=url, timeout=httpx.Timeout(30.0), follow_redirects=False)
