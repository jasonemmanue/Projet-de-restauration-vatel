"""Comptes et secrets de la recette.

Les identifiants de l'admin de recette et le mot de passe des actions sont lus dans le terminal de
l'exploitant, jamais dans le dépôt, et ne sont jamais affichés. Les comptes créés portent un nom
recette-<date et heure> pour être reconnus et supprimés, y compris par la remise à zéro.
"""

import os
from dataclasses import dataclass
from datetime import UTC, datetime

VARIABLES_ADMIN = ("RECETTE_ADMIN_IDENTIFIANT", "RECETTE_ADMIN_MOT_DE_PASSE")
VARIABLE_ACTIONS = "RECETTE_MOT_DE_PASSE_ACTIONS"


@dataclass(frozen=True)
class IdentifiantsAdmin:
    """Identifiants du compte admin de recette ; la représentation masque le mot de passe."""

    identifiant: str
    mot_de_passe: str

    def __repr__(self) -> str:
        return "IdentifiantsAdmin(identifiant=***, mot_de_passe=***)"


class SecretManquantError(RuntimeError):
    """Une variable de recette attendue n'est pas posée dans le terminal."""


def nom_compte_recette(maintenant: datetime | None = None) -> str:
    """Nom d'un compte de recette, recette-AAAAMMJJ-HHMMSS en UTC."""
    instant = maintenant or datetime.now(UTC)
    return "recette-" + instant.strftime("%Y%m%d-%H%M%S")


def lire_identifiants_admin() -> IdentifiantsAdmin:
    """Lit les identifiants de l'admin de recette ; échoue en nommant la variable, jamais sa valeur."""
    valeurs = [os.environ.get(nom, "").strip() for nom in VARIABLES_ADMIN]
    manquantes = [nom for nom, valeur in zip(VARIABLES_ADMIN, valeurs, strict=True) if not valeur]
    if manquantes:
        raise SecretManquantError("variables absentes : " + ", ".join(manquantes))
    return IdentifiantsAdmin(identifiant=valeurs[0], mot_de_passe=valeurs[1])


def lire_mot_de_passe_actions() -> str:
    """Lit le mot de passe des actions protégées, sans jamais l'afficher."""
    valeur = os.environ.get(VARIABLE_ACTIONS, "").strip()
    if not valeur:
        raise SecretManquantError("variable absente : " + VARIABLE_ACTIONS)
    return valeur
