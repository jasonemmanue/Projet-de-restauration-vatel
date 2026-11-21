# Role du fichier : produire les SVG de la marque Cantine Vatel dans docs/marque/.
# La geometrie du symbole et les couleurs viennent de la maquette (shared/components/Logo.tsx).
# Le nom et la signature sont convertis en trace avec fontTools, pour qu aucune police ne soit requise.
# Lancer : python docs/marque/outils/svg_marque.py

from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

RACINE = Path(__file__).resolve().parents[3]
SORTIE = RACINE / "docs" / "marque"
POLICES = SORTIE / "polices"

# Couleurs de la marque, recopiees de Logo.tsx. Elles ne suivent pas les jetons d interface.
TONS = {
    "clair": {"trait": "#171717", "accent": "#2557d6", "fond": "#ffffff", "signature": "#64748b"},
    "sombre": {"trait": "#f5f5f4", "accent": "#6b93ff", "fond": "#1c1c1c", "signature": "#9ca3af"},
}

NOM = "Cantine Vatel"
SIGNATURE = "CRÉNEAU · REPAS · QR"

# Rapports repris de Logo.tsx pour la taille 48, appliques ici a un symbole de 64.
ECHELLE = 64 / 48
TAILLE_SYMBOLE = 64.0
ECART = 14 * ECHELLE
TAILLE_NOM = 20 * ECHELLE
TAILLE_SIGNATURE = 10 * ECHELLE
MARGE_SIGNATURE = 3 * ECHELLE
HAUTEUR_LIGNE = 1.05
INTERLETTRAGE_NOM = -0.045
INTERLETTRAGE_SIGNATURE = 0.08


def chemin_police(graisse: int) -> Path:
    """Rend le fichier woff de Plus Jakarta Sans pour une graisse, ou leve une erreur claire."""
    noms = [
        POLICES / f"plus-jakarta-sans-latin-{graisse}-normal.woff",
        RACINE / "docs" / "maquette" / "node_modules" / "@fontsource" / "plus-jakarta-sans" / "files"
        / f"plus-jakarta-sans-latin-{graisse}-normal.woff",
        RACINE / "uiux vatel" / "INTERFACE_SAKAM" / "node_modules" / "@fontsource" / "plus-jakarta-sans"
        / "files" / f"plus-jakarta-sans-latin-{graisse}-normal.woff",
    ]
    for nom in noms:
        if nom.exists():
            return nom
    raise SystemExit(f"Police introuvable pour la graisse {graisse}. Cherchee dans : {noms}")


def tracer_texte(texte: str, graisse: int, taille: float, interlettrage: float) -> tuple:
    """Rend (chemin SVG, largeur, ascendante, descendante) du texte converti en trace."""
    police = TTFont(chemin_police(graisse))
    upem = police["head"].unitsPerEm
    jeu = police.getGlyphSet()
    cmap = police.getBestCmap()
    echelle = taille / upem
    ecart = interlettrage * taille

    morceaux = []
    avance = 0.0
    for index, caractere in enumerate(texte):
        point = ord(caractere)
        if point not in cmap:
            # Le point median n est pas toujours dans le sous ensemble latin : il est dessine a la main.
            if caractere == "·":
                rayon = taille * 0.055
                centre = avance + taille * 0.16
                morceaux.append(
                    f"M {centre - rayon:.2f} {-taille * 0.3:.2f} "
                    f"a {rayon:.2f} {rayon:.2f} 0 1 0 {rayon * 2:.2f} 0 "
                    f"a {rayon:.2f} {rayon:.2f} 0 1 0 {-rayon * 2:.2f} 0 z"
                )
                avance += taille * 0.32 + ecart
                continue
            if caractere == " ":
                avance += taille * 0.26 + ecart
                continue
            raise SystemExit(f"Caractere absent de la police : {caractere!r}")
        nom_glyphe = cmap[point]
        plume = SVGPathPen(jeu)
        jeu[nom_glyphe].draw(plume)
        trace = plume.getCommands()
        if trace:
            morceaux.append(
                f'<g transform="translate({avance:.3f} 0) scale({echelle:.6f} {-echelle:.6f})">'
                f'<path d="{trace}"/></g>'
            )
        avance += jeu[nom_glyphe].width * echelle
        if index < len(texte) - 1:
            avance += ecart

    ascendante = police["hhea"].ascent * echelle
    descendante = police["hhea"].descent * echelle
    police.close()
    # Les glyphes deja enveloppes sont rendus tels quels, les dessins manuels sont des chemins simples.
    contenu = "".join(m if m.startswith("<g") else f'<path d="{m}"/>' for m in morceaux)
    return contenu, avance, ascendante, descendante


