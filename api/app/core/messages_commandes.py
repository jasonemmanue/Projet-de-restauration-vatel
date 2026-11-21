"""Messages d'erreur des commandes et du porte-monnaie, en français et en anglais."""

MESSAGES_COMMANDES: dict[str, dict[str, str]] = {
    "cle_geste_requise": {
        "fr": "Identifiant de geste manquant. Réessayez.",
        "en": "Missing action identifier. Please try again.",
    },
    "reservation_existante": {
        "fr": "Un des jours est déjà commandé.",
        "en": "One of the days has already been ordered.",
    },
    "menu_non_publie": {
        "fr": "Le menu de ce jour n'est pas encore publié.",
        "en": "This day's menu has not been published yet.",
    },
    "commande_gelee": {
        "fr": "Les commandes de ce jour sont gelées.",
        "en": "Orders for this day are frozen.",
    },
    "aucun_service": {
        "fr": "Choisissez au moins un plat pour chaque jour.",
        "en": "Choose at least one dish for each day.",
    },
    "plat_hors_menu": {
        "fr": "Un des plats n'est pas au menu de ce jour.",
        "en": "One of the dishes is not on this day's menu.",
    },
    "plat_epuise": {
        "fr": "Un des plats n'a plus assez de portions.",
        "en": "One of the dishes has run out of portions.",
    },
    "tarif_absent": {
        "fr": "Aucun prix n'est encore fixé pour votre profil.",
        "en": "No price has been set for your profile yet.",
    },
    "solde_insuffisant": {
        "fr": "Le solde ne couvre pas cette commande.",
        "en": "Your balance does not cover this order.",
    },
    "porte_monnaie_gele": {
        "fr": "Ce porte-monnaie est bloqué.",
        "en": "This wallet is locked.",
    },
    "deja_servie": {
        "fr": "Ce repas a déjà été servi.",
        "en": "This meal has already been served.",
    },
}
