"""Modèles du service : liens parent-enfant, commandes par lot en trois services avec ticket QR, file des
scans hors ligne."""

import uuid
from datetime import date, datetime

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Integer, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK
from app.models.menus import SERVICES


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


class LotReservation(AvecModification, Base):
    """Geste de commande qui couvre une période : un jour, une semaine ou un mois. Propriétaire : A5.

    Le lot, ses réservations et son unique débit s'écrivent dans la même transaction : tout ou rien.
    """

    __tablename__ = "lots_reservation"
    __table_args__ = (
        choix("portee", "jour", "semaine", "mois"),
        choix("etat", "confirme", "partiellement_annule", "annule"),
        CheckConstraint("fin >= debut", name="periode_valide"),
        CheckConstraint("jours_reserves > 0", name="jours_positifs"),
        CheckConstraint("total_xof >= 0", name="total_positif"),
        Index("ix_lots_reservation_convive_debut", "convive_id", text("debut desc")),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    convive_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    portee: Mapped[str] = mapped_column(Text, nullable=False)
    debut: Mapped[date] = mapped_column(Date, nullable=False)
    fin: Mapped[date] = mapped_column(Date, nullable=False)
    jours_reserves: Mapped[int] = mapped_column(Integer, nullable=False)
    total_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    cle_unique: Mapped[str] = mapped_column(Text, nullable=False, unique=True)


class Reservation(AvecModification, Base):
    """Commande d'un jour, une seule vivante par convive et par jour, rattachée à son lot. Propriétaire : A5.

    La commande engage : non retirée, elle passe à non_reclamee sans remboursement. Après le gel, elle ne
    se modifie plus et ne peut qu'être supprimée, sans remboursement.
    """

    __tablename__ = "reservations"
    __table_args__ = (
        choix("etat", "confirmee", "servie", "annulee", "supprimee", "non_reclamee"),
        CheckConstraint("total_xof >= 0", name="total_positif"),
        Index(
            "uq_reservations_convive_jour_vivante",
            "convive_id",
            "date_service",
            unique=True,
            postgresql_where=text("etat in ('confirmee', 'servie')"),
        ),
        Index("ix_reservations_date_etat", "date_service", "etat"),
        Index("ix_reservations_menu_etat", "menu_id", "etat"),
        Index("ix_reservations_lot_id", "lot_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    lot_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("lots_reservation.id"), nullable=False
    )
    convive_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    menu_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("menus.id"), nullable=False)
    date_service: Mapped[date] = mapped_column(Date, nullable=False)
    total_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    code_ticket: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    servie_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    servie_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    annulee_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class LigneReservation(AvecCreation, Base):
    """Plat commandé dans un service, avec sa quantité et son supplément. Ajout seul. Propriétaire : A5."""

    __tablename__ = "lignes_reservation"
    __table_args__ = (
        choix("service", *SERVICES),
        CheckConstraint("quantite > 0", name="quantite_positive"),
        CheckConstraint("supplement_xof >= 0", name="supplement_positif"),
        Index("uq_lignes_reservation_reservation_plat", "reservation_id", "plat_id", unique=True),
        Index("ix_lignes_reservation_plat_id", "plat_id"),
        Index("ix_lignes_reservation_plat_service", "plat_id", "service"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    reservation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("reservations.id", ondelete="CASCADE"), nullable=False
    )
    plat_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("plats.id"), nullable=False)
    service: Mapped[str] = mapped_column(Text, nullable=False)
    quantite: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("1"))
    supplement_xof: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))


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
