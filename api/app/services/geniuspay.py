"""Client GeniusPay : initiation d'un paiement et vérification de la signature des webhooks.

La clé secrète ne quitte jamais le serveur. Les montants et les frais reçus sont convertis en entiers XOF ;
GeniusPay les envoie parfois avec des décimales (10000.00).
"""

import hashlib
import hmac
import time
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

import httpx

DELAI_HORODATAGE_SECONDES = 300
ENVIRONNEMENTS = {"test": "sandbox", "reel": "live"}
# Opérateur du contrat vers le moyen de paiement GeniusPay.
MOYENS = {
    "orange": {"payment_method": "orange_money"},
    "mtn": {"payment_method": "mtn_money"},
    "wave": {"payment_method": "wave"},
    "moov": {"gateway": "moov_money"},
}


class GeniusPayError(RuntimeError):
    """GeniusPay n'a pas accepté la demande ou n'a pas répondu."""


@dataclass(frozen=True)
class PaiementInitie:
    """Réponse de GeniusPay à l'initiation d'un paiement."""

    reference: str
    url_paiement: str | None
    frais_xof: int
    net_xof: int


def en_xof(valeur: object) -> int:
    """Montant GeniusPay en entier XOF, sans passer par un flottant."""
    return int(Decimal(str(valeur or 0)).to_integral_value())


def signature_valide(
    secret: str, horodatage: str, corps: bytes, signature: str, maintenant: float | None = None
) -> bool:
    """Vérifie HMAC-SHA256(horodatage + "." + corps) et refuse un envoi vieux de plus de 5 minutes."""
    if not secret or not horodatage or not signature or not horodatage.isdigit():
        return False
    instant = time.time() if maintenant is None else maintenant
    if abs(instant - int(horodatage)) > DELAI_HORODATAGE_SECONDES:
        return False
    attendue = hmac.new(secret.encode(), horodatage.encode() + b"." + corps, hashlib.sha256).hexdigest()
    return hmac.compare_digest(attendue, signature.strip().lower())


async def initier(
    client: httpx.AsyncClient,
    url_base: str,
    cle_publique: str,
    cle_secrete: str,
    montant: int,
    operateur: str,
    telephone: str,
    description: str,
    retour: str,
    metadata: dict[str, Any],
) -> PaiementInitie:
    """Demande un paiement à GeniusPay et rend sa référence, son adresse de paiement et ses frais."""
    corps = {
        "amount": montant,
        "currency": "XOF",
        "description": description[:500],
        "customer": {"phone": telephone, "country": "CI"},
        "success_url": retour,
        "error_url": retour,
        "metadata": metadata,
        **MOYENS[operateur],
    }
    entetes = {"X-API-Key": cle_publique, "X-API-Secret": cle_secrete, "Content-Type": "application/json"}
    try:
        reponse = await client.post(
            f"{url_base.rstrip('/')}/payments", json=corps, headers=entetes, timeout=20
        )
    except httpx.HTTPError as exc:
        raise GeniusPayError("GeniusPay injoignable") from exc
    if reponse.status_code >= 300:
        raise GeniusPayError(f"GeniusPay a répondu {reponse.status_code}")
    donnees = (reponse.json() or {}).get("data") or {}
    if not donnees.get("reference"):
        raise GeniusPayError("réponse GeniusPay sans référence")
    return PaiementInitie(
        reference=str(donnees["reference"]),
        url_paiement=donnees.get("payment_url") or donnees.get("checkout_url"),
        frais_xof=en_xof(donnees.get("fees")),
        net_xof=en_xof(donnees.get("net_amount")),
    )
