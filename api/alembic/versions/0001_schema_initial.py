"""Migration initiale : crée les 26 tables du modèle de données, leurs index, leurs contraintes et les
paramètres de départ.

Le DDL est figé dans alembic/schema_initial/*.sql : la migration ne dépend pas des modèles Python, qui
évolueront. Un test compare la base migrée aux modèles pour qu'ils ne divergent pas.

Revision ID: 0001
Revises:
Create Date: 2026-11-21
"""

from collections.abc import Sequence
from pathlib import Path

from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

DOSSIER_SQL = Path(__file__).resolve().parent.parent / "schema_initial"


def _instructions(contenu: str) -> list[str]:
    """Découpe un fichier SQL en instructions, commentaires de ligne retirés."""
    lignes = [ligne for ligne in contenu.splitlines() if not ligne.lstrip().startswith("--")]
    return [morceau.strip() for morceau in "\n".join(lignes).split(";\n") if morceau.strip().strip(";")]


def upgrade() -> None:
    """Crée le schéma complet sur une base vide."""
    # gen_random_uuid est natif depuis PostgreSQL 13 ; l'extension couvre une version plus ancienne.
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
    for fichier in sorted(DOSSIER_SQL.glob("*.sql")):
        for instruction in _instructions(fichier.read_text(encoding="utf-8")):
            op.execute(instruction.rstrip(";"))


def downgrade() -> None:
    """Refusé : défaire le schéma initial reviendrait à tout supprimer, ce que le projet interdit."""
    raise NotImplementedError("La migration initiale ne se défait pas.")
