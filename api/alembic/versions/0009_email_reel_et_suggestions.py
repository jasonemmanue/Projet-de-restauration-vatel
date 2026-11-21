"""Codes par e-mail en livraison réelle (API Gmail), et table des suggestions des convives.

Revision ID: 0009
Revises: 0008
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "UPDATE parametres SET valeur = '\"reel\"' WHERE cle = 'livraison_verification_email'",
    """CREATE TABLE suggestions (
        id UUID DEFAULT gen_random_uuid() NOT NULL,
        auteur_id UUID NOT NULL,
        message TEXT NOT NULL,
        plat_souhaite TEXT DEFAULT '' NOT NULL,
        cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        CONSTRAINT pk_suggestions PRIMARY KEY (id),
        CONSTRAINT fk_suggestions_auteur_id_utilisateurs FOREIGN KEY (auteur_id) REFERENCES utilisateurs (id)
    )""",
    "CREATE INDEX ix_suggestions_cree_le ON suggestions (cree_le desc)",
)


def upgrade() -> None:
    """Passe l'e-mail en réel et crée les suggestions."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : des suggestions peuvent déjà exister."""
    raise NotImplementedError("Cette migration ne se défait pas.")
