"""Code de liaison parent-enfant porté par le compte du convive, haché, avec sa date d'expiration.

Le code existe avant qu'un parent ne soit connu : il ne peut donc pas vivre dans liens_parent_enfant, dont
chaque ligne exige un parent. Il donne accès aux repas et au solde de l'enfant : il est rangé haché, comme
un mot de passe, et plusieurs parents peuvent s'en servir tant qu'il n'a pas expiré.

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "ALTER TABLE utilisateurs ADD COLUMN code_liaison_hache TEXT",
    "ALTER TABLE utilisateurs ADD COLUMN code_liaison_expire_le TIMESTAMP WITH TIME ZONE",
    "ALTER TABLE utilisateurs ADD CONSTRAINT uq_utilisateurs_code_liaison_hache UNIQUE (code_liaison_hache)",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('liaison_code_jours', '7', 'entier', 'Jours de validité d''un code de liaison parent',
         'Parent link code validity in days', 'general')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Ajoute le code de liaison au compte."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : des parents peuvent déjà s'être liés."""
    raise NotImplementedError("Cette migration ne se défait pas.")
