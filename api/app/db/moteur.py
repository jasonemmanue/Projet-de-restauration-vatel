"""Moteur asynchrone PostgreSQL et fabrique de sessions.

Chaque connexion porte un délai d'attente de verrou et un délai d'exécution bornés, et parle en UTC : une
requête bloquée par un verrou échoue vite au lieu d'immobiliser le pool de l'unique instance d'API.
"""

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import Configuration


def reglages_connexion(config: Configuration) -> dict[str, str]:
    """Paramètres de session PostgreSQL posés à l'ouverture de chaque connexion."""
    return {
        "lock_timeout": str(config.lock_timeout_ms),
        "statement_timeout": str(config.statement_timeout_ms),
        "idle_in_transaction_session_timeout": str(config.statement_timeout_ms * 2),
        "timezone": "UTC",
        "application_name": "cantine-vatel-api",
    }


def creer_moteur(config: Configuration) -> AsyncEngine:
    """Crée le moteur asynchrone de l'application."""
    return create_async_engine(
        config.database_url,
        pool_size=config.pool_taille,
        max_overflow=config.pool_taille,
        pool_pre_ping=True,
        pool_recycle=1800,
        connect_args={"server_settings": reglages_connexion(config)},
    )


def creer_fabrique(moteur: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    """Crée la fabrique de sessions ; les objets restent lisibles après validation."""
    return async_sessionmaker(moteur, expire_on_commit=False, autoflush=False)
