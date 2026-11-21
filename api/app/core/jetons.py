"""Jetons de session : jeton d'accès JWT court, jeton de rafraîchissement aléatoire rangé haché.

Le jeton d'accès porte l'utilisateur et la session ; chaque requête relit la session en base, si bien
qu'une déconnexion ou une réinitialisation coupe l'accès sans attendre l'expiration.
"""

import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt

ALGORITHME = "HS256"
TYPE_ACCES = "acces"


@dataclass(frozen=True)
class ContenuJeton:
    """Ce que porte un jeton d'accès valide."""

    utilisateur_id: uuid.UUID
    session_id: uuid.UUID


class JetonInvalideError(ValueError):
    """Le jeton est absent, mal formé, mal signé ou expiré."""


def creer_jeton_acces(secret: str, utilisateur_id: uuid.UUID, session_id: uuid.UUID, duree: timedelta) -> str:
    """Signe un jeton d'accès pour une session."""
    maintenant = datetime.now(UTC)
    contenu = {
        "sub": str(utilisateur_id),
        "sid": str(session_id),
        "typ": TYPE_ACCES,
        "iat": maintenant,
        "exp": maintenant + duree,
    }
    return jwt.encode(contenu, secret, algorithm=ALGORITHME)


def lire_jeton_acces(secret: str, jeton: str) -> ContenuJeton:
    """Vérifie la signature et l'expiration d'un jeton d'accès et rend son contenu."""
    try:
        contenu = jwt.decode(
            jeton, secret, algorithms=[ALGORITHME], options={"require": ["exp", "sub", "sid"]}
        )
        if contenu.get("typ") != TYPE_ACCES:
            raise JetonInvalideError("type de jeton inattendu")
        return ContenuJeton(uuid.UUID(contenu["sub"]), uuid.UUID(contenu["sid"]))
    except (jwt.PyJWTError, ValueError, KeyError) as exc:
        raise JetonInvalideError("jeton refusé") from exc


def nouveau_jeton_rafraichissement() -> str:
    """Tire un jeton de rafraîchissement opaque ; seul son haché est rangé en base."""
    return secrets.token_urlsafe(48)
