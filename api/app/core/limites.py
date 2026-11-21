"""Limites de débit par adresse IP, en mémoire : une seule instance d'API, donc pas de Redis."""

from slowapi import Limiter
from starlette.requests import Request

from app.core.securite import adresse_reelle


def cle_adresse(request: Request) -> str:
    """Clé de limitation : l'adresse réelle du client, lue derrière le relais."""
    return adresse_reelle(request, request.app.state.config.proxies_de_confiance)


def creer_limiteur(limite_defaut: str) -> Limiter:
    """Crée le limiteur de l'application, avec la limite par défaut appliquée à toutes les routes."""
    return Limiter(key_func=cle_adresse, default_limits=[limite_defaut], storage_uri="memory://")
