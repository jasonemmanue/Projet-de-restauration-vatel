"""Modèles des stocks : ingrédients et mouvements de stock en ajout seul."""

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Numeric, Text, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire
from app.models.comptes import UTILISATEUR_FK

QUANTITE = Numeric(12, 3)


class Ingredient(AvecModification, Base):
    """Matière en stock, avec son seuil d'alerte. Propriétaire : A8."""

    __tablename__ = "ingredients"
    __table_args__ = (
        choix("unite", "kg", "g", "l", "cl", "piece"),
        CheckConstraint("quantite_actuelle >= 0", name="quantite_positive"),
        CheckConstraint("seuil_alerte >= 0", name="seuil_positif"),
        Index("uq_ingredients_nom_minuscule", func.lower(text("nom")), unique=True),
        Index("ix_ingredients_sous_seuil", "id", postgresql_where=text("quantite_actuelle < seuil_alerte")),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    nom: Mapped[str] = mapped_column(Text, nullable=False)
    unite: Mapped[str] = mapped_column(Text, nullable=False)
    quantite_actuelle: Mapped[Decimal] = mapped_column(QUANTITE, nullable=False, server_default=text("0"))
    seuil_alerte: Mapped[Decimal] = mapped_column(QUANTITE, nullable=False, server_default=text("0"))
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class MouvementStock(AvecCreation, Base):
    """Entrée, sortie, perte ou inventaire d'un ingrédient. Ajout seul. Propriétaire : A8."""

    __tablename__ = "mouvements_stock"
    __table_args__ = (
        choix("sens", "entree", "sortie", "perte", "inventaire"),
        choix("reference_type", "reservation", "service", "achat"),
        CheckConstraint("quantite > 0", name="quantite_positive"),
        CheckConstraint("quantite_apres >= 0", name="quantite_apres_positive"),
        Index("ix_mouvements_stock_ingredient_cree_le", "ingredient_id", text("cree_le desc")),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    ingredient_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("ingredients.id"), nullable=False
    )
    sens: Mapped[str] = mapped_column(Text, nullable=False)
    quantite: Mapped[Decimal] = mapped_column(QUANTITE, nullable=False)
    quantite_apres: Mapped[Decimal] = mapped_column(QUANTITE, nullable=False)
    reference_type: Mapped[str | None] = mapped_column(Text)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    commentaire: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    cree_par: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK), nullable=False
    )
