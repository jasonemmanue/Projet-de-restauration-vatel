"""Point d'entrée de l'API : assemble configuration, base, middlewares, erreurs et routes.

Ordre des couches, de l'extérieur vers l'intérieur : garde et en-têtes de sécurité, CORS, limite de taille,
limite de débit, puis l'application. La garde est tout à l'extérieur pour que même un refus du CORS ou une
erreur inattendue porte les en-têtes de sécurité.
"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from slowapi.middleware import SlowAPIASGIMiddleware

from app import __version__
from app.core.config import Configuration, lire_configuration
from app.core.erreurs import installer_gestionnaires
from app.core.journalisation import configurer_journaux
from app.core.limites import creer_limiteur
from app.core.securite import CorsStrict, GardeEtEntetes, LimiteTaille
from app.db.moteur import creer_fabrique, creer_moteur
from app.routes import (
    admin_catalogue,
    admin_menus,
    admin_tableau,
    admin_utilisateurs,
    agent,
    auth,
    liens_paiement,
    medias,
    menus,
    moi,
    paiements,
    parent,
    reservations,
    sante,
)
from app.services.amorcage import creer_admin_initial
from app.services.stockage import copier_demo


def creer_application(config: Configuration | None = None) -> FastAPI:
    """Construit l'application FastAPI à partir de la configuration lue dans l'environnement."""
    config = config or lire_configuration()
    configurer_journaux(config.log_niveau)
    moteur = creer_moteur(config)

    @asynccontextmanager
    async def cycle_de_vie(app: FastAPI) -> AsyncIterator[None]:
        try:
            copier_demo(config.stockage_dossier)
        except OSError:
            logging.getLogger("vatel.stockage").exception("copie des images de démonstration impossible")
        try:
            await creer_admin_initial(app.state.fabrique_sessions, config)
        except Exception:
            # Une base indisponible au démarrage ne doit pas empêcher /health de le signaler.
            logging.getLogger("vatel.amorcage").exception("amorçage impossible")
        yield
        await app.state.client_http.aclose()
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
    # Un seul client HTTP pour les prestataires (GeniusPay) : connexions réutilisées, délais bornés.
    application.state.client_http = httpx.AsyncClient(timeout=httpx.Timeout(20.0))

    installer_gestionnaires(application)
    for module in (
        sante,
        medias,
        auth,
        moi,
        menus,
        reservations,
        parent,
        paiements,
        liens_paiement,
        admin_utilisateurs,
        admin_catalogue,
        admin_menus,
        admin_tableau,
        agent,
    ):
        application.include_router(module.routeur)

    # L'application web Flutter est servie par ce même service, sous /app, pour que tout vive
    # derrière une seule adresse. Le dossier est produit au build et peut manquer en local.
    dossier_web = Path(__file__).resolve().parents[1] / "web_app"
    if dossier_web.is_dir():
        application.mount(
            "/app",
            StaticFiles(directory=dossier_web, html=True),
            name="application_web",
        )

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
