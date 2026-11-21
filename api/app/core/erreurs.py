"""Format d'erreur unique {"code", "message"} pour toutes les réponses en échec.

Erreurs métier, erreurs de validation, routes inconnues, limites de débit et erreurs inattendues passent
toutes par ici. Une trace technique ne quitte jamais le serveur : elle va dans les journaux.
"""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.messages import choisir_langue, code_pour_statut, message_pour

journal = logging.getLogger("vatel.erreurs")


class ErreurApi(Exception):
    """Erreur métier levée par un service, traduite en réponse {"code", "message"}."""

    def __init__(self, code: str, statut: int = 400) -> None:
        super().__init__(code)
        self.code = code
        self.statut = statut


def corps_erreur(code: str, langue: str) -> dict[str, str]:
    """Construit le corps JSON d'une erreur dans la langue demandée."""
    return {"code": code, "message": message_pour(code, langue)}


def reponse_erreur(
    code: str, statut: int, langue: str, entetes: dict[str, str] | None = None
) -> JSONResponse:
    """Construit la réponse JSON d'une erreur."""
    return JSONResponse(status_code=statut, content=corps_erreur(code, langue), headers=entetes)


def _langue(request: Request) -> str:
    return choisir_langue(request.headers.get("accept-language"))


async def _sur_erreur_api(request: Request, exc: ErreurApi) -> JSONResponse:
    return reponse_erreur(exc.code, exc.statut, _langue(request))


async def _sur_erreur_http(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    entetes = {"Allow": exc.headers["Allow"]} if exc.headers and "Allow" in exc.headers else None
    return reponse_erreur(code_pour_statut(exc.status_code), exc.status_code, _langue(request), entetes)


async def _sur_erreur_validation(request: Request, exc: RequestValidationError) -> JSONResponse:
    # Le détail des champs reste dans les journaux : il peut contenir la valeur envoyée.
    journal.info("validation refusée sur %s : %s", request.url.path, [e.get("loc") for e in exc.errors()])
    return reponse_erreur("validation", 422, _langue(request))


async def _sur_limite_debit(request: Request, exc: Exception) -> JSONResponse:
    return reponse_erreur("trop_de_requetes", 429, _langue(request), {"Retry-After": "60"})


async def _sur_erreur_inattendue(request: Request, exc: Exception) -> JSONResponse:
    journal.exception("erreur inattendue sur %s %s", request.method, request.url.path)
    return reponse_erreur("erreur_serveur", 500, _langue(request))


def installer_gestionnaires(application: FastAPI) -> None:
    """Branche tous les gestionnaires d'erreur sur l'application."""
    application.add_exception_handler(ErreurApi, _sur_erreur_api)
    application.add_exception_handler(StarletteHTTPException, _sur_erreur_http)
    application.add_exception_handler(RequestValidationError, _sur_erreur_validation)
    application.add_exception_handler(RateLimitExceeded, _sur_limite_debit)
    application.add_exception_handler(Exception, _sur_erreur_inattendue)
