"""Stockage des médias sur le volume : photos des plats et images de démonstration.

Un chemin demandé est toujours résolu à l'intérieur du dossier des médias : « .. », chemin absolu ou lien
qui sortirait du dossier sont refusés. Les écritures passent par un fichier temporaire renommé, pour qu'une
image ne soit jamais lue à moitié écrite.
"""

import logging
import os
import shutil
from pathlib import Path

from anyio import to_thread

journal = logging.getLogger("vatel.stockage")
DOSSIER_DEMO = Path(__file__).resolve().parents[2] / "demo" / "images"
EXTENSIONS = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}
TYPES_PAR_EXTENSION = {f".{v}": k for k, v in EXTENSIONS.items()} | {".jpeg": "image/jpeg"}


class CheminInterditError(ValueError):
    """Le chemin demandé sortirait du dossier des médias."""


def resoudre(racine: str, relatif: str) -> Path:
    """Chemin absolu d'un média, garanti à l'intérieur de la racine."""
    base = Path(racine).resolve()
    cible = (base / relatif).resolve()
    if base != cible and base not in cible.parents:
        raise CheminInterditError(relatif)
    return cible


def _ecrire_sync(cible: Path, contenu: bytes) -> None:
    cible.parent.mkdir(parents=True, exist_ok=True)
    temporaire = cible.with_suffix(cible.suffix + ".tmp")
    temporaire.write_bytes(contenu)
    os.replace(temporaire, cible)


async def ecrire(racine: str, relatif: str, contenu: bytes) -> None:
    """Écrit un média, hors de la boucle de l'API."""
    await to_thread.run_sync(_ecrire_sync, resoudre(racine, relatif), contenu)


def type_par_extension(chemin: Path) -> str | None:
    """Type d'image d'après l'extension d'un fichier déjà contrôlé à son dépôt."""
    return TYPES_PAR_EXTENSION.get(chemin.suffix.lower())


def copier_demo(racine: str) -> int:
    """Copie les images de démonstration dans `demo/` du volume, sans écraser une image déjà là."""
    if not DOSSIER_DEMO.is_dir():
        return 0
    destination = resoudre(racine, "demo")
    destination.mkdir(parents=True, exist_ok=True)
    copiees = 0
    for image in sorted(DOSSIER_DEMO.glob("*.jpg")):
        cible = destination / image.name
        if not cible.exists():
            shutil.copyfile(image, cible)
            copiees += 1
    journal.info("images de démonstration copiées : %d", copiees)
    return copiees
