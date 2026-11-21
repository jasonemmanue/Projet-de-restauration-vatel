"""Amorçage au démarrage : crée le premier compte admin depuis ADMIN_INITIAL_EMAIL et
ADMIN_INITIAL_MOT_DE_PASSE s'il n'existe pas encore. Un compte existant n'est jamais modifié.

Un verrou consultatif évite deux créations si deux processus démarrent ensemble. Les valeurs ne sont
jamais écrites dans les journaux.
"""

import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.services import comptes
from app.services.regles_comptes import IdentifiantInvalideError, normaliser_email

journal = logging.getLogger("vatel.amorcage")
VERROU_AMORCAGE = 727001


async def creer_admin_initial(fabrique: async_sessionmaker[AsyncSession], config: Configuration) -> None:
    """Crée l'admin initial si les deux variables sont posées et qu'aucun compte ne porte cet e-mail."""
    if not config.admin_initial_email or not config.admin_initial_mot_de_passe:
        journal.info("admin initial non configuré")
        return
    try:
        email = normaliser_email(config.admin_initial_email)
    except IdentifiantInvalideError:
        journal.warning("ADMIN_INITIAL_EMAIL n'est pas une adresse valide, admin initial non créé")
        return
    identifiant = comptes.Identifiant(comptes.CANAL_EMAIL, email)
    async with fabrique() as session, session.begin():
        await session.execute(text("SELECT pg_advisory_xact_lock(:cle)"), {"cle": VERROU_AMORCAGE})
        if await comptes.trouver(session, identifiant) is not None:
            journal.info("admin initial déjà présent")
            return
        donnees = comptes.NouveauCompte(
            identifiant=identifiant,
            mot_de_passe=config.admin_initial_mot_de_passe,
            prenom="Admin",
            nom="Vatel",
            role="admin",
            statut_convive=None,
        )
        try:
            await comptes.creer_compte(session, config, donnees, verifie=True, consentement=False)
        except ErreurApi as exc:
            journal.warning("admin initial non créé : %s", exc.code)
            return
    journal.info("admin initial créé")
