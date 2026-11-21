"""Recharges GeniusPay : adresse de paiement gardée sur le paiement, montants permis d'une recharge.

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "ALTER TABLE paiements ADD COLUMN url_paiement TEXT",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('recharge_min_xof', '500', 'entier', 'Recharge minimale', 'Minimum top-up', 'paiement'),
        ('recharge_max_xof', '200000', 'entier', 'Recharge maximale', 'Maximum top-up', 'paiement')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Ajoute l'adresse de paiement et les bornes d'une recharge."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : des paiements peuvent déjà porter leur adresse."""
    raise NotImplementedError("Cette migration ne se défait pas.")
