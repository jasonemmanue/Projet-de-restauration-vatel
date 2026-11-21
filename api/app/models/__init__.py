"""Registre des modèles : importer ce paquet charge toutes les tables dans les métadonnées."""

from app.models.administration import JournalAdmin, Parametre
from app.models.argent import LienPaiement, Mouvement, Paiement, PorteMonnaie
from app.models.comptes import (
    CodeVerification,
    ConnexionQr,
    JournalVerification,
    SessionAppareil,
    Utilisateur,
)
from app.models.menus import Creneau, Menu, MenuPlat, Plat, Tarif
from app.models.profil import Appareil, Avatar, Signalement
from app.models.retours import Avis, Notification
from app.models.service import FileScan, LienParentEnfant, Reservation
from app.models.stocks import Ingredient, MouvementStock

__all__ = [
    "Appareil",
    "Avatar",
    "Avis",
    "CodeVerification",
    "ConnexionQr",
    "Creneau",
    "FileScan",
    "Ingredient",
    "JournalAdmin",
    "JournalVerification",
    "LienPaiement",
    "LienParentEnfant",
    "Menu",
    "MenuPlat",
    "Mouvement",
    "MouvementStock",
    "Notification",
    "Paiement",
    "Parametre",
    "Plat",
    "PorteMonnaie",
    "Reservation",
    "SessionAppareil",
    "Signalement",
    "Tarif",
    "Utilisateur",
]
