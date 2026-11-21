"""Porte-monnaie : le solde n'existe que par la somme de ses mouvements.

Toute écriture verrouille d'abord la ligne du porte-monnaie (SELECT ... FOR UPDATE), ce qui range les gestes
d'argent d'un même compte l'un après l'autre. Le solde de lecture rapide est recalculé depuis les mouvements
dans la même transaction, puis relu pour vérification.
"""

import uuid
from datetime import UTC, datetime

from sqlalchemy import case, func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.models import Mouvement, PorteMonnaie
from app.services.regles_commandes import solde_apres


async def verrouiller(session: AsyncSession, utilisateur_id: uuid.UUID) -> PorteMonnaie:
    """Rend le porte-monnaie du compte, créé au besoin, verrouillé jusqu'à la fin de la transaction."""
    await session.execute(
        insert(PorteMonnaie)
        .values(utilisateur_id=utilisateur_id)
        .on_conflict_do_nothing(index_elements=["utilisateur_id"])
    )
    requete = select(PorteMonnaie).where(PorteMonnaie.utilisateur_id == utilisateur_id).with_for_update()
    return (await session.execute(requete)).scalar_one()


async def solde_reel(session: AsyncSession, porte_monnaie_id: uuid.UUID) -> int:
    """Somme des mouvements : crédits moins débits."""
    signe = case((Mouvement.sens == "credit", Mouvement.montant_xof), else_=-Mouvement.montant_xof)
    total = await session.scalar(
        select(func.coalesce(func.sum(signe), 0)).where(Mouvement.porte_monnaie_id == porte_monnaie_id)
    )
    return int(total or 0)


async def mouvement_existant(session: AsyncSession, cle_unique: str) -> Mouvement | None:
    """Mouvement déjà écrit pour cette clé, s'il existe : un renvoi ne crée rien de plus."""
    return (
        await session.execute(select(Mouvement).where(Mouvement.cle_unique == cle_unique))
    ).scalar_one_or_none()


async def ecrire(
    session: AsyncSession,
    porte_monnaie: PorteMonnaie,
    sens: str,
    montant: int,
    motif: str,
    cle_unique: str,
    reference_type: str | None = None,
    reference_id: uuid.UUID | None = None,
    cree_par: uuid.UUID | None = None,
) -> Mouvement:
    """Écrit un mouvement sur un porte-monnaie déjà verrouillé ; 402 si un débit dépasse le solde."""
    if porte_monnaie.gele and sens == "debit":
        raise ErreurApi("porte_monnaie_gele", 409)
    solde = await solde_reel(session, porte_monnaie.id)
    apres = solde_apres(solde, sens, montant)
    if apres < 0:
        raise ErreurApi("solde_insuffisant", 402)
    mouvement = Mouvement(
        porte_monnaie_id=porte_monnaie.id,
        sens=sens,
        montant_xof=montant,
        motif=motif,
        reference_type=reference_type,
        reference_id=reference_id,
        solde_apres_xof=apres,
        cle_unique=cle_unique,
        cree_par=cree_par,
    )
    session.add(mouvement)
    await session.flush()
    relu = await solde_reel(session, porte_monnaie.id)
    if relu != apres:
        # Ne devrait jamais arriver sous verrou : on préfère tout annuler qu'écrire un solde faux.
        raise ErreurApi("erreur_serveur", 500)
    porte_monnaie.solde_cache_xof = relu
    porte_monnaie.recalcule_le = datetime.now(UTC)
    return mouvement
