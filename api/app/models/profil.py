"""Modèles du profil : appareils connus, avatars et signalements envoyés à l'assistance."""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, ForeignKey, Index, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecModification, Base, choix, cle_primaire
from app.models.comptes import PLATEFORMES, UTILISATEUR_FK


class Appareil(AvecModification, Base):
    """Appareil connu, pour les notifications et la biométrie. Propriétaire : A7, biométrie A3b."""

    __tablename__ = "appareils"
    __table_args__ = (
        choix("plateforme", *PLATEFORMES),
        Index("ix_appareils_utilisateur_id", "utilisateur_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    utilisateur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK, ondelete="CASCADE"), nullable=False
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("sessions.id"))
    jeton_fcm: Mapped[str | None] = mapped_column(Text, unique=True)
    plateforme: Mapped[str] = mapped_column(Text, nullable=False)
    modele: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    version_app: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    secret_biometrique_hache: Mapped[str | None] = mapped_column(Text)
    biometrie_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    derniere_vue_le: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )


class Avatar(AvecModification, Base):
    """Image de profil, du catalogue ou envoyée. Propriétaire : A3c."""

    __tablename__ = "avatars"
    __table_args__ = (
        choix("type", "catalogue", "envoye"),
        Index(
            "uq_avatars_utilisateur_envoye_actif",
            "utilisateur_id",
            unique=True,
            postgresql_where=text("type = 'envoye' and actif"),
        ),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    utilisateur_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    type: Mapped[str] = mapped_column(Text, nullable=False)
    url: Mapped[str] = mapped_column(Text, nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class Signalement(AvecModification, Base):
    """Demande d'assistance ou signalement d'un problème. Propriétaire : A3c."""

    __tablename__ = "signalements"
    __table_args__ = (
        choix("sujet", "repas", "paiement", "compte", "application", "autre"),
        choix("reference_type", "reservation", "paiement", "avis"),
        choix("etat", "ouvert", "en_cours", "clos"),
        Index("ix_signalements_etat_cree_le", "etat", text("cree_le desc")),
        Index("ix_signalements_auteur_id", "auteur_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    auteur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    sujet: Mapped[str] = mapped_column(Text, nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    reference_type: Mapped[str | None] = mapped_column(Text)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    etat: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'ouvert'"))
    reponse: Mapped[str | None] = mapped_column(Text)
    traite_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    traite_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
