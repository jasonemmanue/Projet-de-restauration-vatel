"""Catalogue : plats (création, modification, retrait logique, photo) et tarifs du menu par profil.

Chaque écriture passe par le journal de l'admin, dans la même transaction.
"""

import secrets
import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.models import Plat, Tarif
from app.schemas.catalogue import PlatEntree, PlatModification, TarifEntree
from app.services import stockage
from app.services.journal import ecrire_journal
from app.services.regles_menus import type_de_photo
from app.services.stockage import EXTENSIONS

CHAMPS_JOURNAL = ("nom_fr", "categorie", "allergenes", "regimes", "prix_supplement_xof", "actif")


def etat_plat(plat: Plat) -> dict[str, Any]:
    """État d'un plat pour le journal, sans la photo."""
    return {champ: getattr(plat, champ) for champ in CHAMPS_JOURNAL} | {"image_url": plat.image_url}


def chemin_photo(plat: Plat) -> str | None:
    """Adresse relative de la photo d'un plat sur le volume ; le client la préfixe de l'adresse de l'API."""
    return plat.image_url


async def plat_vivant(session: AsyncSession, plat_id: uuid.UUID, verrou: bool = False) -> Plat:
    """Charge un plat non retiré, ou répond 404."""
    requete = select(Plat).where(Plat.id == plat_id, Plat.supprime_le.is_(None))
    if verrou:
        requete = requete.with_for_update()
    plat = (await session.execute(requete)).scalar_one_or_none()
    if plat is None:
        raise ErreurApi("introuvable", 404)
    return plat


async def lister_plats(session: AsyncSession) -> list[Plat]:
    """Tous les plats non retirés, par service puis par nom."""
    requete = select(Plat).where(Plat.supprime_le.is_(None)).order_by(Plat.categorie, func.lower(Plat.nom_fr))
    return list((await session.execute(requete)).scalars().all())


async def creer_plat(session: AsyncSession, admin_id: uuid.UUID, corps: PlatEntree, ip: str | None) -> Plat:
    """Crée un plat ; 409 conflit si un plat vivant porte déjà ce nom."""
    plat = Plat(**corps.model_dump())
    session.add(plat)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("conflit", 409) from exc
    ecrire_journal(session, admin_id, "creation_plat", "plat", plat.id, None, etat_plat(plat), ip)
    return plat


async def modifier_plat(
    session: AsyncSession, admin_id: uuid.UUID, plat_id: uuid.UUID, corps: PlatModification, ip: str | None
) -> Plat:
    """Modifie les seuls champs envoyés."""
    plat = await plat_vivant(session, plat_id, verrou=True)
    avant = etat_plat(plat)
    for champ, valeur in corps.model_dump(exclude_unset=True).items():
        setattr(plat, champ, valeur)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("conflit", 409) from exc
    ecrire_journal(session, admin_id, "modification_plat", "plat", plat.id, avant, etat_plat(plat), ip)
    return plat


async def retirer_plat(
    session: AsyncSession, admin_id: uuid.UUID, plat_id: uuid.UUID, ip: str | None
) -> None:
    """Retire un plat du catalogue, sans effacer la ligne : les commandes passées le citent encore."""
    plat = await plat_vivant(session, plat_id, verrou=True)
    avant = etat_plat(plat)
    plat.actif = False
    plat.supprime_le = datetime.now(UTC)
    ecrire_journal(session, admin_id, "retrait_plat", "plat", plat.id, avant, etat_plat(plat), ip)


async def ranger_photo(
    session: AsyncSession,
    admin_id: uuid.UUID,
    plat_id: uuid.UUID,
    contenu: bytes,
    dossier: str,
    taille_max: int,
    ip: str | None,
) -> Plat:
    """Range la photo d'un plat sur le volume, après contrôle de sa taille et de son type réel."""
    if not contenu or len(contenu) > taille_max:
        raise ErreurApi("trop_lourd", 413)
    type_mime = type_de_photo(contenu)
    if type_mime is None:
        raise ErreurApi("fichier_invalide", 422)
    plat = await plat_vivant(session, plat_id, verrou=True)
    avant = etat_plat(plat)
    # Un nom neuf à chaque envoi : le cache des téléphones ne garde jamais l'ancienne photo.
    relatif = f"plats/{plat.id}-{secrets.token_hex(4)}.{EXTENSIONS[type_mime]}"
    await stockage.ecrire(dossier, relatif, contenu)
    plat.image_url = f"/medias/{relatif}"
    plat.photo_type = type_mime
    ecrire_journal(session, admin_id, "photo_plat", "plat", plat.id, avant, etat_plat(plat), ip)
    return plat


async def lister_tarifs(session: AsyncSession) -> list[Tarif]:
    """Tous les tarifs, du plus récent au plus ancien."""
    requete = select(Tarif).order_by(Tarif.profil, Tarif.actif_du.desc())
    return list((await session.execute(requete)).scalars().all())


async def creer_tarif(
    session: AsyncSession, admin_id: uuid.UUID, corps: TarifEntree, ip: str | None
) -> Tarif:
    """Ajoute un tarif ; le plus récent en vigueur l'emporte, les anciens restent pour l'historique."""
    tarif = Tarif(**corps.model_dump())
    session.add(tarif)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("chevauchement", 409) from exc
    apres = {"profil": tarif.profil, "prix_xof": tarif.prix_xof, "actif_du": tarif.actif_du.isoformat()}
    ecrire_journal(session, admin_id, "creation_tarif", "tarif", tarif.id, None, apres, ip)
    return tarif
