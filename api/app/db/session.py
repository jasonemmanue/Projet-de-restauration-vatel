"""Session de base par requête, validée avant l'envoi de la réponse.

La validation se fait dans la dépendance elle-même, avant que FastAPI n'envoie la réponse : un échec de
validation devient une erreur 500 et jamais un 200 suivi d'une écriture perdue. Les effets externes
(notification, e-mail) se lancent après cette validation, jamais dedans.
"""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession


async def obtenir_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Fournit une session ; valide si la route a réussi, annule sinon."""
    fabrique = request.app.state.fabrique_sessions
    async with fabrique() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        else:
            if session.in_transaction():
                await session.commit()


# Portée « function » : la sortie de la dépendance, donc la validation, précède l'envoi de la réponse.
# La portée par défaut de FastAPI validerait après l'envoi. Toute route passe par cet alias.
SessionBase = Annotated[AsyncSession, Depends(obtenir_session, scope="function")]
