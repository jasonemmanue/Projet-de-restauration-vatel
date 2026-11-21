"""Messages d'erreur du catalogue et des menus, en français et en anglais."""

MESSAGES_MENUS: dict[str, dict[str, str]] = {
    "menu_existant": {
        "fr": "Ce jour a déjà un menu.",
        "en": "This day already has a menu.",
    },
    "menu_publie": {
        "fr": "Ce menu a déjà des commandes : il ne se modifie plus ici.",
        "en": "This menu already has orders and can no longer be changed here.",
    },
    "menu_annule": {
        "fr": "Ce menu est annulé.",
        "en": "This menu has been cancelled.",
    },
    "menu_vide": {
        "fr": "Un menu doit proposer au moins un plat pour être publié.",
        "en": "A menu must offer at least one dish to be published.",
    },
    "plat_inconnu": {
        "fr": "Un des plats est inconnu ou retiré du catalogue.",
        "en": "One of the dishes is unknown or no longer in the catalogue.",
    },
    "chevauchement": {
        "fr": "Un tarif existe déjà pour ce profil à cette date.",
        "en": "A price already exists for this profile on this date.",
    },
    "fichier_invalide": {
        "fr": "La photo doit être une image JPEG, PNG ou WebP.",
        "en": "The photo must be a JPEG, PNG or WebP image.",
    },
    "trop_lourd": {
        "fr": "Le fichier est trop lourd.",
        "en": "The file is too large.",
    },
}
