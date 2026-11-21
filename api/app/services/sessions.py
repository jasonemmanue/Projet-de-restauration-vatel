"""Sessions ouvertes par appareil : ouverture, rafraîchissement avec remplacement du jeton, révocation."""

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.core.hachage import hmac_hex
from app.core.jetons import creer_jeton_acces, nouveau_jeton_rafraichissement
from app.models import SessionAppareil, Utilisateur


@dataclass(frozen=True)
class Appareil:
    """Appareil déclaré par le client à l'ouverture d'une session."""

    nom: str
    plateforme: str


@dataclass(frozen=True)
class Jetons:
    """Jetons remis au client : accès court et rafraîchissement long."""

    jeton: str
    jeton_rafraichissement: str
    expire_dans: int


def _jetons(config: Configuration, utilisateur_id: uuid.UUID, session_id: uuid.UUID, brut: str) -> Jetons:
    duree = timedelta(minutes=config.jwt_duree_minutes)
    return Jetons(
        jeton=creer_jeton_acces(config.secret_key, utilisateur_id, session_id, duree),
        jeton_rafraichissement=brut,
        expire_dans=int(duree.total_seconds()),
    )


async def ouvrir_session(
    session: AsyncSession, config: Configuration, utilisateur: Utilisateur, appareil: Appareil, ip: str | None
) -> Jetons:
    """Ouvre une session pour un appareil et rend ses jetons."""
    brut = nouveau_jeton_rafraichissement()
    ligne = SessionAppareil(
        utilisateur_id=utilisateur.id,
        jeton_rafraichissement_hache=hmac_hex(config.secret_key, brut),
        appareil_nom=appareil.nom,
        plateforme=appareil.plateforme,
        adresse_ip=ip,
        expire_le=datetime.now(UTC) + timedelta(days=config.jwt_rafraichissement_jours),
    )
    session.add(ligne)
    await session.flush()
    return _jetons(config, utilisateur.id, ligne.id, brut)


async def rafraichir(session: AsyncSession, config: Configuration, brut: str) -> Jetons:
    """Échange un jeton de rafraîchissement contre de nouveaux jetons ; l'ancien ne sert plus jamais.

    La ligne est verrouillée : deux rafraîchissements simultanés du même jeton ne peuvent pas réussir tous
    les deux.
    """
    hache = hmac_hex(config.secret_key, brut)
    ligne = (
        await session.execute(
            select(SessionAppareil)
            .where(SessionAppareil.jeton_rafraichissement_hache == hache)
            .with_for_update()
        )
    ).scalar_one_or_none()
    maintenant = datetime.now(UTC)
    if ligne is None or ligne.expire_le <= maintenant:
        raise ErreurApi("jeton_invalide", 401)
    if ligne.revoquee_le is not None:
        raise ErreurApi("session_revoquee", 401)
    utilisateur = await session.get(Utilisateur, ligne.utilisateur_id)
    if utilisateur is None or not utilisateur.actif or utilisateur.supprime_le is not None:
        raise ErreurApi("jeton_invalide", 401)
    nouveau = nouveau_jeton_rafraichissement()
    ligne.jeton_rafraichissement_hache = hmac_hex(config.secret_key, nouveau)
    ligne.derniere_activite = maintenant
    ligne.expire_le = maintenant + timedelta(days=config.jwt_rafraichissement_jours)
    return _jetons(config, utilisateur.id, ligne.id, nouveau)


async def revoquer_session(session: AsyncSession, session_id: uuid.UUID) -> None:
    """Ferme une session."""
    await session.execute(
        update(SessionAppareil)
        .where(SessionAppareil.id == session_id, SessionAppareil.revoquee_le.is_(None))
        .values(revoquee_le=datetime.now(UTC))
    )


async def revoquer_toutes(
    session: AsyncSession, utilisateur_id: uuid.UUID, sauf: uuid.UUID | None = None
) -> None:
    """Ferme toutes les sessions d'un utilisateur, sauf éventuellement la session courante."""
    condition = [SessionAppareil.utilisateur_id == utilisateur_id, SessionAppareil.revoquee_le.is_(None)]
    if sauf is not None:
        condition.append(SessionAppareil.id != sauf)
    await session.execute(update(SessionAppareil).where(*condition).values(revoquee_le=datetime.now(UTC)))
