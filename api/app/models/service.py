"""Modèles du service : liens parent-enfant, réservations avec ticket QR, file des scans hors ligne."""

import uuid
from datetime import date, datetime

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Integer, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK


class LienParentEnfant(AvecModification, Base):
    """Liaison d'un parent à un enfant par code. Propriétaire : A5."""

    __tablename__ = "liens_parent_enfant"
    __table_args__ = (
        choix("etat", "en_attente", "actif", "revoque"),
        CheckConstraint("char_length(code_liaison) = 8", name="code_huit_caracteres"),
        CheckConstraint("parent_id <> enfant_id", name="parent_different"),
        Index("uq_liens_parent_enfant_parent_enfant", "parent_id", "enfant_id", unique=True),
        Index("ix_liens_parent_enfant_enfant_id", "enfant_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    parent_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    enfant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    code_liaison: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    cree_par: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    valide_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Reservation(AvecModification, Base):
    """Réservation d'un repas, une seule vivante par convive et par jour. Propriétaire : A5."""

    __tablename__ = "reservations"
    __table_args__ = (
        choix("etat", "confirmee", "servie", "annulee", "expiree"),
        CheckConstraint("prix_xof >= 0", name="prix_positif"),
        Index(
            "uq_reservations_convive_jour_vivante",
            "convive_id",
            "date_service",
            unique=True,
            postgresql_where=text("etat in ('confirmee', 'servie')"),
        ),
        Index("ix_reservations_date_creneau", "date_service", "creneau_id"),
        Index("ix_reservations_menu_etat", "menu_id", "etat"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    convive_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    menu_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("menus.id"), nullable=False)
    creneau_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("creneaux.id"), nullable=False
    )
    plat_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("plats.id"), nullable=False)
    date_service: Mapped[date] = mapped_column(Date, nullable=False)
    prix_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    code_ticket: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    servie_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    servie_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    annulee_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    cle_unique: Mapped[str] = mapped_column(Text, nullable=False, unique=True)


class FileScan(AvecCreation, Base):
    """Scan fait hors ligne par l'agent, reçu au retour du réseau. Ajout seul. Propriétaire : A5."""

    __tablename__ = "file_scans"
    __table_args__ = (
        choix("resultat", "accepte", "deja_servi", "inconnu", "mauvais_jour", "annule"),
        Index("ix_file_scans_agent_recu_le", "agent_id", text("recu_le desc")),
        Index("ix_file_scans_code_ticket", "code_ticket"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    agent_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    code_ticket: Mapped[str] = mapped_column(Text, nullable=False)
    reservation_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("reservations.id")
    )
    scanne_le: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    recu_le: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    cle_unique: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    resultat: Mapped[str] = mapped_column(Text, nullable=False)
    detail: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
