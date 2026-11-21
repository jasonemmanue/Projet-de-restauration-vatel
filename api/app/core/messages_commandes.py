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
    "deja_lie": {
        "fr": "Ce compte est déjà lié au vôtre.",
        "en": "This account is already linked to yours.",
    },
    "role_invalide": {
        "fr": "Ce compte n'a pas de code de liaison.",
        "en": "This account has no link code.",
    },
    "beneficiaire_interdit": {
        "fr": "Vous ne pouvez pas recharger ce compte.",
        "en": "You cannot top up this account.",
    },
    "montant_invalide": {
        "fr": "Ce montant n'est pas accepté.",
        "en": "This amount is not accepted.",
    },
    "mode_paiement_invalide": {
        "fr": "Le paiement n'est pas ouvert dans ce mode.",
        "en": "Payment is not open in this mode.",
    },
    "cles_absentes": {
        "fr": "Le paiement n'est pas encore configuré.",
        "en": "Payment is not configured yet.",
    },
    "paiement_indisponible": {
        "fr": "Le service de paiement ne répond pas. Réessayez dans un instant.",
        "en": "The payment service is not responding. Please try again shortly.",
    },
    "signature_invalide": {
        "fr": "Signature refusée.",
        "en": "Signature rejected.",
    },
    "deja_paye": {
        "fr": "Ce lien a déjà été payé.",
        "en": "This link has already been paid.",
    },
    "lien_expire": {
        "fr": "Ce lien de paiement n'est plus valable.",
        "en": "This payment link is no longer valid.",
    },
    "operateur_inconnu": {
        "fr": "Opérateur non pris en charge.",
        "en": "Unsupported operator.",
    },
    "cible_vide": {
        "fr": "Choisissez au moins un destinataire.",
        "en": "Choose at least one recipient.",
    },
}
