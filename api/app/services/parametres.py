"""Lecture des réglages de la table parametres, seule source des valeurs métier modifiables."""

from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Parametre


class ParametreManquantError(LookupError):
    """Un réglage attendu n'existe pas : la migration qui le crée n'a pas été appliquée."""


async def lire_parametres(session: AsyncSession, *cles: str) -> dict[str, Any]:
    """Lit plusieurs réglages d'un coup ; échoue si l'un d'eux manque plutôt que d'inventer une valeur."""
    lignes = await session.execute(select(Parametre.cle, Parametre.valeur).where(Parametre.cle.in_(cles)))
    valeurs = {cle: valeur for cle, valeur in lignes.all()}
    manquants = [cle for cle in cles if cle not in valeurs]
    if manquants:
        raise ParametreManquantError(", ".join(manquants))
    return valeurs


async def lire_entier(session: AsyncSession, cle: str) -> int:
    """Lit un réglage entier."""
    return int((await lire_parametres(session, cle))[cle])
