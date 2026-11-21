"""Protections transverses : en-têtes de sécurité, garde des erreurs, taille, CORS et adresse réelle.

Ces couches sont en ASGI pur pour s'appliquer à toutes les réponses, y compris les refus du CORS, les
dépassements de taille et les erreurs inattendues, qu'un middleware de plus haut niveau ne verrait pas.
"""

import json
import logging

from starlette.datastructures import Headers
from starlette.middleware.cors import CORSMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.core.erreurs import corps_erreur
from app.core.messages import choisir_langue

journal = logging.getLogger("vatel.securite")

ENTETES_SECURITE: tuple[tuple[bytes, bytes], ...] = (
    (b"strict-transport-security", b"max-age=31536000; includeSubDomains"),
    (b"x-content-type-options", b"nosniff"),
    (b"x-frame-options", b"DENY"),
    (b"referrer-policy", b"no-referrer"),
)


def _langue_scope(scope: Scope) -> str:
    return choisir_langue(Headers(scope=scope).get("accept-language"))


async def _envoyer_json(send: Send, statut: int, corps: dict[str, str]) -> None:
    contenu = json.dumps(corps, ensure_ascii=False).encode("utf-8")
    await send(
        {
            "type": "http.response.start",
            "status": statut,
            "headers": [
                (b"content-type", b"application/json"),
                (b"content-length", str(len(contenu)).encode()),
            ],
        }
    )
    await send({"type": "http.response.body", "body": contenu})


class GardeEtEntetes:
    """Couche la plus externe : ajoute les en-têtes de sécurité et la version, et rattrape toute erreur.

    Sans elle, une erreur inattendue serait rendue par la couche de Starlette, au-dessus de toutes les
    autres, donc sans en-têtes de sécurité ni CORS.
    """

    def __init__(self, app: ASGIApp, commit: str) -> None:
        self.app = app
        self.entetes = (*ENTETES_SECURITE, (b"x-version-commit", commit.encode()))

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        reponse_commencee = False

        async def envoyer(message: Message) -> None:
            nonlocal reponse_commencee
            if message["type"] == "http.response.start":
                reponse_commencee = True
                deja = {nom.lower() for nom, _ in message.get("headers", [])}
                ajout = [(nom, val) for nom, val in self.entetes if nom not in deja]
                message["headers"] = [*message.get("headers", []), *ajout]
            await send(message)

        try:
            await self.app(scope, receive, envoyer)
        except Exception:
            journal.exception("erreur inattendue sur %s %s", scope.get("method"), scope.get("path"))
            if not reponse_commencee:
                await _envoyer_json(envoyer, 500, corps_erreur("erreur_serveur", _langue_scope(scope)))


class LimiteTaille:
    """Refuse en 413 un corps plus gros que la limite, annoncé ou non par Content-Length."""

    def __init__(self, app: ASGIApp, taille_max: int) -> None:
        self.app = app
        self.taille_max = taille_max

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        annoncee = Headers(scope=scope).get("content-length")
        if annoncee and annoncee.isdigit() and int(annoncee) > self.taille_max:
            await _envoyer_json(send, 413, corps_erreur("requete_trop_lourde", _langue_scope(scope)))
            return
        recue = 0
        reponse_commencee = False

        async def recevoir() -> Message:
            nonlocal recue
            message = await receive()
            if message["type"] == "http.request":
                recue += len(message.get("body", b""))
                if recue > self.taille_max:
                    raise _CorpsTropLourdError
            return message

        async def envoyer(message: Message) -> None:
            nonlocal reponse_commencee
            if message["type"] == "http.response.start":
                reponse_commencee = True
            await send(message)

        try:
            await self.app(scope, recevoir, envoyer)
        except _CorpsTropLourdError:
            if not reponse_commencee:
                await _envoyer_json(send, 413, corps_erreur("requete_trop_lourde", _langue_scope(scope)))


class _CorpsTropLourdError(Exception):
    """Signal interne : le corps reçu en flux dépasse la limite."""


class CorsStrict(CORSMiddleware):
    """CORS de Starlette, avec un refus au format d'erreur unique au lieu d'un texte brut."""

    def preflight_response(self, request_headers: Headers) -> Response:
        """Rend la réponse de pré-vérification, en JSON 403 si l'origine ou la méthode est refusée."""
        reponse = super().preflight_response(request_headers)
        if reponse.status_code == 200:
            return reponse
        langue = choisir_langue(request_headers.get("accept-language"))
        return JSONResponse(status_code=403, content=corps_erreur("origine_refusee", langue))


def adresse_reelle(request: Request, proxies_de_confiance: int) -> str:
    """Rend l'adresse IP du client derrière le relais de Railway.

    Le relais ajoute l'adresse qu'il voit à la fin de X-Forwarded-For. Les entrées de gauche viennent du
    client et peuvent être inventées : on ne garde que celle posée par le dernier relais de confiance.
    """
    transmis = request.headers.get("x-forwarded-for", "")
    adresses = [a.strip() for a in transmis.split(",") if a.strip()]
    if proxies_de_confiance > 0 and len(adresses) >= proxies_de_confiance:
        return adresses[-proxies_de_confiance]
    if request.client and request.client.host:
        return request.client.host
    return "inconnue"
