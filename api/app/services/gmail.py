"""Envoi des codes par e-mail avec l'API Gmail, jamais SMTP, que Railway bloque.

Le jeton d'accès vient du jeton de rafraîchissement du compte expéditeur, posé dans Railway. Le code n'est
jamais écrit dans un journal ; seul le domaine du destinataire y figure en cas d'échec.
"""

import base64
import logging
import time
from email.message import EmailMessage

import httpx

from app.core.config import Configuration

journal = logging.getLogger("vatel.gmail")
URL_JETON = "https://oauth2.googleapis.com/token"
URL_ENVOI = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
_cache: dict[str, float | str] = {}

SUJETS = {
    "verification_compte": {"fr": "Votre code CANTINE VATEL", "en": "Your CANTINE VATEL code"},
    "reinitialisation_mot_de_passe": {
        "fr": "Réinitialiser votre mot de passe CANTINE VATEL",
        "en": "Reset your CANTINE VATEL password",
    },
    "reconnexion": {"fr": "Votre code de connexion CANTINE VATEL", "en": "Your CANTINE VATEL sign-in code"},
}
CORPS = {
    "fr": "Bonjour,\n\nVotre code : {code}\n\nIl est valable {minutes} minutes. "
    "Si vous n'êtes pas à l'origine de cette demande, ignorez ce message.\n\nCANTINE VATEL",
    "en": "Hello,\n\nYour code: {code}\n\nIt is valid for {minutes} minutes. "
    "If you did not make this request, please ignore this message.\n\nCANTINE VATEL",
}


def configure(config: Configuration) -> bool:
    """Dit si les quatre variables Gmail sont posées."""
    return all(
        (
            config.gmail_client_id,
            config.gmail_client_secret,
            config.gmail_refresh_token,
            config.gmail_expediteur,
        )
    )


def construire(expediteur: str, destinataire: str, usage: str, code: str, minutes: int, langue: str) -> str:
    """Message MIME encodé pour l'API Gmail."""
    message = EmailMessage()
    message["From"] = f"CANTINE VATEL <{expediteur}>"
    message["To"] = destinataire
    message["Subject"] = SUJETS.get(usage, SUJETS["verification_compte"]).get(
        langue, SUJETS["verification_compte"]["fr"]
    )
    message.set_content(CORPS.get(langue, CORPS["fr"]).format(code=code, minutes=minutes))
    return base64.urlsafe_b64encode(message.as_bytes()).decode("ascii")


async def _jeton(client: httpx.AsyncClient, config: Configuration) -> str:
    if float(_cache.get("expire", 0)) > time.time() + 60:
        return str(_cache["jeton"])
    reponse = await client.post(
        URL_JETON,
        data={
            "client_id": config.gmail_client_id,
            "client_secret": config.gmail_client_secret,
            "refresh_token": config.gmail_refresh_token,
            "grant_type": "refresh_token",
        },
        timeout=15,
    )
    reponse.raise_for_status()
    corps = reponse.json()
    _cache.update(jeton=corps["access_token"], expire=time.time() + int(corps.get("expires_in", 3600)))
    return str(_cache["jeton"])


async def envoyer_code(
    client: httpx.AsyncClient,
    config: Configuration,
    destinataire: str,
    usage: str,
    code: str,
    minutes: int,
    langue: str,
) -> bool:
    """Envoie un code par e-mail ; rend faux en cas d'échec, sans jamais lever vers la requête."""
    if not configure(config):
        journal.error("variables Gmail absentes : e-mail non envoyé")
        return False
    try:
        jeton = await _jeton(client, config)
        brut = construire(config.gmail_expediteur or "", destinataire, usage, code, minutes, langue)
        reponse = await client.post(
            URL_ENVOI, json={"raw": brut}, headers={"Authorization": f"Bearer {jeton}"}, timeout=20
        )
        reponse.raise_for_status()
        return True
    except (httpx.HTTPError, KeyError, ValueError) as exc:
        journal.error(
            "envoi Gmail impossible vers @%s : %s", destinataire.rsplit("@", 1)[-1], type(exc).__name__
        )
        return False
