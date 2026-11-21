"""Routes /api/v1/admin/journal, /admin/etat et /admin/utilisateurs/{id}/verification.

Le journal rend les actions de l'admin avec leur état avant et après. L'état des services dit ce qui est
branché, sans jamais montrer une valeur secrète. Valider un compte à la main ou le repasser en non vérifié
exige un motif et le mot de passe des actions, et laisse une ligne au journal.
"""

import uuid
from datetime import UTC, datetime
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import func, select, text
from sqlalchemy.orm import undefer

from app import __version__
from app.core.dependances import Admin, AdminAvecActions, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import JournalAdmin, Utilisateur
from app.services import gmail, paiements, sessions
from app.services.journal import ecrire_journal
from app.services.parametres import lire_parametres

routeur = APIRouter(prefix="/api/v1/admin", tags=["admin"])


class VerificationEntree(BaseModel):
    """Corps de POST /admin/utilisateurs/{id}/verification."""

    action: Literal["valider", "invalider"]
    motif: str = Field(min_length=3, max_length=300)


@routeur.get("/journal")
async def journal(
    admin: Admin,
    session: SessionBase,
    cible_type: Annotated[str | None, Query(max_length=40)] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    taille: Annotated[int, Query(ge=1, le=100)] = 50,
) -> dict[str, Any]:
    """Les actions de l'admin, les plus récentes d'abord, avec l'état avant et après."""
    condition = [JournalAdmin.cible_type == cible_type] if cible_type else []
    total = await session.scalar(select(func.count()).select_from(JournalAdmin).where(*condition))
    lignes = await session.execute(
        select(JournalAdmin, Utilisateur.nom_complet)
        .join(Utilisateur, Utilisateur.id == JournalAdmin.admin_id)
        .where(*condition)
        .options(undefer(JournalAdmin.avant), undefer(JournalAdmin.apres))
        .order_by(JournalAdmin.cree_le.desc())
        .offset((page - 1) * taille)
        .limit(taille)
    )
    elements = [
        {
            "id": str(ligne.id),
            "admin": nom,
            "action": ligne.action,
            "cible_type": ligne.cible_type,
            "cible_id": str(ligne.cible_id) if ligne.cible_id else None,
            "avant": ligne.avant,
            "apres": ligne.apres,
            "cree_le": ligne.cree_le.isoformat(),
        }
        for ligne, nom in lignes.all()
    ]
    return {"elements": elements, "page": page, "taille": taille, "total": int(total or 0)}


@routeur.get("/etat")
async def etat(admin: Admin, request: Request, session: SessionBase) -> dict[str, Any]:
    """Ce qui est branché : base, version, mode de paiement, clés, e-mail, notifications, vérification."""
    config = request.app.state.config
    base_ok = (await session.scalar(text("select 1"))) == 1
    reglages = await lire_parametres(
        session, "mode_paiement", "livraison_verification_email", "livraison_verification_telephone"
    )
    return {
        "version": __version__,
        "commit": config.commit,
        "base": "ok" if base_ok else "indisponible",
        "mode_paiement": reglages["mode_paiement"],
        "geniuspay_test": all(paiements.cles_du_mode(config, "test"))
        and bool(config.geniuspay_secret_webhook_test),
        "geniuspay_reel": all(paiements.cles_du_mode(config, "reel"))
        and bool(config.geniuspay_secret_webhook_reel),
        "email": {
            "livraison": reglages["livraison_verification_email"],
            "gmail_configure": gmail.configure(config),
        },
        "telephone": {"livraison": reglages["livraison_verification_telephone"]},
        "notifications_push": config.fcm_actif and bool(config.firebase_compte_service),
    }


@routeur.post("/utilisateurs/{utilisateur_id}/verification")
async def verification(
    utilisateur_id: uuid.UUID,
    corps: VerificationEntree,
    admin: AdminAvecActions,
    request: Request,
    session: SessionBase,
) -> dict[str, bool]:
    """Valide un compte à la main, ou le repasse en non vérifié ; ses sessions sont alors fermées."""
    cible = await session.get(Utilisateur, utilisateur_id, with_for_update=True)
    if cible is None or cible.supprime_le is not None:
        raise ErreurApi("introuvable", 404)
    if cible.id == admin.utilisateur.id:
        raise ErreurApi("conflit", 409)
    avant = {
        "email_verifie": cible.email_verifie_le is not None,
        "telephone_verifie": cible.telephone_verifie_le is not None,
    }
    maintenant = datetime.now(UTC)
    if corps.action == "valider":
        if cible.email and cible.email_verifie_le is None:
            cible.email_verifie_le = maintenant
        if cible.telephone and cible.telephone_verifie_le is None:
            cible.telephone_verifie_le = maintenant
    else:
        cible.email_verifie_le = None
        cible.telephone_verifie_le = None
        await sessions.revoquer_toutes(session, cible.id)
    apres = {
        "email_verifie": cible.email_verifie_le is not None,
        "telephone_verifie": cible.telephone_verifie_le is not None,
        "motif": corps.motif,
    }
    ecrire_journal(
        session,
        admin.utilisateur.id,
        f"verification_{corps.action}",
        "utilisateur",
        cible.id,
        avant,
        apres,
        adresse_client(request),
    )
    return {"verifie": corps.action == "valider"}
