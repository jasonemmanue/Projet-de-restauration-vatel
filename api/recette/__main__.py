"""Point d'entrée : python -m recette --url https://<URL_API> --bloc <bloc> [--commit <sha>].

Lit d'abord /health et affiche le commit déployé ; avec --commit, s'arrête si ce n'est pas le bon. Les
comptes créés sont supprimés à la fin, même après un échec. Aucun SMS ni paiement réel n'est déclenché.
"""

import argparse
import sys

import httpx

from recette.blocs import BLOCS
from recette.executeur import CROIX, Recette, creer_client, preparer_console


def _arguments(argv: list[str] | None) -> argparse.Namespace:
    analyseur = argparse.ArgumentParser(prog="python -m recette", description="Recette en ligne de l'API")
    analyseur.add_argument("--url", required=True, help="URL publique de l'API, en https")
    analyseur.add_argument("--bloc", required=True, choices=[*BLOCS, "tous"], help="bloc à lancer")
    analyseur.add_argument("--commit", help="commit attendu ; la recette s'arrête s'il diffère")
    return analyseur.parse_args(argv)


def _commit_deploye(client: httpx.Client) -> str | None:
    try:
        reponse = client.get("/health")
        return str(reponse.json().get("commit") or "") or None
    except (httpx.HTTPError, ValueError):
        return None


def principal(argv: list[str] | None = None) -> int:
    """Lance la recette demandée et rend le code de sortie."""
    preparer_console()
    args = _arguments(argv)
    url = args.url.rstrip("/")
    with creer_client(url) as client:
        commit = _commit_deploye(client)
        print(f"API : {url}")
        print(f"Commit déployé : {commit or 'inconnu'}")
        if args.commit and (not commit or not args.commit.startswith(commit)):
            print(f"{CROIX} commit attendu {args.commit[:7]}, la recette s'arrête")
            return 1
        recette = Recette(url=url, client=client)
        noms = list(BLOCS) if args.bloc == "tous" else [args.bloc]
        try:
            for nom in noms:
                print(f"\nBloc {nom}")
                try:
                    BLOCS[nom](recette)
                except Exception as exc:  # un bloc qui plante compte comme un échec, les autres continuent
                    recette.verifier(f"bloc {nom} exécuté jusqu'au bout", False, type(exc).__name__)
        finally:
            recette.nettoyer()
        return recette.total()


if __name__ == "__main__":
    sys.exit(principal())
