"""Catalogue A4 : photo des plats rangée en base, liste fermée d'allergènes, tarifs de départ.

La photo est une colonne lourde : le modèle la charge seulement à la demande. Les tarifs de départ sont ceux
du cahier (1 500 XOF pour un élève, 2 500 XOF pour le personnel) ; les autres profils restent sans tarif
tant que l'admin ne les a pas fixés, et la commande les refuse.

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "ALTER TABLE plats ADD COLUMN photo BYTEA",
    "ALTER TABLE plats ADD COLUMN photo_type TEXT",
    "ALTER TABLE plats ADD CONSTRAINT ck_plats_photo_type "
    "CHECK (photo_type in ('image/jpeg', 'image/png', 'image/webp'))",
    "ALTER TABLE plats ADD CONSTRAINT ck_plats_allergenes CHECK (allergenes <@ array["
    "'arachide', 'poisson', 'crustaces', 'gluten', 'lait', 'oeuf', 'soja', 'sesame', "
    "'fruits_a_coque', 'celeri', 'moutarde']::text[])",
    "ALTER TABLE utilisateurs ADD CONSTRAINT ck_utilisateurs_allergies CHECK (allergies <@ array["
    "'arachide', 'poisson', 'crustaces', 'gluten', 'lait', 'oeuf', 'soja', 'sesame', "
    "'fruits_a_coque', 'celeri', 'moutarde']::text[])",
    """INSERT INTO tarifs (profil, prix_xof, actif_du) VALUES
        ('eleve', 1500, '2026-01-01T00:00:00Z'),
        ('employe', 2500, '2026-01-01T00:00:00Z')
    ON CONFLICT DO NOTHING""",
)


def upgrade() -> None:
    """Ajoute la photo, la liste fermée d'allergènes et les tarifs de départ."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : des photos peuvent déjà être rangées."""
    raise NotImplementedError("Cette migration ne se défait pas.")
