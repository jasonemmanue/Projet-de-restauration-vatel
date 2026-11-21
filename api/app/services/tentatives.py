"""Compteurs d'échecs et blocages temporaires, rangés en base pour survivre aux redéploiements.

Un échec ancien de plus d'une durée de blocage est oublié : seuls les échecs rapprochés mènent au blocage.
Les écritures se font par une seule instruction INSERT ... ON CONFLICT, sûre quand deux requêtes arrivent
ensemble.
"""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy import select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Tentative


@dataclass(frozen=True)
class Seuil:
    """Nombre d'échecs permis et durée du blocage qui suit."""

    essais_max: int
    blocage: timedelta


def cle_connexion_compte(identifiant: str) -> str:
    """Clé des échecs de connexion d'un identifiant, qu'un compte existe derrière ou non."""
    return f"connexion:compte:{identifiant}"


def cle_connexion_ip(adresse: str) -> str:
    """Clé des échecs de connexion venus d'une adresse IP."""
    return f"connexion:ip:{adresse}"


def cle_codes(canal: str, identifiant: str) -> str:
    """Clé des codes faux saisis pour un identifiant."""
    return f"codes:{canal}:{identifiant}"


async def bloque_jusqua(session: AsyncSession, cle: str) -> datetime | None:
    """Rend la fin du blocage en cours pour cette clé, ou None si rien ne bloque."""
    fin = (await session.execute(select(Tentative.bloque_jusqua).where(Tentative.cle == cle))).scalar()
    if fin is not None and fin > datetime.now(UTC):
        return fin
    return None


async def compter_echec(session: AsyncSession, cle: str, seuil: Seuil) -> bool:
    """Ajoute un échec et bloque la clé au seuil atteint ; rend vrai si la clé vient d'être bloquée."""
    resultat = await session.execute(
        text(
            """
            INSERT INTO tentatives (cle, echecs, dernier_echec_le)
            VALUES (:cle, 1, now())
            ON CONFLICT (cle) DO UPDATE SET
                echecs = CASE
                    WHEN tentatives.dernier_echec_le < now() - CAST(:fenetre AS interval) THEN 1
                    ELSE tentatives.echecs + 1
                END,
                dernier_echec_le = now(),
                modifie_le = now()
            RETURNING echecs
            """
        ),
        {"cle": cle, "fenetre": seuil.blocage},
    )
    echecs = int(resultat.scalar_one())
    if echecs < seuil.essais_max:
        return False
    await session.execute(
        update(Tentative)
        .where(Tentative.cle == cle)
        .values(bloque_jusqua=datetime.now(UTC) + seuil.blocage, echecs=0)
    )
    return True


async def oublier(session: AsyncSession, cle: str) -> None:
    """Efface les échecs d'une clé après une réussite."""
    await session.execute(update(Tentative).where(Tentative.cle == cle).values(echecs=0, bloque_jusqua=None))
