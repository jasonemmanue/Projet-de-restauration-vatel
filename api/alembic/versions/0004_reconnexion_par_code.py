"""Reconnexion par code après une absence : nouvel usage de code et durée d'inactivité d'une session.

Décision de l'exploitant du 21 novembre : le code de vérification sert à l'inscription et au retour après
5 jours sans ouvrir l'application. La session se prolonge à chaque ouverture ; passé ce délai, il faut le
mot de passe puis un code.

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "ALTER TABLE codes_verification DROP CONSTRAINT ck_codes_verification_usage",
    "ALTER TABLE codes_verification ADD CONSTRAINT ck_codes_verification_usage CHECK (usage in "
    "('verification_compte', 'reinitialisation_mot_de_passe', 'secours', 'changement_identifiant', 'reconnexion'))",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('session_inactivite_jours', '5', 'entier',
         'Jours sans ouvrir l''application avant que la session expire et qu''un code soit demandé',
         'Days without opening the app before the session expires and a code is required', 'general')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Ajoute l'usage de reconnexion et la durée d'inactivité."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : des codes de reconnexion peuvent déjà exister."""
    raise NotImplementedError("Cette migration ne se défait pas.")
