# Role du fichier : reduire un PNG deja rendu a une petite taille, pour les favicons.
# Le navigateur sans interface refuse les fenetres de moins de 64 pixels : on rend grand puis on reduit.
# Lancer : python docs/marque/outils/redimensionner.py <source> <cible> <taille>

import sys

from PIL import Image


def redimensionner(source: str, cible: str, taille: int) -> None:
    """Reduit une image carree a la taille demandee, en gardant la transparence."""
    image = Image.open(source)
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGBA")
    image = image.resize((taille, taille), Image.LANCZOS)
    image.save(cible, "PNG")
    print(f"reduit {cible} en {taille} pixels")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage : redimensionner.py <source> <cible> <taille>")
    redimensionner(sys.argv[1], sys.argv[2], int(sys.argv[3]))
