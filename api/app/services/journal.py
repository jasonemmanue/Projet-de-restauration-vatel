"""Journal des actions de l'admin : une ligne par écriture du back office, dans la même transaction.

Les états avant et après ne contiennent jamais de secret ni de haché, et jamais de photo.
"""

import uuid
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import JournalAdmin


def ecrire_journal(
    session: AsyncSession,
    admin_id: uuid.UUID,
    action: str,
    cible_type: str,
    cible_id: uuid.UUID | None,
    avant: dict[str, Any] | None,
    apres: dict[str, Any] | None,
    ip: str | None,
) -> None:
    """Ajoute une ligne au journal des actions."""
    session.add(
        JournalAdmin(
            admin_id=admin_id,
            action=action,
            cible_type=cible_type,
            cible_id=cible_id,
            avant=avant,
            apres=apres,
            adresse_ip=ip,
        )
    )
