"""Grille de frais GeniusPay donnée par l'exploitant le 21 novembre, en parts pour dix mille (entiers).

Les taux en pourcentage entier de la migration 0003 ne savaient pas dire 1,5 % : ils sont remplacés par des
parts pour dix mille (150 = 1,5 %). Ces valeurs ne servent qu'à l'estimation affichée avant paiement et à
l'écran des frais ; les frais réels de chaque paiement viennent de GeniusPay.

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "DELETE FROM parametres WHERE cle IN ('frais_geniuspay_pourcent', 'frais_retrait_pourcent')",
    "UPDATE parametres SET valeur = '100' WHERE cle = 'frais_geniuspay_fixe_xof'",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('frais_geniuspay_pdm', '100', 'entier', 'Frais GeniusPay par encaissement, pour dix mille (100 = 1 %)',
         'GeniusPay fee per payment, per ten thousand (100 = 1%)', 'paiement'),
        ('frais_retrait_pdm', '100', 'entier', 'Frais au retrait, pour dix mille (100 = 1 %)',
         'Withdrawal fee, per ten thousand (100 = 1%)', 'paiement'),
        ('frais_passerelles_pdm', '{"wave": 150, "orange": 350, "mtn": 350, "stripe": 500, "lien_tiers": 500}',
         'objet', 'Frais de passerelle par opérateur, pour dix mille', 'Gateway fee by operator, per ten thousand',
         'paiement')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Pose la grille de frais."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : la grille peut déjà avoir été réglée au back office."""
    raise NotImplementedError("Cette migration ne se défait pas.")
