"""Registre des blocs de recette, dans l'ordre où « --bloc tous » les lance.

Chaque étape qui crée un bloc ajoute son fichier dans ce dossier et sa ligne ici.
"""

from collections.abc import Callable

from recette.blocs import auth, menus, sante
from recette.executeur import Recette

BLOCS: dict[str, Callable[[Recette], None]] = {
    "sante": sante.lancer,
    "auth": auth.lancer,
    "menus": menus.lancer,
}
