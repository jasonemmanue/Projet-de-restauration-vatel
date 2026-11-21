"""Comptes : inscription, connexion, vérification de l'identifiant, mot de passe oublié.

La connexion répond toujours « Identifiant ou mot de passe incorrect », avec un hachage factice quand le
compte n'existe pas, pour que ni le message ni la durée ne trahissent son existence.
"""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.core.hachage import hacher_mot_de_passe, verifier_mot_de_passe
from app.models import Utilisateur
from app.services import sessions, tentatives, verification
from app.services.parametres import lire_parametres
from app.services.regles_comptes import (
    CANAL_EMAIL,
    Identifiant,
    IdentifiantInvalideError,
    mot_de_passe_valide,
    normaliser_identifiant,
)


@dataclass(frozen=True)
class NouveauCompte:
    """Données d'un compte à créer, déjà validées par le schéma."""

    identifiant: Identifiant
    mot_de_passe: str
    prenom: str
    nom: str
    role: str
    statut_convive: str | None


def lire_identifiant(saisie: str, canal: str | None = None) -> Identifiant:
    """Normalise un identifiant saisi, ou répond 422 identifiant_invalide."""
    try:
        return normaliser_identifiant(saisie, canal)
    except IdentifiantInvalideError as exc:
        raise ErreurApi("identifiant_invalide", 422) from exc


def est_verifie(utilisateur: Utilisateur) -> bool:
    """Un compte est vérifié dès que l'un de ses identifiants l'est."""
    return utilisateur.email_verifie_le is not None or utilisateur.telephone_verifie_le is not None


def canal_a_verifier(utilisateur: Utilisateur) -> str:
    """Canal par lequel le compte doit être vérifié."""
    return CANAL_EMAIL if utilisateur.email else "telephone"


async def trouver(session: AsyncSession, identifiant: Identifiant) -> Utilisateur | None:
    """Cherche un compte non supprimé par son identifiant normalisé."""
    if identifiant.canal == CANAL_EMAIL:
        condition = func.lower(Utilisateur.email) == identifiant.valeur
    else:
        condition = Utilisateur.telephone == identifiant.valeur
    requete = select(Utilisateur).where(condition, Utilisateur.supprime_le.is_(None))
    return (await session.execute(requete)).scalar_one_or_none()


async def creer_compte(
    session: AsyncSession, config: Configuration, donnees: NouveauCompte, verifie: bool, consentement: bool
) -> Utilisateur:
    """Crée un compte ; 409 compte_existe si l'identifiant est pris, 422 si le mot de passe est faible."""
    if not mot_de_passe_valide(donnees.mot_de_passe, donnees.identifiant):
        raise ErreurApi("mot_de_passe_faible", 422)
    if await trouver(session, donnees.identifiant) is not None:
        raise ErreurApi("compte_existe", 409)
    maintenant = datetime.now(UTC)
    par_email = donnees.identifiant.canal == CANAL_EMAIL
    utilisateur = Utilisateur(
        nom_complet=f"{donnees.prenom} {donnees.nom}".strip(),
        prenom=donnees.prenom,
        nom=donnees.nom,
        email=donnees.identifiant.valeur if par_email else None,
        telephone=None if par_email else donnees.identifiant.valeur,
        mot_de_passe_hache=await hacher_mot_de_passe(donnees.mot_de_passe, config.bcrypt_tours),
        role=donnees.role,
        statut_convive=donnees.statut_convive if donnees.role == "convive" else None,
        email_verifie_le=maintenant if verifie and par_email else None,
        telephone_verifie_le=maintenant if verifie and not par_email else None,
        conditions_acceptees_le=maintenant if consentement else None,
    )
    session.add(utilisateur)
    try:
        await session.flush()
    except IntegrityError as exc:
        # Deux inscriptions simultanées du même identifiant : l'index unique tranche.
        raise ErreurApi("compte_existe", 409) from exc
    return utilisateur


async def _seuils_connexion(session: AsyncSession) -> tuple[tentatives.Seuil, tentatives.Seuil]:
    reglages = await lire_parametres(
        session, "connexion_essais_max", "connexion_essais_ip_max", "connexion_blocage_minutes"
    )
    blocage = timedelta(minutes=int(reglages["connexion_blocage_minutes"]))
    return (
        tentatives.Seuil(int(reglages["connexion_essais_max"]), blocage),
        tentatives.Seuil(int(reglages["connexion_essais_ip_max"]), blocage),
    )


