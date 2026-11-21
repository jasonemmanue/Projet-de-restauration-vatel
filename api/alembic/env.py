"""Environnement Alembic : applique les migrations avec le moteur asynchrone et l'URL de l'environnement.

Seule DATABASE_URL est lue ici, pour qu'une migration puisse tourner sans les secrets de l'API.
"""

import asyncio
import os

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context
from app.core.config import normaliser_url_base
from app.db.base import Base
from app.models import __all__ as _modeles  # noqa: F401  charge toutes les tables

config = context.config
metadonnees = Base.metadata


def _url() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        raise RuntimeError("DATABASE_URL manque pour appliquer les migrations")
    return normaliser_url_base(url)


def _executer(connexion: Connection) -> None:
    context.configure(connection=connexion, target_metadata=metadonnees, compare_type=True)
    with context.begin_transaction():
        context.run_migrations()


async def _en_ligne() -> None:
    moteur = create_async_engine(
        _url(),
        poolclass=pool.NullPool,
        connect_args={"server_settings": {"lock_timeout": "10000", "timezone": "UTC"}},
    )
    async with moteur.connect() as connexion:
        await connexion.run_sync(_executer)
    await moteur.dispose()


if context.is_offline_mode():
    raise RuntimeError("Le mode hors ligne d'Alembic n'est pas utilisé")
asyncio.run(_en_ligne())
