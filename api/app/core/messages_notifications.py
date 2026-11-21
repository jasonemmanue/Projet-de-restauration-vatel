"""Textes des notifications, en français et en anglais, choisis selon la langue du destinataire.

Les valeurs entre accolades sont remplies au moment de l'envoi ; elles ne contiennent jamais de secret.
"""

NOTIFICATIONS: dict[str, dict[str, tuple[str, str]]] = {
    "paiement_recu": {
        "fr": ("Recharge reçue", "{montant} XOF ont été ajoutés au porte-monnaie."),
        "en": ("Top-up received", "{montant} XOF were added to the wallet."),
    },
    "repas_servi": {
        "fr": ("Repas servi", "Bon appétit ! Votre repas du {date} a été servi."),
        "en": ("Meal served", "Enjoy! Your meal for {date} has been served."),
    },
    "menu_publie": {
        "fr": ("Menu publié", "Le menu du {date} est en ligne. Commandez avant le gel."),
        "en": ("Menu published", "The menu for {date} is online. Order before it freezes."),
    },
    "solde_bas": {
        "fr": ("Solde bas", "Le solde de {prenom} est de {solde} XOF."),
        "en": ("Low balance", "{prenom}'s balance is {solde} XOF."),
    },
    "message_admin": {
        "fr": ("{titre}", "{corps}"),
        "en": ("{titre}", "{corps}"),
    },
}
