"""Codes de vérification : l'API tire et contrôle toujours le code, seule sa livraison change par canal.

En livraison « demo », le code revient dans la réponse. En « reel », il ne revient jamais ; l'envoi réel
par e-mail arrive à l'étape E1. Un code est aussi tiré, sans jamais être rendu, pour un identifiant sans
compte : les limites et la réponse sont alors les mêmes que le compte existe ou non.

Un échec compté puis signalé est validé avant l'erreur : sinon l'annulation de la requête l'effacerait.
"""

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Configuration
from app.core.erreurs import ErreurApi
from app.core.hachage import egal_en_temps_constant, hmac_hex
from app.models import CodeVerification, JournalVerification
from app.services import gmail, tentatives
from app.services.parametres import lire_parametres
from app.services.regles_comptes import (
    CANAL_EMAIL,
    Identifiant,
    generer_code,
    masquer_identifiant,
    normaliser_code,
)

USAGE_VERIFICATION = "verification_compte"
USAGE_REINITIALISATION = "reinitialisation_mot_de_passe"
USAGE_RECONNEXION = "reconnexion"
JOUR = timedelta(days=1)


@dataclass(frozen=True)
class CodeEnvoye:
    """Réponse d'une demande de code ; `code_demo` n'existe qu'en livraison démo pour un compte réel."""

    mode_livraison: str
    expire_le: datetime
    code_demo: str | None
    canal: str


def _empreinte(config: Configuration, identifiant: Identifiant, code: str) -> str:
    return hmac_hex(config.secret_key, f"{identifiant.canal}:{identifiant.valeur}:{code}")


def _journal(
    identifiant: Identifiant, etape: str, ip: str | None, mode: str | None, raison: str | None = None
):
    return JournalVerification(
        identifiant_masque=masquer_identifiant(identifiant),
        canal=identifiant.canal,
        etape=etape,
        raison=raison,
        mode_livraison=mode,
        adresse_ip=ip,
    )


async def _refuser(session: AsyncSession, code: str, statut: int) -> None:
    await session.commit()
    raise ErreurApi(code, statut)


async def demander_code(
    session: AsyncSession,
    config: Configuration,
    identifiant: Identifiant,
    usage: str,
    ip: str | None,
    destinataire_id: uuid.UUID | None = None,
) -> CodeEnvoye:
    """Tire un nouveau code pour un identifiant, après contrôle des limites ; annule les codes précédents."""
    canal = identifiant.canal
    cle_duree = "duree_code_email_minutes" if canal == CANAL_EMAIL else "duree_code_verification_minutes"
    reglages = await lire_parametres(
        session,
        f"livraison_verification_{canal}",
        cle_duree,
        "intervalle_codes_secondes",
        "codes_par_jour_max",
        "demandes_codes_ip_jour_max",
        "essais_code_max",
    )
    mode = str(reglages[f"livraison_verification_{canal}"])
    session.add(_journal(identifiant, "demande", ip, mode))
    if await tentatives.bloque_jusqua(session, tentatives.cle_codes(canal, identifiant.valeur)):
        await _refuser(session, "trop_essais", 429)

    maintenant = datetime.now(UTC)
    if ip is not None:
        demandes_ip = await session.scalar(
            select(func.count())
            .select_from(JournalVerification)
            .where(
                JournalVerification.adresse_ip == ip,
                JournalVerification.etape == "demande",
                JournalVerification.cree_le > maintenant - JOUR,
            )
        )
        if int(demandes_ip or 0) >= int(reglages["demandes_codes_ip_jour_max"]):
            await _refuser(session, "trop_de_requetes", 429)

    recents = select(CodeVerification.cree_le).where(
        CodeVerification.identifiant_vise == identifiant.valeur,
        CodeVerification.canal == canal,
        CodeVerification.cree_le > maintenant - JOUR,
    )
    dates = (await session.execute(recents)).scalars().all()
    intervalle = timedelta(seconds=int(reglages["intervalle_codes_secondes"]))
    if len(dates) >= int(reglages["codes_par_jour_max"]) or any(d > maintenant - intervalle for d in dates):
        await _refuser(session, "trop_de_requetes", 429)

    if mode != "demo" and canal != CANAL_EMAIL:
        # Le téléphone n'a pas de livraison réelle : on refuse plutôt que de prétendre avoir envoyé.
        session.add(_journal(identifiant, "echec", ip, mode, "envoi_impossible"))
        await _refuser(session, "envoi_impossible", 502)

    await session.execute(
        update(CodeVerification)
        .where(
            CodeVerification.identifiant_vise == identifiant.valeur,
            CodeVerification.canal == canal,
            CodeVerification.usage == usage,
            CodeVerification.utilise_le.is_(None),
            CodeVerification.expire_le > maintenant,
        )
        .values(expire_le=maintenant)
    )
    code = generer_code(canal)
    expire_le = maintenant + timedelta(minutes=int(reglages[cle_duree]))
    session.add(
        CodeVerification(
            utilisateur_id=destinataire_id,
            identifiant_vise=identifiant.valeur,
            canal=canal,
            code_hache=_empreinte(config, identifiant, code),
            origine="api",
            usage=usage,
            mode_livraison=mode,
            essais_max=int(reglages["essais_code_max"]),
            expire_le=expire_le,
        )
    )
    session.add(_journal(identifiant, "envoye", ip, mode))
    if mode == "reel" and destinataire_id is not None:
        minutes = int(reglages[cle_duree])

        async def _envoyer() -> None:
            application = session.info.get("application")
            if application is not None:
                await gmail.envoyer_code(
                    application.state.client_http, config, identifiant.valeur, usage, code, minutes, "fr"
                )

        session.info.setdefault("apres_validation", []).append(_envoyer)
    rendu = code if destinataire_id is not None and mode == "demo" else None
    return CodeEnvoye(mode, expire_le, rendu, canal)


