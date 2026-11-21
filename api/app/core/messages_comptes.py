"""Messages d'erreur des comptes, de la connexion et de la vérification, en français et en anglais.

Aucun ne dit si un compte existe, sauf `compte_existe` à l'inscription, exigé par le parcours.
"""

MESSAGES_COMPTES: dict[str, dict[str, str]] = {
    "compte_existe": {
        "fr": "Un compte existe déjà avec cet identifiant.",
        "en": "An account already exists with this identifier.",
    },
    "identifiant_invalide": {
        "fr": "Numéro ou adresse e-mail invalide.",
        "en": "Invalid phone number or e-mail address.",
    },
    "mot_de_passe_faible": {
        "fr": "Le mot de passe doit faire 8 à 64 caractères, avec une lettre et un chiffre, sans reprendre "
        "l'identifiant.",
        "en": "The password must be 8 to 64 characters long, with a letter and a digit, and must not contain "
        "the identifier.",
    },
    "conditions_requises": {
        "fr": "Les conditions d'utilisation doivent être acceptées.",
        "en": "The terms of use must be accepted.",
    },
    "identifiants_invalides": {
        "fr": "Identifiant ou mot de passe incorrect.",
        "en": "Incorrect identifier or password.",
    },
    "trop_de_tentatives": {
        "fr": "Trop de tentatives. Réessayez dans quelques minutes.",
        "en": "Too many attempts. Please try again in a few minutes.",
    },
    "compte_desactive": {
        "fr": "Ce compte est désactivé.",
        "en": "This account is disabled.",
    },
    "a_verifier": {
        "fr": "Vérifiez d'abord votre numéro ou votre adresse e-mail.",
        "en": "Please verify your phone number or e-mail address first.",
    },
    "jeton_invalide": {
        "fr": "Session invalide. Reconnectez-vous.",
        "en": "Invalid session. Please sign in again.",
    },
    "session_revoquee": {
        "fr": "Cette session a été fermée. Reconnectez-vous.",
        "en": "This session has been closed. Please sign in again.",
    },
    "code_invalide": {
        "fr": "Code incorrect.",
        "en": "Incorrect code.",
    },
    "code_expire": {
        "fr": "Ce code a expiré. Demandez-en un nouveau.",
        "en": "This code has expired. Please request a new one.",
    },
    "trop_essais": {
        "fr": "Trop de codes incorrects. Réessayez dans quelques minutes.",
        "en": "Too many incorrect codes. Please try again in a few minutes.",
    },
    "envoi_impossible": {
        "fr": "L'envoi du code n'est pas encore disponible par ce canal.",
        "en": "Sending the code is not yet available on this channel.",
    },
    "mot_de_passe_actions_invalide": {
        "fr": "Mot de passe des actions incorrect.",
        "en": "Incorrect actions password.",
    },
    "suppression_interdite": {
        "fr": "Ce compte ne peut pas être supprimé ici.",
        "en": "This account cannot be deleted here.",
    },
}
