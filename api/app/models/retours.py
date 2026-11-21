"""Modèles des échanges avec les convives : avis modérés sur les plats et notifications."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK

NOTES = ("note_gout", "note_quantite", "note_temperature", "note_attente")


class Avis(AvecModification, Base):
    """Note d'un plat servi, publiée après modération. Propriétaire : A9."""

    __tablename__ = "avis"
    __table_args__ = (
        *(CheckConstraint(f"{note} between 1 and 5", name=f"{note}_entre_1_et_5") for note in NOTES),
        choix("etat", "a_examiner", "publie", "refuse"),
        Index("uq_avis_auteur_reservation", "auteur_id", "reservation_id", unique=True),
        Index("ix_avis_plat_etat", "plat_id", "etat"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    auteur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    plat_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("plats.id"), nullable=False)
    reservation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("reservations.id"), nullable=False
    )
    note_gout: Mapped[int] = mapped_column(Integer, nullable=False)
    note_quantite: Mapped[int] = mapped_column(Integer, nullable=False)
    note_temperature: Mapped[int] = mapped_column(Integer, nullable=False)
    note_attente: Mapped[int] = mapped_column(Integer, nullable=False)
    commentaire: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    etat: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'a_examiner'"))
    motif_refus: Mapped[str | None] = mapped_column(Text)
    reponse_cantine: Mapped[str | None] = mapped_column(Text)
    repondu_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    repondu_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    cle_unique: Mapped[str] = mapped_column(Text, nullable=False, unique=True)


class Notification(AvecModification, Base):
    """Notification dans l'application, doublée ou non d'un envoi push. Propriétaire : A7."""

    __tablename__ = "notifications"
    __table_args__ = (
        choix(
            "type",
            "menu_publie",
            "rappel_limite",
            "solde_bas",
            "paiement_recu",
            "repas_servi",
            "anti_gaspillage",
            "message_admin",
        ),
        choix("envoi_push", "non_demande", "en_attente", "envoye", "echoue"),
        Index("ix_notifications_destinataire_cree_le", "destinataire_id", text("cree_le desc")),
        Index("ix_notifications_non_lues", "destinataire_id", postgresql_where=text("lue_le is null")),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    destinataire_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    type: Mapped[str] = mapped_column(Text, nullable=False)
    titre: Mapped[str] = mapped_column(Text, nullable=False)
    corps: Mapped[str] = mapped_column(Text, nullable=False)
    donnees: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    lue_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    envoi_push: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'non_demande'"))
    envoye_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
