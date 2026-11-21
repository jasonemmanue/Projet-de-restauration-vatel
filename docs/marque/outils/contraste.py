# Role du fichier : verifier le contraste WCAG de chaque paire texte sur fond de la charte.
# Les couleurs sont recopiees de docs/maquette/src/shared/styles/tokens.css, sans rien inventer.
# Lancer : python docs/marque/outils/contraste.py

CLAIR = {
    "texte": "#0f172a",
    "texte secondaire": "#64748b",
    "accent": "#2f6bff",
    "accent doux": "#e8efff",
    "sur accent": "#ffffff",
    "fond": "#f4f6fb",
    "surface": "#ffffff",
    "muet": "#eef1f8",
    "filet": "#e2e8f0",
    "succes": "#0d9488",
    "danger": "#ef4444",
    "alerte": "#f59e0b",
    "contraste": "#0f172a",
    "sur contraste": "#ffffff",
    "sur contraste attenue": "#93c5fd",
    "champ": "#ffffff",
    "texte de champ": "#0f172a",
}

SOMBRE = {
    "texte": "#f8fafc",
    "texte secondaire": "#94a3b8",
    "accent": "#60a5fa",
    "accent doux": "#1e293b",
    "sur accent": "#0f172a",
    "fond": "#0b1220",
    "surface": "#111827",
    "muet": "#1f2937",
    "filet": "#334155",
    "succes": "#0d9488",
    "danger": "#ef4444",
    "alerte": "#f59e0b",
    "contraste": "#020617",
    "sur contraste": "#f8fafc",
    "sur contraste attenue": "#93c5fd",
    "champ": "#1e293b",
    "texte de champ": "#f8fafc",
}

# Paires (texte, fond) a controler, identiques dans les deux modes.
PAIRES = [
    ("texte", "fond"),
    ("texte", "surface"),
    ("texte", "muet"),
    ("texte", "accent doux"),
    ("texte secondaire", "fond"),
    ("texte secondaire", "surface"),
    ("accent", "fond"),
    ("accent", "surface"),
    ("sur accent", "accent"),
    ("sur contraste", "contraste"),
    ("sur contraste attenue", "contraste"),
    ("texte de champ", "champ"),
    ("succes", "surface"),
    ("danger", "surface"),
    ("alerte", "surface"),
    ("filet", "surface"),
]


def canal(valeur: float) -> float:
    """Rend la luminance lineaire d un canal, selon la formule WCAG 2.1."""
    valeur = valeur / 255
    return valeur / 12.92 if valeur <= 0.04045 else ((valeur + 0.055) / 1.055) ** 2.4


def luminance(hexa: str) -> float:
    """Rend la luminance relative d une couleur ecrite en hexadecimal."""
    hexa = hexa.lstrip("#")
    r, v, b = (int(hexa[i : i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * canal(r) + 0.7152 * canal(v) + 0.0722 * canal(b)


def rapport(avant: str, arriere: str) -> float:
    """Rend le rapport de contraste entre deux couleurs, de 1 a 21."""
    a, b = luminance(avant), luminance(arriere)
    clair, sombre = max(a, b), min(a, b)
    return (clair + 0.05) / (sombre + 0.05)


def controler(nom_mode: str, palette: dict) -> list:
    """Rend la liste des paires du mode avec leur rapport et leur verdict."""
    lignes = []
    for texte, fond in PAIRES:
        valeur = rapport(palette[texte], palette[fond])
        seuil = 3.0 if texte == "filet" else 4.5
        lignes.append((nom_mode, texte, fond, palette[texte], palette[fond], valeur, valeur >= seuil, seuil))
    return lignes


if __name__ == "__main__":
    resultats = controler("clair", CLAIR) + controler("sombre", SOMBRE)
    print(f"{'mode':7} {'texte':22} {'fond':14} {'rapport':>8}  verdict")
    for mode, texte, fond, ct, cf, valeur, ok, seuil in resultats:
        verdict = "ok" if ok else f"SOUS {seuil}"
        print(f"{mode:7} {texte:22} {fond:14} {valeur:8.2f}  {verdict}")
    echecs = [r for r in resultats if not r[6]]
    print(f"\n{len(resultats) - len(echecs)} paires conformes, {len(echecs)} a signaler.")