def symbole(ton: dict, monochrome: str | None = None, fond_plein: bool = True) -> str:
    """Rend le groupe SVG du symbole : assiette, encoche de creneau, aiguille et reperes."""
    trait = monochrome or ton["trait"]
    accent = monochrome or ton["accent"]
    fond = ton["fond"] if fond_plein and not monochrome else "none"
    opacite = "0.35" if not monochrome else "0.5"
    opacite_reperes = "0.45" if not monochrome else "0.55"
    return f"""  <circle cx="32" cy="32" r="28" fill="{fond}" stroke="{trait}" stroke-width="3"/>
  <circle cx="32" cy="32" r="22" stroke="{trait}" stroke-width="1.5" fill="none" opacity="{opacite}"/>
  <path d="M32 2.5 L38.5 14.5 L25.5 14.5 Z" fill="{accent}"/>
  <circle cx="32" cy="33" r="11" stroke="{trait}" stroke-width="2.25" fill="none"/>
  <circle cx="32" cy="33" r="3.2" fill="{accent}"/>
  <path d="M32 33 L41.5 26.5" stroke="{accent}" stroke-width="2.75" stroke-linecap="round"/>
  <circle cx="32" cy="18.5" r="1.4" fill="{trait}" opacity="{opacite_reperes}"/>
  <circle cx="45.5" cy="33" r="1.4" fill="{trait}" opacity="{opacite_reperes}"/>
  <circle cx="32" cy="47.5" r="1.4" fill="{trait}" opacity="{opacite_reperes}"/>
  <circle cx="18.5" cy="33" r="1.4" fill="{trait}" opacity="{opacite_reperes}"/>"""


def ecrire(nom: str, contenu: str) -> None:
    """Ecrit un fichier SVG dans docs/marque/ et l annonce."""
    cible = SORTIE / nom
    cible.write_text(contenu, encoding="utf-8")
    print(f"ecrit {cible.relative_to(RACINE)}")


def svg_symbole(nom_fichier: str, ton: dict, monochrome: str | None, fond_plein: bool) -> None:
    """Ecrit un SVG du symbole seul, en 64 par 64."""
    contenu = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none" '
        'role="img" aria-label="Cantine Vatel">\n'
        f"{symbole(ton, monochrome, fond_plein)}\n</svg>\n"
    )
    ecrire(nom_fichier, contenu)


def svg_complet(nom_fichier: str, ton: dict, monochrome: str | None, fond_plein: bool) -> None:
    """Ecrit un SVG du logo complet : symbole, nom et signature, le texte en trace."""
    trace_nom, largeur_nom, asc_nom, desc_nom = tracer_texte(NOM, 700, TAILLE_NOM, INTERLETTRAGE_NOM)
    trace_sig, largeur_sig, asc_sig, desc_sig = tracer_texte(
        SIGNATURE, 600, TAILLE_SIGNATURE, INTERLETTRAGE_SIGNATURE
    )

    hauteur_nom = TAILLE_NOM * HAUTEUR_LIGNE
    hauteur_sig = TAILLE_SIGNATURE * HAUTEUR_LIGNE
    hauteur_bloc = hauteur_nom + MARGE_SIGNATURE + hauteur_sig
    haut_bloc = (TAILLE_SYMBOLE - hauteur_bloc) / 2

    base_nom = haut_bloc + (hauteur_nom - (asc_nom - desc_nom)) / 2 + asc_nom
    base_sig = haut_bloc + hauteur_nom + MARGE_SIGNATURE + (hauteur_sig - (asc_sig - desc_sig)) / 2 + asc_sig

    x_texte = TAILLE_SYMBOLE + ECART
    largeur = x_texte + max(largeur_nom, largeur_sig)
    couleur_nom = monochrome or ton["trait"]
    couleur_sig = monochrome or ton["signature"]

    contenu = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{largeur:.0f}" height="64" '
        f'viewBox="0 0 {largeur:.2f} 64" fill="none" role="img" aria-label="Cantine Vatel, creneau repas QR">\n'
        f"{symbole(ton, monochrome, fond_plein)}\n"
        f'  <g transform="translate({x_texte:.2f} {base_nom:.2f})" fill="{couleur_nom}">{trace_nom}</g>\n'
        f'  <g transform="translate({x_texte:.2f} {base_sig:.2f})" fill="{couleur_sig}">{trace_sig}</g>\n'
        "</svg>\n"
    )
    ecrire(nom_fichier, contenu)


def svg_silhouette() -> None:
    """Ecrit la silhouette blanche pleine, pour l icone de notification et le monochrome Android."""
    contenu = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path fill="#ffffff" fill-rule="evenodd" d="M32 4a28 28 0 1 1 0 56 28 28 0 0 1 0-56Zm0 9.5a18.5 18.5 0 1 0 0 37 18.5 18.5 0 0 0 0-37Z"/>
  <path fill="#ffffff" d="M32 1 L39.8 15.5 L24.2 15.5 Z"/>
  <circle fill="#ffffff" cx="32" cy="33" r="4.4"/>
  <path stroke="#ffffff" stroke-width="3.6" stroke-linecap="round" d="M32 33 L42 26"/>
</svg>
"""
    ecrire("symbole-silhouette.svg", contenu)


if __name__ == "__main__":
    SORTIE.mkdir(parents=True, exist_ok=True)
    svg_symbole("symbole-clair.svg", TONS["clair"], None, True)
    svg_symbole("symbole-sombre.svg", TONS["sombre"], None, True)
    svg_complet("logo-complet-clair.svg", TONS["clair"], None, True)
    svg_complet("logo-complet-sombre.svg", TONS["sombre"], None, True)
    svg_symbole("logo-noir-symbole.svg", TONS["clair"], "#171717", False)
    svg_complet("logo-noir.svg", TONS["clair"], "#171717", False)
    svg_symbole("logo-blanc-symbole.svg", TONS["sombre"], "#f5f5f4", False)
    svg_complet("logo-blanc.svg", TONS["sombre"], "#f5f5f4", False)
    svg_silhouette()
    print("termine")
