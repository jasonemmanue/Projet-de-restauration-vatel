"""Dépendances d'accès : utilisateur courant lu dans le jeton, compte vérifié, rôle exigé, mot de passe des
actions. Refus par défaut : une route qui n'en déclare aucune reste publique, toutes les autres en
déclarent une explicitement.

L'identité vient du seul jeton, jamais du corps ni de l'URL, et la session est relue en base à chaque appel.
"""

import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Header, Request
from sqlalchemy import select

from app.core.erreurs import ErreurApi
from app.core.hachage import egal_en_temps_constant
from app.core.jetons import JetonInvalideError, lire_jeton_acces
from app.core.securite import adresse_reelle
from app.db.session import SessionBase
from app.models import SessionAppareil, Utilisateur
from app.services.comptes import est_verifie


@dataclass(frozen=True)
class Connecte:
    """Utilisateur authentifié et session par laquelle il passe."""

    utilisateur: Utilisateur
    session_id: uuid.UUID


def adresse_client(request: Request) -> str:
    """Adresse IP réelle du client, derrière le relais."""
    return adresse_reelle(request, request.app.state.config.proxies_de_confiance)


async def utilisateur_courant(
    request: Request, session: SessionBase, authorization: Annotated[str | None, Header()] = None
) -> Connecte:
    """Lit le jeton d'accès, puis vérifie en base que la session est ouverte et le compte actif."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ErreurApi("non_authentifie", 401)
    try:
        contenu = lire_jeton_acces(request.app.state.config.secret_key, authorization[7:].strip())
    except JetonInvalideError as exc:
        raise ErreurApi("jeton_invalide", 401) from exc
    ligne = (
        await session.execute(
            select(SessionAppareil, Utilisateur)
            .join(Utilisateur, Utilisateur.id == SessionAppareil.utilisateur_id)
            .where(SessionAppareil.id == contenu.session_id, Utilisateur.id == contenu.utilisateur_id)
        )
    ).first()
    if ligne is None:
        raise ErreurApi("jeton_invalide", 401)
    session_appareil, utilisateur = ligne
    if session_appareil.revoquee_le is not None:
        raise ErreurApi("session_revoquee", 401)
    if not utilisateur.actif or utilisateur.supprime_le is not None:
        raise ErreurApi("compte_desactive", 403)
    return Connecte(utilisateur, session_appareil.id)


UtilisateurCourant = Annotated[Connecte, Depends(utilisateur_courant)]


async def utilisateur_verifie(connecte: UtilisateurCourant) -> Connecte:
    """Exige un compte vérifié : seuls le profil, la vérification et la déconnexion s'en passent."""
    if not est_verifie(connecte.utilisateur):
        raise ErreurApi("a_verifier", 403)
    return connecte


UtilisateurVerifie = Annotated[Connecte, Depends(utilisateur_verifie)]


def exiger_role(*roles: str) -> Callable[[Connecte], Awaitable[Connecte]]:
    """Fabrique une dépendance qui n'admet que les rôles donnés, sur un compte vérifié."""

    async def _controle(connecte: UtilisateurVerifie) -> Connecte:
        if connecte.utilisateur.role not in roles:
            raise ErreurApi("acces_refuse", 403)
        return connecte

    return _controle


Admin = Annotated[Connecte, Depends(exiger_role("admin"))]


async def mot_de_passe_actions(
    request: Request, admin: Admin, x_mot_de_passe_actions: Annotated[str | None, Header()] = None
) -> Connecte:
    """Exige un admin puis l'en-tête X-Mot-De-Passe-Actions, pour une action sensible du back office.

    Le rôle passe d'abord : le mot de passe des actions ne se devine pas sans un compte admin connecté.
    """
    attendu = request.app.state.config.admin_actions_password
    if not x_mot_de_passe_actions or not egal_en_temps_constant(x_mot_de_passe_actions, attendu):
        raise ErreurApi("mot_de_passe_actions_invalide", 403)
    return admin


AdminAvecActions = Annotated[Connecte, Depends(mot_de_passe_actions)]