async def connecter(
    session: AsyncSession,
    config: Configuration,
    saisie: str,
    mot_de_passe: str,
    appareil: sessions.Appareil,
    ip: str,
) -> tuple[Utilisateur, sessions.Jetons]:
    """Vérifie identifiant et mot de passe, sous blocage par compte et par IP, puis ouvre une session."""
    try:
        identifiant = normaliser_identifiant(saisie)
        cle_compte = tentatives.cle_connexion_compte(f"{identifiant.canal}:{identifiant.valeur}")
    except IdentifiantInvalideError:
        identifiant, cle_compte = None, tentatives.cle_connexion_compte(saisie.strip().lower()[:254])
    cle_ip = tentatives.cle_connexion_ip(ip)
    if await tentatives.bloque_jusqua(session, cle_compte) or await tentatives.bloque_jusqua(session, cle_ip):
        raise ErreurApi("trop_de_tentatives", 429)

    utilisateur = await trouver(session, identifiant) if identifiant else None
    hache = utilisateur.mot_de_passe_hache if utilisateur else None
    if not await verifier_mot_de_passe(mot_de_passe, hache, config.bcrypt_tours) or utilisateur is None:
        seuil_compte, seuil_ip = await _seuils_connexion(session)
        await tentatives.compter_echec(session, cle_compte, seuil_compte)
        await tentatives.compter_echec(session, cle_ip, seuil_ip)
        await session.commit()
        raise ErreurApi("identifiants_invalides", 401)
    if not utilisateur.actif:
        raise ErreurApi("compte_desactive", 403)
    await tentatives.oublier(session, cle_compte)
    jetons = await sessions.ouvrir_session(session, config, utilisateur, appareil, ip)
    return utilisateur, jetons


async def confirmer_identifiant(
    session: AsyncSession, config: Configuration, identifiant: Identifiant, code: str, ip: str | None
) -> None:
    """Contrôle le code de vérification et marque l'identifiant comme vérifié."""
    ligne = await verification.controler_code(
        session, config, identifiant, verification.USAGE_VERIFICATION, code, ip
    )
    utilisateur = await session.get(Utilisateur, ligne.utilisateur_id, with_for_update=True)
    if utilisateur is None or utilisateur.supprime_le is not None:
        raise ErreurApi("code_invalide", 400)
    _marquer_verifie(utilisateur, identifiant)


def _marquer_verifie(utilisateur: Utilisateur, identifiant: Identifiant) -> None:
    maintenant = datetime.now(UTC)
    if identifiant.canal == CANAL_EMAIL and utilisateur.email_verifie_le is None:
        utilisateur.email_verifie_le = maintenant
    elif identifiant.canal != CANAL_EMAIL and utilisateur.telephone_verifie_le is None:
        utilisateur.telephone_verifie_le = maintenant


async def demander_code_compte(
    session: AsyncSession, config: Configuration, identifiant: Identifiant, usage: str, ip: str | None
) -> verification.CodeEnvoye:
    """Demande un code ; il n'est rendu en démo que pour un compte qui peut réellement s'en servir."""
    utilisateur = await trouver(session, identifiant)
    eligible = utilisateur is not None and utilisateur.actif
    if eligible and usage == verification.USAGE_VERIFICATION:
        deja = (
            utilisateur.email_verifie_le
            if identifiant.canal == CANAL_EMAIL
            else utilisateur.telephone_verifie_le
        )
        eligible = deja is None
    return await verification.demander_code(
        session, config, identifiant, usage, ip, utilisateur.id if eligible else None
    )


async def reinitialiser_mot_de_passe(
    session: AsyncSession,
    config: Configuration,
    identifiant: Identifiant,
    code: str,
    nouveau: str,
    ip: str | None,
) -> None:
    """Remplace le mot de passe après contrôle du code, et ferme toutes les sessions ouvertes."""
    if not mot_de_passe_valide(nouveau, identifiant):
        raise ErreurApi("mot_de_passe_faible", 422)
    ligne = await verification.controler_code(
        session, config, identifiant, verification.USAGE_REINITIALISATION, code, ip
    )
    utilisateur = await session.get(Utilisateur, ligne.utilisateur_id, with_for_update=True)
    if utilisateur is None or utilisateur.supprime_le is not None:
        raise ErreurApi("code_invalide", 400)
    utilisateur.mot_de_passe_hache = await hacher_mot_de_passe(nouveau, config.bcrypt_tours)
    # Recevoir le code prouve que l'identifiant appartient bien à la personne.
    _marquer_verifie(utilisateur, identifiant)
    await sessions.revoquer_toutes(session, utilisateur.id)
