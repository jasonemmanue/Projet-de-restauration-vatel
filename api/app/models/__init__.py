"""Registre des modèles : importer ce paquet charge toutes les tables dans les métadonnées."""

from app.models.administration import JournalAdmin, Parametre
from app.models.argent import LienPaiement, Mouvement, Paiement, PorteMonnaie
from app.models.comptes import (
    CodeVerification,
    ConnexionQr,
    JournalVerification,
    SessionAppareil,
    Tentative,
    Utilisateur,
)
from app.models.menus import Menu, MenuPlat, Plat, Tarif
from app.models.profil import Appareil, Avatar, Signalement
from app.models.retours import Avis, Notification, Suggestion
from app.models.service import FileScan, LienParentEnfant, LigneReservation, LotReservation, Reservation
from app.models.stocks import Ingredient, MouvementStock

__all__ = [
    "Appareil",
    "Avatar",
    "Avis",
    "CodeVerification",
    "ConnexionQr",
    "FileScan",
    "Ingredient",
    "JournalAdmin",
    "JournalVerification",
    "LienPaiement",
    "LienParentEnfant",
    "LigneReservation",
    "LotReservation",
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
    "Suggestion",
    "Tarif",
    "Tentative",
    "Utilisateur",
]
