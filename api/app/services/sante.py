"""Vérification de la santé : la base répond-elle ?"""

import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

journal = logging.getLogger("vatel.sante")


async def base_repond(session: AsyncSession) -> bool:
    """Dit si PostgreSQL répond à une requête triviale ; la cause d'un échec va dans les journaux."""
    try:
        resultat = await session.execute(text("select 1"))
        return resultat.scalar_one() == 1
    except Exception:
        journal.exception("la base ne répond pas")
        # Une transaction en échec ne doit pas être validée par la dépendance de session.
        try:
            await session.rollback()
        except Exception:
            journal.warning("annulation impossible après l'échec du contrôle de base")
        return False
