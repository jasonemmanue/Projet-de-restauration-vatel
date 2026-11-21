"""Session de base par requête, validée avant l'envoi de la réponse.

La validation se fait dans la dépendance elle-même, avant que FastAPI n'envoie la réponse : un échec de
validation devient une erreur 500 et jamais un 200 suivi d'une écriture perdue. Les effets externes
(notification, e-mail) se lancent après cette validation, jamais dedans.
"""

import asyncio
import logging
from collections.abc import AsyncIterator, Coroutine
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

journal = logging.getLogger("vatel.session")
_taches: set[asyncio.Task] = set()


def lancer_en_fond(travail: Coroutine) -> None:
    """Lance un travail de fond et garde une référence pour qu'il ne soit pas ramassé avant la fin."""
    tache = asyncio.create_task(travail)
    _taches.add(tache)
    tache.add_done_callback(_taches.discard)


async def obtenir_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Fournit une session ; valide si la route a réussi, annule sinon."""
    fabrique = request.app.state.fabrique_sessions
    async with fabrique() as session:
        session.info["application"] = request.app
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        else:
            if session.in_transaction():
                await session.commit()
            # Effets externes (notifications push) seulement après la validation, en tâche de fond.
            for tache in session.info.pop("apres_validation", []):
                lancer_en_fond(tache())


# Portée « function » : la sortie de la dépendance, donc la validation, précède l'envoi de la réponse.
# La portée par défaut de FastAPI validerait après l'envoi. Toute route passe par cet alias.
SessionBase = Annotated[AsyncSession, Depends(obtenir_session, scope="function")]
