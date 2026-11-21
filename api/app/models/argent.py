"""Modèles de l'argent : porte-monnaie, mouvements, paiements Mobile Money et liens de paiement.

Le solde n'existe que par la somme des mouvements. `solde_cache_xof` est une copie de lecture, recalculée
dans la transaction qui insère un mouvement, jamais écrite à la main.
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Integer, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK


class PorteMonnaie(AvecModification, Base):
    """Porte-monnaie d'un utilisateur, sans solde modifiable. Propriétaire : A5."""

    __tablename__ = "porte_monnaie"
    __table_args__ = (CheckConstraint("devise = 'XOF'", name="devise_xof"),)

    id: Mapped[uuid.UUID] = cle_primaire()
    utilisateur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False, unique=True
    )
    devise: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'XOF'"))
    gele: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    solde_cache_xof: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    recalcule_le: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )


class Mouvement(AvecCreation, Base):
    """Mouvement d'argent, en ajout seul : une correction est un mouvement inverse. Propriétaire : A5."""

    __tablename__ = "mouvements"
    __table_args__ = (
        choix("sens", "credit", "debit"),
        choix(
            "motif",
            "recharge",
            "reservation",
            "annulation",
            "remboursement",
            "supplement",
            "ajustement_admin",
        ),
        choix("reference_type", "lot_reservation", "reservation", "paiement", "lien_paiement"),
        CheckConstraint("montant_xof > 0", name="montant_positif"),
        CheckConstraint("solde_apres_xof >= 0", name="solde_positif"),
        Index("ix_mouvements_porte_monnaie_cree_le", "porte_monnaie_id", text("cree_le desc")),
        Index("ix_mouvements_reference", "reference_type", "reference_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    porte_monnaie_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("porte_monnaie.id"), nullable=False
    )
    sens: Mapped[str] = mapped_column(Text, nullable=False)
    montant_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    motif: Mapped[str] = mapped_column(Text, nullable=False)
    reference_type: Mapped[str | None] = mapped_column(Text)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    solde_apres_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    cle_unique: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    cree_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))


class Paiement(AvecModification, Base):
    """Recharge Mobile Money par GeniusPay. Propriétaire : A6."""

    __tablename__ = "paiements"
    __table_args__ = (
        choix("operateur", "orange", "mtn", "moov", "wave"),
        choix("mode", "test", "reel"),
        choix("etat", "initie", "en_attente", "reussi", "echoue", "expire"),
        CheckConstraint("montant_xof > 0", name="montant_positif"),
        CheckConstraint("frais_xof >= 0", name="frais_positifs"),
        CheckConstraint("net_xof >= 0", name="net_positif"),
        Index("ix_paiements_beneficiaire_cree_le", "beneficiaire_id", text("cree_le desc")),
        Index("ix_paiements_etat", "etat"),
        Index("ix_paiements_mode", "mode"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    payeur_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    beneficiaire_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    # Clé étrangère posée après la création des deux tables : paiements et liens se citent l'un l'autre.
    lien_paiement_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("liens_paiement.id", use_alter=True)
    )
    montant_xof: Mapped[int] = mapped_column(Integer, nullable=False)
    operateur: Mapped[str] = mapped_column(Text, nullable=False)
    telephone_payeur: Mapped[str] = mapped_column(Text, nullable=False)
    mode: Mapped[str] = mapped_column(Text, nullable=False)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    reference_geniuspay: Mapped[str | None] = mapped_column(Text, unique=True)
    cle_geste: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    # Frais retenus par GeniusPay et net pour la cantine, lus dans sa réponse : la cantine les supporte.
    frais_xof: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    net_xof: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    # Charge utile brute du prestataire : lourde et rarement lue, chargée seulement à la demande.
    charge_utile_webhook: Mapped[dict[str, Any] | None] = mapped_column(JSONB, deferred=True)
    motif_echec: Mapped[str | None] = mapped_column(Text)
    confirme_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class LienPaiement(AvecModification, Base):
    """Lien envoyé à un proche pour qu'il paie une recharge. Propriétaire : A6."""

    __tablename__ = "liens_paiement"
    __table_args__ = (
        choix("etat", "actif", "paye", "expire", "annule"),
        CheckConstraint("montant_xof > 0", name="montant_positif"),
        Index("ix_liens_paiement_createur_cree_le", "createur_id", text("cree_le desc")),
        Index("ix_liens_paiement_etat", "etat"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    createur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    beneficiaire_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    jeton_public: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    montant_xof: Mapped[int | None] = mapped_column(Integer)
    message: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    expire_le: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    paiement_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("paiements.id"))
