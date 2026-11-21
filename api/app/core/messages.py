"""Messages d'erreur de l'API en français et en anglais.

Ils sont volontairement génériques : aucun ne révèle l'existence d'un compte ni un détail technique.
Chaque bloc ajoute ici les codes qu'il crée, toujours dans les deux langues.
"""

from app.core.messages_commandes import MESSAGES_COMMANDES
from app.core.messages_comptes import MESSAGES_COMPTES
from app.core.messages_menus import MESSAGES_MENUS

LANGUES = ("fr", "en")
LANGUE_DEFAUT = "fr"

MESSAGES: dict[str, dict[str, str]] = {
    "validation": {
        "fr": "Certaines informations envoyées sont invalides.",
        "en": "Some of the information sent is invalid.",
    },
    "non_authentifie": {
        "fr": "Connexion requise.",
        "en": "Sign-in required.",
    },
    "acces_refuse": {
        "fr": "Accès refusé.",
        "en": "Access denied.",
    },
    "introuvable": {
        "fr": "Ressource introuvable.",
        "en": "Resource not found.",
    },
    "methode_non_autorisee": {
        "fr": "Cette action n'est pas permise sur cette adresse.",
        "en": "This action is not allowed on this address.",
    },
    "conflit": {
        "fr": "Cette action entre en conflit avec l'état actuel.",
        "en": "This action conflicts with the current state.",
    },
    "requete_trop_lourde": {
        "fr": "La requête est trop volumineuse.",
        "en": "The request is too large.",
    },
    "trop_de_requetes": {
        "fr": "Trop de requêtes. Réessayez dans un instant.",
        "en": "Too many requests. Please try again shortly.",
    },
    "origine_refusee": {
        "fr": "Origine non autorisée.",
        "en": "Origin not allowed.",
    },
    "service_indisponible": {
        "fr": "Le service est momentanément indisponible.",
        "en": "The service is temporarily unavailable.",
    },
    "erreur_serveur": {
        "fr": "Une erreur inattendue est survenue.",
        "en": "An unexpected error occurred.",
    },
}

MESSAGES.update(MESSAGES_COMPTES)
MESSAGES.update(MESSAGES_MENUS)
MESSAGES.update(MESSAGES_COMMANDES)

# Code générique associé à un statut HTTP quand aucune erreur métier n'est levée.
CODE_PAR_STATUT: dict[int, str] = {
    400: "validation",
    401: "non_authentifie",
    403: "acces_refuse",
    404: "introuvable",
    405: "methode_non_autorisee",
    409: "conflit",
    413: "requete_trop_lourde",
    422: "validation",
    429: "trop_de_requetes",
    503: "service_indisponible",
}


def choisir_langue(entete_accept_language: str | None) -> str:
    """Choisit fr ou en d'après l'en-tête Accept-Language, fr par défaut."""
    if not entete_accept_language:
        return LANGUE_DEFAUT
    for morceau in entete_accept_language.split(","):
        code = morceau.split(";")[0].strip().lower()[:2]
        if code in LANGUES:
            return code
    return LANGUE_DEFAUT


def message_pour(code: str, langue: str) -> str:
    """Rend le message d'un code dans la langue voulue, ou le message générique s'il est inconnu."""
    traductions = MESSAGES.get(code) or MESSAGES["erreur_serveur"]
    return traductions.get(langue) or traductions[LANGUE_DEFAUT]


def code_pour_statut(statut: int) -> str:
    """Rend le code générique d'un statut HTTP."""
    if statut >= 500:
        return "erreur_serveur"
    return CODE_PAR_STATUT.get(statut, "validation")
