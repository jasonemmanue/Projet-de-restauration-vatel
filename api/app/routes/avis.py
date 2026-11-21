"""Routes des appréciations et suggestions : /avis, /suggestions, /admin/avis, /admin/suggestions.

Une appréciation ne se donne qu'après un repas servi, une fois par repas. Elle reste invisible des autres
tant que l'admin ne l'a pas publiée ; une note de 2 ou moins alerte l'admin. Les suggestions du jour
proposent les plats publiés les mieux notés, sans allergène déclaré par le convive.
"""

import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated, Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.dependances import Connecte, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Avis, LigneReservation, Reservation, Suggestion, Utilisateur
from app.routes.reservations import CleGeste
from app.services.menus_lecture import lire_semaine
from app.services.notifications import notifier
from app.services.regles_menus import lundi_de

routeur = APIRouter(prefix="/api/v1", tags=["avis"])
Convive = Annotated[Connecte, Depends(exiger_role("convive"))]
Lecteur = Annotated[Connecte, Depends(exiger_role("convive", "parent", "agent", "admin"))]
Note = Annotated[int, Field(ge=1, le=5)]
MOYENNE = (Avis.note_gout + Avis.note_quantite + Avis.note_temperature + Avis.note_attente) / 4.0


class AvisEntree(BaseModel):
    """Corps de POST /avis : une note par critère, de 1 à 5, sur un plat du repas servi."""

    reservation_id: uuid.UUID
    plat_id: uuid.UUID | None = None
    note_gout: Note
    note_quantite: Note
    note_temperature: Note
    note_attente: Note
    commentaire: str = Field(default="", max_length=1000)


class SuggestionEntree(BaseModel):
    """Corps de POST /suggestions."""

    message: str = Field(min_length=3, max_length=1000)
    plat_souhaite: str = Field(default="", max_length=120)


def _vue(avis: Avis) -> dict[str, Any]:
    return {
        "id": str(avis.id),
        "plat_id": str(avis.plat_id),
        "notes": {
            "gout": avis.note_gout,
            "quantite": avis.note_quantite,
            "temperature": avis.note_temperature,
            "attente": avis.note_attente,
        },
        "commentaire": avis.commentaire,
        "etat": avis.etat,
        "reponse_cantine": avis.reponse_cantine,
        "cree_le": avis.cree_le.isoformat(),
    }


@routeur.post("/avis", status_code=201)
async def donner(corps: AvisEntree, convive: Convive, cle: CleGeste, session: SessionBase) -> dict[str, Any]:
    """Note un repas servi ; un renvoi de la même clé rend la même appréciation."""
    deja = (
        await session.execute(select(Avis).where(Avis.cle_unique == f"{convive.utilisateur.id}:{cle}"))
    ).scalar()
    if deja is not None:
        return _vue(deja)
    reservation = (
        await session.execute(
            select(Reservation).where(
                Reservation.id == corps.reservation_id, Reservation.convive_id == convive.utilisateur.id
            )
        )
    ).scalar_one_or_none()
    if reservation is None:
        raise ErreurApi("introuvable", 404)
    if reservation.etat != "servie":
        raise ErreurApi("repas_non_servi", 409)
    plats = (
        await session.scalars(
            select(LigneReservation.plat_id).where(LigneReservation.reservation_id == reservation.id)
        )
    ).all()
    plat_id = corps.plat_id or next(iter(plats), None)
    if plat_id is None or plat_id not in plats:
        raise ErreurApi("validation", 422)
    avis = Avis(
        auteur_id=convive.utilisateur.id,
        plat_id=plat_id,
        reservation_id=reservation.id,
        note_gout=corps.note_gout,
        note_quantite=corps.note_quantite,
        note_temperature=corps.note_temperature,
        note_attente=corps.note_attente,
        commentaire=corps.commentaire.strip(),
        cle_unique=f"{convive.utilisateur.id}:{cle}",
    )
    session.add(avis)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("avis_existant", 409) from exc
    if min(corps.note_gout, corps.note_quantite, corps.note_temperature, corps.note_attente) <= 2:
        admins = await session.scalars(
            select(Utilisateur.id).where(Utilisateur.role == "admin", Utilisateur.actif)
        )
        await notifier(
            session,
            admins.all(),
            "message_admin",
            {"titre": "Appréciation basse", "corps": "Un convive a donné une note de 2 ou moins."},
            {"avis_id": str(avis.id)},
        )
    return _vue(avis)


@routeur.get("/avis/miens")
async def les_miens(convive: Convive, session: SessionBase) -> list[dict[str, Any]]:
    """Les appréciations du convive, avec leur état."""
    lignes = await session.scalars(
        select(Avis).where(Avis.auteur_id == convive.utilisateur.id).order_by(Avis.cree_le.desc()).limit(100)
    )
    return [_vue(a) for a in lignes.all()]


@routeur.get("/avis/plat/{plat_id}")
async def du_plat(plat_id: uuid.UUID, lecteur: Lecteur, session: SessionBase) -> dict[str, Any]:
    """Appréciations publiées d'un plat et moyennes par critère, sur les seules publiées."""
    condition = (Avis.plat_id == plat_id, Avis.etat == "publie")
    moyennes = (
        await session.execute(
            select(
                func.avg(Avis.note_gout),
                func.avg(Avis.note_quantite),
                func.avg(Avis.note_temperature),
                func.avg(Avis.note_attente),
                func.avg(MOYENNE),
                func.count(),
            ).where(*condition)
        )
    ).one()
    lignes = await session.scalars(select(Avis).where(*condition).order_by(Avis.cree_le.desc()).limit(50))

    def _arrondi(valeur: object) -> float | None:
        return round(float(valeur), 1) if valeur is not None else None

    return {
        "moyennes": {
            "gout": _arrondi(moyennes[0]),
            "quantite": _arrondi(moyennes[1]),
            "temperature": _arrondi(moyennes[2]),
            "attente": _arrondi(moyennes[3]),
            "generale": _arrondi(moyennes[4]),
        },
        "nombre": int(moyennes[5]),
        "avis": [_vue(a) | {"commentaire": a.commentaire} for a in lignes.all()],
    }


@routeur.post("/suggestions", status_code=201)
async def suggerer(corps: SuggestionEntree, convive: Convive, session: SessionBase) -> dict[str, str]:
    """Enregistre une suggestion du convive pour la cantine."""
    suggestion = Suggestion(
        auteur_id=convive.utilisateur.id, message=corps.message, plat_souhaite=corps.plat_souhaite
    )
    session.add(suggestion)
    await session.flush()
    return {"id": str(suggestion.id)}


@routeur.get("/suggestions")
async def suggestions_du_jour(convive: Convive, session: SessionBase) -> list[dict[str, Any]]:
    """Plats du prochain menu publié, les mieux notés d'abord, sans allergène déclaré par le convive."""
    aujourd_hui = datetime.now(UTC).date()
    lundi = lundi_de(aujourd_hui)
    jours = (await lire_semaine(session, lundi, convive.utilisateur)).jours
    jours += (await lire_semaine(session, lundi + timedelta(days=7), convive.utilisateur)).jours
    for jour in jours:
        if jour.date_service < aujourd_hui or jour.menu_id is None:
            continue
        plats = [p for liste in jour.services.values() for p in liste if not p.contient_allergene]
        plats.sort(key=lambda p: (p.note_moyenne or 0, p.portions_restantes), reverse=True)
        return [
            {"date_service": jour.date_service.isoformat()} | p.model_dump(mode="json") for p in plats[:5]
        ]
    return []
