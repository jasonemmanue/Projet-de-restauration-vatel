"""Gestion des comptes par l'admin : création d'un compte déjà vérifié, suppression logique, journal.

Chaque action écrit une ligne dans journal_admin, dans la même transaction que l'action.
"""

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.core.hachage import mot_de_passe_inutilisable
from app.models import Utilisateur
from app.services import comptes, sessions
from app.services.journal import ecrire_journal


def _etat(utilisateur: Utilisateur) -> dict[str, Any]:
    # Jamais de haché ni de secret dans le journal.
    return {
        "role": utilisateur.role,
        "statut_convive": utilisateur.statut_convive,
        "actif": utilisateur.actif,
        "supprime": utilisateur.supprime_le is not None,
    }


def journaliser(
    session: AsyncSession,
    admin_id: uuid.UUID,
    action: str,
    cible: Utilisateur,
    avant: dict[str, Any] | None,
    ip: str | None,
) -> None:
    """Ajoute au journal une action sur un compte."""
    ecrire_journal(session, admin_id, action, "utilisateur", cible.id, avant, _etat(cible), ip)


async def creer_par_admin(
    session: AsyncSession,
    config: Configuration,
    admin_id: uuid.UUID,
    donnees: comptes.NouveauCompte,
    ip: str | None,
) -> Utilisateur:
    """Crée un compte de n'importe quel rôle, déjà vérifié."""
    utilisateur = await comptes.creer_compte(session, config, donnees, verifie=True, consentement=False)
    journaliser(session, admin_id, "creation_compte", utilisateur, None, ip)
    return utilisateur


async def supprimer_par_admin(
    session: AsyncSession, config: Configuration, admin_id: uuid.UUID, cible_id: uuid.UUID, ip: str | None
) -> None:
    """Supprime logiquement un compte : identifiants libérés, connexion impossible, sessions fermées.

    Un compte admin ne se supprime pas ici : la gestion de l'équipe admin a ses propres garde-fous (A8).
    """
    cible = await session.get(Utilisateur, cible_id, with_for_update=True)
    if cible is None or cible.supprime_le is not None:
        raise ErreurApi("introuvable", 404)
    if cible.role == "admin" or cible.id == admin_id:
        raise ErreurApi("suppression_interdite", 409)
    avant = _etat(cible)
    # L'adresse en .invalid ne peut appartenir à personne et garde la contrainte « téléphone ou e-mail ».
    cible.email = f"supprime-{cible.id}@supprime.invalid"
    cible.telephone = None
    cible.google_id = None
    cible.apple_id = None
    cible.email_verifie_le = None
    cible.telephone_verifie_le = None
    cible.mot_de_passe_hache = mot_de_passe_inutilisable(config.bcrypt_tours)
    cible.actif = False
    cible.supprime_le = datetime.now(UTC)
    await sessions.revoquer_toutes(session, cible.id)
    journaliser(session, admin_id, "suppression_compte", cible, avant, ip)
