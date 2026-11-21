"""Modèles de la carte : plats en trois services, prix du menu par profil, menus du jour et leurs plats.

Il n'y a pas de créneau de passage : un convive vient manger quand il veut le jour commandé.
"""

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK

TABLEAU_VIDE = text("'{}'::text[]")
# Les trois services d'un repas, dans l'ordre du repas.
SERVICES = ("entree", "resistance", "sortie")
# Liste fermée des allergènes, la même pour les plats et pour les allergies des comptes.
ALLERGENES = (
    "arachide",
    "poisson",
    "crustaces",
    "gluten",
    "lait",
    "oeuf",
    "soja",
    "sesame",
    "fruits_a_coque",
    "celeri",
    "moutarde",
)
REGIMES = ("sans_porc", "sans_gluten", "vegetarien", "halal")
TYPES_PHOTO = ("image/jpeg", "image/png", "image/webp")


def dans_liste(colonne: str, valeurs: tuple[str, ...], nom: str) -> CheckConstraint:
    """Contrainte qui limite un tableau de textes à une liste fermée."""
    liste = ", ".join(f"'{v}'" for v in valeurs)
    return CheckConstraint(f"{colonne} <@ array[{liste}]::text[]", name=nom)


class Plat(AvecModification, Base):
    """Plat de la carte, en deux langues, rangé dans un des trois services. Propriétaire : A4."""

    __tablename__ = "plats"
    __table_args__ = (
        choix("categorie", *SERVICES),
        dans_liste("regimes", REGIMES, "regimes"),
        dans_liste("allergenes", ALLERGENES, "allergenes"),
        choix("photo_type", *TYPES_PHOTO),
        CheckConstraint("calories >= 0", name="calories_positives"),
        CheckConstraint("prix_supplement_xof >= 0", name="supplement_positif"),
        Index("ix_plats_categorie", "categorie"),
        Index("ix_plats_actif", "actif"),
        Index(
            "uq_plats_nom_fr_minuscule",
            func.lower(text("nom_fr")),
            unique=True,
            postgresql_where=text("supprime_le is null"),
        ),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    nom_fr: Mapped[str] = mapped_column(Text, nullable=False)
    nom_en: Mapped[str] = mapped_column(Text, nullable=False)
    description_fr: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    description_en: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    categorie: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text)
    allergenes: Mapped[list[str]] = mapped_column(ARRAY(Text), nullable=False, server_default=TABLEAU_VIDE)
    regimes: Mapped[list[str]] = mapped_column(ARRAY(Text), nullable=False, server_default=TABLEAU_VIDE)
    calories: Mapped[int | None] = mapped_column(Integer)
    prix_supplement_xof: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    # Photo rangée en base : colonne lourde, chargée seulement quand on sert l'image.
    photo: Mapped[bytes | None] = mapped_column(LargeBinary, deferred=True)
    photo_type: Mapped[str | None] = mapped_column(Text)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    supprime_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Tarif(AvecModification, Base):
    """Prix du menu du jour pour un profil, sur une période ; propre à un menu si menu_id est renseigné.

    Le prix ne dépend pas des plats choisis : le menu se vend comme un tout. Propriétaire : A4.
    """

    __tablename__ = "tarifs"
    __table_args__ = (
        choix("profil", "eleve", "etudiant", "employe", "autre", "visiteur"),
        CheckConstraint("prix_xof >= 0", name="prix_positif"),
        CheckConstraint("actif_au is null or actif_au > actif_du", name="periode_valide"),
        # NULLS NOT DISTINCT : un tarif général (sans menu) n'existe qu'une fois par profil et par date.
        Index(
            "uq_tarifs_profil_menu_debut",
            "profil",
            "menu_id",
            "actif_du",
            unique=True,
            postgresql_nulls_not_distinct=True,
        ),
        Index("ix_tarifs_profil_debut", "profil", text("actif_du desc")),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    profil: Mapped[str] = mapped_column(Text, nullable=False)
    menu_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("menus.id"))
    prix_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    actif_du: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    actif_au: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Menu(AvecModification, Base):
    """Menu d'un jour de service ; les commandes se gèlent selon les réglages de gel. Propriétaire : A4."""

    __tablename__ = "menus"
    __table_args__ = (
        choix("etat", "brouillon", "publie", "annule"),
        Index("ix_menus_etat", "etat"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    date_service: Mapped[date] = mapped_column(Date, nullable=False, unique=True)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    publie_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    publie_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))


class MenuPlat(AvecModification, Base):
    """Plat proposé dans un menu, avec la quantité prévue. Propriétaire : A4."""

    __tablename__ = "menus_plats"
    __table_args__ = (
        CheckConstraint("quantite_prevue >= 0", name="quantite_positive"),
        Index("uq_menus_plats_menu_plat", "menu_id", "plat_id", unique=True),
        Index("ix_menus_plats_menu_id", "menu_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    menu_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("menus.id", ondelete="CASCADE"), nullable=False
    )
    plat_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("plats.id"), nullable=False)
    quantite_prevue: Mapped[int] = mapped_column(Integer, nullable=False)
    ordre: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
