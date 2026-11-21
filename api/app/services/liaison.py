"""Liaison parent-enfant : code du convive, liaison du parent, accès aux enfants liés et à eux seuls.

Un parent n'atteint que ses enfants liés : tout autre compte répond 404, comme s'il n'existait pas. Les codes
faux sont comptés par parent et bloquent un temps, pour qu'on ne devine pas un code en essayant au hasard.
"""

import secrets
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.core.hachage import hmac_hex
from app.models import LienParentEnfant, Utilisateur
from app.services import tentatives
from app.services.parametres import lire_entier, lire_parametres
from app.services.regles_comptes import ALPHABET_CODE_EMAIL, normaliser_code

LONGUEUR_CODE_LIAISON = 8


def _empreinte(secret: str, code: str) -> str:
    return hmac_hex(secret, "liaison:" + normaliser_code(code))


async def nouveau_code(session: AsyncSession, secret: str, convive: Utilisateur) -> tuple[str, datetime]:
    """Tire un nouveau code de liaison pour un convive ; l'ancien cesse aussitôt de servir."""
    if convive.role != "convive":
        raise ErreurApi("role_invalide", 409)
    code = "".join(secrets.choice(ALPHABET_CODE_EMAIL) for _ in range(LONGUEUR_CODE_LIAISON))
    expire_le = datetime.now(UTC) + timedelta(days=await lire_entier(session, "liaison_code_jours"))
    convive.code_liaison_hache = _empreinte(secret, code)
    convive.code_liaison_expire_le = expire_le
    return code, expire_le


async def lier(session: AsyncSession, secret: str, parent: Utilisateur, code: str) -> Utilisateur:
    """Lie un parent à l'enfant qui porte ce code ; 400 code_invalide si le code est faux ou expiré."""
    cle = f"liaison:{parent.id}"
    if await tentatives.bloque_jusqua(session, cle):
        raise ErreurApi("trop_essais", 429)
    enfant = (
        await session.execute(
            select(Utilisateur).where(
                Utilisateur.code_liaison_hache == _empreinte(secret, code), Utilisateur.supprime_le.is_(None)
            )
        )
    ).scalar_one_or_none()
    expire = (
        enfant is None
        or enfant.code_liaison_expire_le is None
        or enfant.code_liaison_expire_le <= datetime.now(UTC)
    )
    if expire or enfant.id == parent.id:
        reglages = await lire_parametres(session, "essais_code_max", "blocage_codes_minutes")
        seuil = tentatives.Seuil(
            int(reglages["essais_code_max"]), timedelta(minutes=int(reglages["blocage_codes_minutes"]))
        )
        await tentatives.compter_echec(session, cle, seuil)
        await session.commit()
        raise ErreurApi("code_invalide", 400)
    lien = (
        await session.execute(
            select(LienParentEnfant).where(
                LienParentEnfant.parent_id == parent.id, LienParentEnfant.enfant_id == enfant.id
            )
        )
    ).scalar_one_or_none()
    if lien is not None and lien.etat == "actif":
        raise ErreurApi("deja_lie", 409)
    maintenant = datetime.now(UTC)
    if lien is None:
        # Le code de la ligne n'est qu'un repère du lien : celui du convive reste sur son compte.
        repere = "".join(secrets.choice(ALPHABET_CODE_EMAIL) for _ in range(LONGUEUR_CODE_LIAISON))
        session.add(
            LienParentEnfant(
                parent_id=parent.id,
                enfant_id=enfant.id,
                code_liaison=repere,
                etat="actif",
                cree_par=parent.id,
                valide_le=maintenant,
            )
        )
    else:
        lien.etat = "actif"
        lien.valide_le = maintenant
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("deja_lie", 409) from exc
    await tentatives.oublier(session, cle)
    return enfant


async def enfants(session: AsyncSession, parent_id: uuid.UUID) -> list[Utilisateur]:
    """Enfants liés et actifs d'un parent."""
    lignes = await session.scalars(
        select(Utilisateur)
        .join(LienParentEnfant, LienParentEnfant.enfant_id == Utilisateur.id)
        .where(
            LienParentEnfant.parent_id == parent_id,
            LienParentEnfant.etat == "actif",
            Utilisateur.supprime_le.is_(None),
        )
        .order_by(Utilisateur.prenom)
    )
    return list(lignes.all())


async def enfant_lie(session: AsyncSession, parent_id: uuid.UUID, enfant_id: uuid.UUID) -> Utilisateur:
    """Un enfant lié à ce parent, ou 404 : tout autre compte n'existe pas pour lui."""
    for enfant in await enfants(session, parent_id):
        if enfant.id == enfant_id:
            return enfant
    raise ErreurApi("introuvable", 404)


async def delier(session: AsyncSession, parent_id: uuid.UUID, enfant_id: uuid.UUID) -> None:
    """Coupe le lien d'un parent avec un enfant."""
    await enfant_lie(session, parent_id, enfant_id)
    lien = (
        await session.execute(
            select(LienParentEnfant)
            .where(LienParentEnfant.parent_id == parent_id, LienParentEnfant.enfant_id == enfant_id)
            .with_for_update()
        )
    ).scalar_one()
    lien.etat = "revoque"
