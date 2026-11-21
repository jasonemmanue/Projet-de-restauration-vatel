"""Bloc « sante » : santé avec commit, en-têtes de sécurité, CORS strict et format d'erreur unique."""

from recette.executeur import Recette

ORIGINE_INCONNUE = "https://origine-inconnue.recette.invalid"
ENTETES_ATTENDUS = {
    "strict-transport-security": None,
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": None,
}


def lancer(recette: Recette) -> None:
    """Lance les contrôles du bloc santé."""
    client = recette.client
    sante = client.get("/health")
    recette.verifier("GET /health répond 200", sante.status_code == 200, f"statut {sante.status_code}")
    corps = sante.json() if sante.headers.get("content-type", "").startswith("application/json") else {}
    commit = corps.get("commit", "")
    recette.verifier("/health donne le commit déployé", bool(commit), "commit absent")
    recette.verifier("/health voit la base", corps.get("base") == "ok", f"base {corps.get('base')}")
    recette.verifier(
        "X-Version-Commit égal au commit",
        sante.headers.get("x-version-commit") == commit,
        "en-tête absent ou différent",
    )
    for nom, valeur in ENTETES_ATTENDUS.items():
        recu = sante.headers.get(nom)
        recette.verifier(f"en-tête {nom} présent", recu is not None and (valeur is None or recu == valeur))

    contrat = client.get("/api/v1/sante")
    recette.verifier(
        "GET /api/v1/sante répond 200", contrat.status_code == 200, f"statut {contrat.status_code}"
    )

    pre = client.options(
        "/health", headers={"Origin": ORIGINE_INCONNUE, "Access-Control-Request-Method": "GET"}
    )
    recette.verifier(
        "origine inconnue refusée par le CORS",
        pre.status_code != 200 and "access-control-allow-origin" not in pre.headers,
        f"statut {pre.status_code}",
    )
    simple = client.get("/health", headers={"Origin": ORIGINE_INCONNUE})
    recette.verifier(
        "aucune autorisation CORS donnée à l'origine inconnue",
        "access-control-allow-origin" not in simple.headers,
    )

    inconnue = client.get("/api/v1/route-inconnue-de-recette")
    recette.verifier("route inconnue en 404", inconnue.status_code == 404, f"statut {inconnue.status_code}")
    try:
        erreur = inconnue.json()
    except ValueError:
        erreur = {}
    recette.verifier(
        "erreur au format {code, message}",
        isinstance(erreur, dict)
        and set(erreur) == {"code", "message"}
        and erreur.get("code") == "introuvable",
        "format différent",
    )
