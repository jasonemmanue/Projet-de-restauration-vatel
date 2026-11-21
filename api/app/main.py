"""Point d'entrée de l'API : assemble configuration, base, middlewares, erreurs et routes.

Ordre des couches, de l'extérieur vers l'intérieur : garde et en-têtes de sécurité, CORS, limite de taille,
limite de débit, puis l'application. La garde est tout à l'extérieur pour que même un refus du CORS ou une
erreur inattendue porte les en-têtes de sécurité.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from slowapi.middleware import SlowAPIASGIMiddleware

from app import __version__
from app.core.config import Configuration, lire_configuration
from app.core.erreurs import installer_gestionnaires
from app.core.journalisation import configurer_journaux
from app.core.limites import creer_limiteur
from app.core.securite import CorsStrict, GardeEtEntetes, LimiteTaille
from app.db.moteur import creer_fabrique, creer_moteur
from app.routes import sante


def creer_application(config: Configuration | None = None) -> FastAPI:
    """Construit l'application FastAPI à partir de la configuration lue dans l'environnement."""
    config = config or lire_configuration()
    configurer_journaux(config.log_niveau)
    moteur = creer_moteur(config)

    @asynccontextmanager
    async def cycle_de_vie(_: FastAPI) -> AsyncIterator[None]:
        yield
        await moteur.dispose()

    application = FastAPI(
        title="CANTINE VATEL",
        version=__version__,
        lifespan=cycle_de_vie,
        docs_url="/docs" if config.docs_enabled else None,
        redoc_url=None,
        openapi_url="/openapi.json" if config.docs_enabled else None,
    )
    application.state.config = config
    application.state.moteur = moteur
    application.state.fabrique_sessions = creer_fabrique(moteur)
    application.state.limiter = creer_limiteur(config.limite_debit_defaut)

    installer_gestionnaires(application)
    application.include_router(sante.routeur)

    # add_middleware empile vers l'extérieur : la dernière ajoutée est la plus externe.
    application.add_middleware(SlowAPIASGIMiddleware)
    application.add_middleware(LimiteTaille, taille_max=config.taille_requete_max_octets)
    application.add_middleware(
        CorsStrict,
        allow_origins=config.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Accept-Language", "Cle-Geste", "X-Preuve-Pin"],
        expose_headers=["X-Version-Commit"],
        max_age=600,
    )
    application.add_middleware(GardeEtEntetes, commit=config.commit)
    return application


def creer_application_uvicorn() -> FastAPI:
    """Fabrique appelée par uvicorn avec --factory : la configuration n'est lue qu'au démarrage."""
    return creer_application()
