"""Base déclarative des modèles et colonnes communes à toutes les tables."""

import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, MetaData, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.types import DateTime

# Noms de contraintes prévisibles : une migration future peut les viser sans les deviner.
CONVENTION = {
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Classe mère de tous les modèles."""

    metadata = MetaData(naming_convention=CONVENTION)


def cle_primaire() -> Mapped[uuid.UUID]:
    """Clé primaire uuid générée par PostgreSQL."""
    return mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))


def horodatage() -> Mapped[datetime]:
    """Horodatage UTC rempli par la base à l'insertion."""
    return mapped_column(DateTime(timezone=True), nullable=False, server_default=text("now()"))


class AvecCreation:
    """Ajoute cree_le à une table en ajout seul."""

    cree_le: Mapped[datetime] = horodatage()


class AvecModification(AvecCreation):
    """Ajoute cree_le et modifie_le à une table modifiable."""

    # La base remplit la valeur initiale ; l'ORM la rafraîchit à chaque mise à jour.
    modifie_le: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()"), onupdate=text("now()")
    )


def choix(colonne: str, *valeurs: str, nom: str | None = None) -> CheckConstraint:
    """Contrainte check qui limite une colonne texte à une liste de valeurs, à la place d'un type enum."""
    liste = ", ".join(f"'{v}'" for v in valeurs)
    return CheckConstraint(f"{colonne} in ({liste})", name=nom or colonne)
