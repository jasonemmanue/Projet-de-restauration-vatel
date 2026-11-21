"""Envoi des notifications push par Firebase Cloud Messaging (API HTTP v1), avec le compte de service.

Le jeton d'accès Google est obtenu en signant une assertion avec la clé du compte de service, puis gardé
jusqu'à peu avant son expiration. Chaque message porte ses blocs android, apns et webpush. FCM_ACTIF à faux
coupe tout envoi sans toucher au code.
"""

import base64
import json
import logging
import time
from dataclasses import dataclass
from typing import Any

import httpx
import jwt

journal = logging.getLogger("vatel.fcm")
PORTEE = "https://www.googleapis.com/auth/firebase.messaging"
URL_JETON = "https://oauth2.googleapis.com/token"
_cache: dict[str, Any] = {}


class JetonInvalideError(RuntimeError):
    """FCM ne connaît plus ce jeton d'appareil : l'appareil doit être oublié."""


@dataclass(frozen=True)
class CompteService:
    """Ce qu'il faut du compte de service pour signer l'assertion."""

    email: str
    cle_privee: str
    projet: str


def lire_compte(contenu_base64: str, projet: str | None) -> CompteService:
    """Décode le compte de service posé en base64 dans Railway."""
    donnees = json.loads(base64.b64decode(contenu_base64))
    return CompteService(donnees["client_email"], donnees["private_key"], projet or donnees["project_id"])


async def _jeton_google(client: httpx.AsyncClient, compte: CompteService) -> str:
    if _cache.get("expire", 0) > time.time() + 60:
        return _cache["jeton"]
    maintenant = int(time.time())
    assertion = jwt.encode(
        {"iss": compte.email, "scope": PORTEE, "aud": URL_JETON, "iat": maintenant, "exp": maintenant + 3600},
        compte.cle_privee,
        algorithm="RS256",
    )
    reponse = await client.post(
        URL_JETON,
        data={"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion},
        timeout=15,
    )
    reponse.raise_for_status()
    corps = reponse.json()
    _cache.update(jeton=corps["access_token"], expire=maintenant + int(corps.get("expires_in", 3600)))
    return _cache["jeton"]


def message(jeton_appareil: str, titre: str, corps: str, donnees: dict[str, str]) -> dict[str, Any]:
    """Message FCM v1 avec ses blocs par plateforme ; les données sont des chaînes, comme FCM l'exige."""
    return {
        "message": {
            "token": jeton_appareil,
            "notification": {"title": titre, "body": corps},
            "data": {k: str(v) for k, v in donnees.items()},
            "android": {
                "priority": "high",
                "notification": {"channel_id": "cantine_vatel", "sound": "default"},
            },
            "apns": {"payload": {"aps": {"sound": "default"}}},
            "webpush": {"notification": {"icon": "/icons/Icon-192.png"}},
        }
    }


async def envoyer(
    client: httpx.AsyncClient,
    compte: CompteService,
    jeton_appareil: str,
    titre: str,
    corps: str,
    donnees: dict,
) -> None:
    """Envoie un message à un appareil ; lève JetonInvalideError si FCM ne le connaît plus."""
    jeton = await _jeton_google(client, compte)
    reponse = await client.post(
        f"https://fcm.googleapis.com/v1/projects/{compte.projet}/messages:send",
        json=message(jeton_appareil, titre, corps, donnees),
        headers={"Authorization": f"Bearer {jeton}"},
        timeout=15,
    )
    if reponse.status_code == 404 or (reponse.status_code == 400 and "UNREGISTERED" in reponse.text):
        raise JetonInvalideError(jeton_appareil[:12])
    if reponse.status_code >= 300:
        raise httpx.HTTPStatusError("FCM a refusé", request=reponse.request, response=reponse)
