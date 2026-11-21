"""Hachage des secrets : bcrypt pour les mots de passe, HMAC-SHA256 pour les codes et les jetons.

bcrypt est lent par conception : il tourne dans un fil à part pour ne pas bloquer la boucle de l'API.
Un hachage factice sert quand le compte n'existe pas, pour que le temps de réponse ne le trahisse pas.
"""

import hashlib
import hmac
import secrets
from functools import lru_cache

import bcrypt
from anyio import to_thread


def _hacher_sync(mot_de_passe: str, tours: int) -> str:
    return bcrypt.hashpw(mot_de_passe.encode("utf-8"), bcrypt.gensalt(rounds=tours)).decode("ascii")


def _verifier_sync(mot_de_passe: str, hache: str) -> bool:
    try:
        return bcrypt.checkpw(mot_de_passe.encode("utf-8"), hache.encode("ascii"))
    except ValueError:
        return False


@lru_cache(maxsize=4)
def _hache_factice(tours: int) -> str:
    return _hacher_sync(secrets.token_urlsafe(16), tours)


async def hacher_mot_de_passe(mot_de_passe: str, tours: int) -> str:
    """Hache un mot de passe avec bcrypt."""
    return await to_thread.run_sync(_hacher_sync, mot_de_passe, tours)


async def verifier_mot_de_passe(mot_de_passe: str, hache: str | None, tours: int) -> bool:
    """Compare un mot de passe à son hachage ; sans hachage, fait le même travail et rend faux."""
    if hache is None:
        await to_thread.run_sync(_verifier_sync, mot_de_passe, _hache_factice(tours))
        return False
    return await to_thread.run_sync(_verifier_sync, mot_de_passe, hache)


def mot_de_passe_inutilisable(tours: int) -> str:
    """Haché d'un mot de passe aléatoire jeté aussitôt : colonne remplie, compte inaccessible."""
    return _hacher_sync(secrets.token_urlsafe(32), tours)


def hmac_hex(secret: str, valeur: str) -> str:
    """Empreinte HMAC-SHA256 d'une valeur, avec la clé secrète de l'API."""
    return hmac.new(secret.encode("utf-8"), valeur.encode("utf-8"), hashlib.sha256).hexdigest()


def egal_en_temps_constant(a: str, b: str) -> bool:
    """Compare deux chaînes sans fuite de durée."""
    return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))
