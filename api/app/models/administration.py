"""Modèles de l'administration : paramètres modifiables du produit et journal des actions sensibles."""

import uuid
from typing import Any

from sqlalchemy import Boolean, ForeignKey, Index, Text, text
from sqlalchemy.dialects.postgresql import INET, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK


class Parametre(AvecModification, Base):
    """Réglage modifiable depuis le back office. Propriétaire : A1."""

    __tablename__ = "parametres"
    __table_args__ = (
        choix("type_valeur", "texte", "entier", "booleen", "heure", "liste", "objet"),
        choix("groupe", "service", "paiement", "verification", "notification", "general"),
    )

    cle: Mapped[str] = mapped_column(Text, primary_key=True)
    valeur: Mapped[Any] = mapped_column(JSONB, nullable=False)
    type_valeur: Mapped[str] = mapped_column(Text, nullable=False)
    libelle_fr: Mapped[str] = mapped_column(Text, nullable=False)
    libelle_en: Mapped[str] = mapped_column(Text, nullable=False)
    groupe: Mapped[str] = mapped_column(Text, nullable=False)
    modifiable: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    modifie_par: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))


class JournalAdmin(AvecCreation, Base):
    """Action sensible du back office. Ajout seul. Propriétaire : A1."""

    __tablename__ = "journal_admin"
    __table_args__ = (
        Index("ix_journal_admin_admin_cree_le", "admin_id", text("cree_le desc")),
        Index("ix_journal_admin_cible", "cible_type", "cible_id"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    admin_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
    action: Mapped[str] = mapped_column(Text, nullable=False)
    cible_type: Mapped[str] = mapped_column(Text, nullable=False)
    cible_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    # États avant et après : utiles à l'audit, inutiles aux listes, donc chargés seulement à la demande.
    avant: Mapped[dict[str, Any] | None] = mapped_column(JSONB, deferred=True)
    apres: Mapped[dict[str, Any] | None] = mapped_column(JSONB, deferred=True)
    adresse_ip: Mapped[str | None] = mapped_column(INET)