async def controler_code(
    session: AsyncSession,
    config: Configuration,
    identifiant: Identifiant,
    usage: str,
    saisie: str,
    ip: str | None,
) -> CodeVerification:
    """Contrôle un code saisi et le consomme ; au seuil de codes faux, l'identifiant est bloqué un temps."""
    cle = tentatives.cle_codes(identifiant.canal, identifiant.valeur)
    if await tentatives.bloque_jusqua(session, cle):
        await _refuser(session, "trop_essais", 429)
    reglages = await lire_parametres(session, "essais_code_max", "blocage_codes_minutes")
    seuil = tentatives.Seuil(
        int(reglages["essais_code_max"]), timedelta(minutes=int(reglages["blocage_codes_minutes"]))
    )
    ligne = (
        await session.execute(
            select(CodeVerification)
            .where(
                CodeVerification.identifiant_vise == identifiant.valeur,
                CodeVerification.canal == identifiant.canal,
                CodeVerification.usage == usage,
                CodeVerification.utilise_le.is_(None),
            )
            .order_by(CodeVerification.cree_le.desc())
            .limit(1)
            .with_for_update()
        )
    ).scalar_one_or_none()
    maintenant = datetime.now(UTC)
    if ligne is not None and ligne.expire_le <= maintenant:
        session.add(_journal(identifiant, "echec", ip, ligne.mode_livraison, "expire"))
        await _refuser(session, "code_expire", 410)
    attendu = ligne.code_hache if ligne is not None else ""
    juste = egal_en_temps_constant(attendu, _empreinte(config, identifiant, normaliser_code(saisie)))
    if ligne is None or not juste or ligne.utilisateur_id is None:
        if ligne is not None:
            ligne.essais += 1
        bloque = await tentatives.compter_echec(session, cle, seuil)
        raison = "trop_essais" if bloque else "code_faux"
        session.add(_journal(identifiant, "echec", ip, ligne.mode_livraison if ligne else None, raison))
        await _refuser(session, "code_invalide", 400)
    ligne.utilise_le = maintenant
    await tentatives.oublier(session, cle)
    session.add(_journal(identifiant, "verifie", ip, ligne.mode_livraison))
    return ligne
