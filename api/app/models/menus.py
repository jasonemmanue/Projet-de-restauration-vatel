"""Modèles de la carte : plats, tarifs par profil, menus du jour, plats du menu et créneaux de passage."""

import uuid
from datetime import date, datetime, time

from sqlalchemy import Boolean, CheckConstraint, Date, ForeignKey, Index, Integer, Text, Time, func, text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK

TABLEAU_VIDE = text("'{}'::text[]")


class Plat(AvecModification, Base):
    """Plat de la carte, en deux langues. Propriétaire : A4."""

    __tablename__ = "plats"
    __table_args__ = (
        choix("categorie", "entree", "plat", "accompagnement", "dessert", "boisson"),
        CheckConstraint(
            "regimes <@ array['sans_porc', 'sans_gluten', 'vegetarien', 'halal']::text[]", name="regimes"
        ),
        CheckConstraint("calories >= 0", name="calories_positives"),
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
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    supprime_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Tarif(AvecModification, Base):
    """Prix d'un plat pour un profil, sur une période. Propriétaire : A4."""

    __tablename__ = "tarifs"
    __table_args__ = (
        choix("profil", "eleve", "etudiant", "employe", "autre", "visiteur"),
        CheckConstraint("prix_xof >= 0", name="prix_positif"),
        CheckConstraint("actif_au is null or actif_au > actif_du", name="periode_valide"),
        Index("uq_tarifs_plat_profil_debut", "plat_id", "profil", "actif_du", unique=True),
        Index("ix_tarifs_plat_profil", "plat_id", "profil"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    plat_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("plats.id"), nullable=False)
    profil: Mapped[str] = mapped_column(Text, nullable=False)
    prix_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    actif_du: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    actif_au: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Menu(AvecModification, Base):
    """Menu d'un jour de service. Propriétaire : A4."""

    __tablename__ = "menus"
    __table_args__ = (
        choix("etat", "brouillon", "publie", "annule"),
        Index("ix_menus_etat", "etat"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    date_service: Mapped[date] = mapped_column(Date, nullable=False, unique=True)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    heure_limite: Mapped[time] = mapped_column(Time, nullable=False)
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


class Creneau(AvecModification, Base):
    """Créneau de passage d'un jour, avec sa capacité. Propriétaire : A4."""

    __tablename__ = "creneaux"
    __table_args__ = (
        CheckConstraint("fin > debut", name="fin_apres_debut"),
        CheckConstraint("capacite >= 0", name="capacite_positive"),
        Index("uq_creneaux_menu_debut", "menu_id", "debut", unique=True),
        Index("ix_creneaux_menu_id", "menu_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    menu_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("menus.id", ondelete="CASCADE"), nullable=False
    )
    debut: Mapped[time] = mapped_column(Time, nullable=False)
    fin: Mapped[time] = mapped_column(Time, nullable=False)
    capacite: Mapped[int] = mapped_column(Integer, nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
