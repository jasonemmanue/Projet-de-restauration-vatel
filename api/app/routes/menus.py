"""Routes de lecture des menus et des plats : /api/v1/menus/semaine, /menus/{date}, /plats/{id}.

Réservées aux comptes vérifiés ; seuls les menus publiés sont visibles. La photo d'un plat est publique :
elle ne dit rien de personne et s'affiche sans jeton dans une balise d'image.
"""

import uuid
from datetime import UTC, date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy import func, select

from app.core.dependances import Connecte, exiger_role
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Avis
from app.schemas.catalogue import PlatSortie
from app.schemas.menus import JourSortie, SemaineSortie
from app.services import catalogue
from app.services.menus_lecture import debut_par_defaut, lire_semaine
from app.services.regles_menus import lundi_de

routeur = APIRouter(prefix="/api/v1", tags=["menus"])
Lecteur = Annotated[Connecte, Depends(exiger_role("convive", "parent", "agent", "admin"))]


def vue_plat(plat) -> PlatSortie:
    """Vue d'un plat du catalogue."""
    return PlatSortie(
        id=plat.id,
        nom_fr=plat.nom_fr,
        nom_en=plat.nom_en,
        description_fr=plat.description_fr,
        description_en=plat.description_en,
        categorie=plat.categorie,
        allergenes=plat.allergenes,
        regimes=plat.regimes,
        calories=plat.calories,
        prix_supplement_xof=plat.prix_supplement_xof,
        image_url=catalogue.chemin_photo(plat),
        actif=plat.actif,
    )


@routeur.get("/menus/semaine", response_model=SemaineSortie)
async def menus_semaine(
    lecteur: Lecteur, session: SessionBase, du: Annotated[date | None, Query()] = None
) -> SemaineSortie:
    """Les sept jours à partir du lundi qui contient `du` (la semaine en cours par défaut)."""
    debut = lundi_de(du) if du else debut_par_defaut(datetime.now(UTC).date())
    return await lire_semaine(session, debut, lecteur.utilisateur)


@routeur.get("/menus/{jour}", response_model=JourSortie)
async def menu_du_jour(jour: date, lecteur: Lecteur, session: SessionBase) -> JourSortie:
    """Le menu publié d'un jour ; 404 si ce jour n'en a pas."""
    semaine = await lire_semaine(session, lundi_de(jour), lecteur.utilisateur)
    trouve = next(j for j in semaine.jours if j.date_service == jour)
    if trouve.menu_id is None:
        raise ErreurApi("introuvable", 404)
    return trouve


@routeur.get("/plats/{plat_id}")
async def lire_plat(plat_id: uuid.UUID, lecteur: Lecteur, session: SessionBase) -> dict:
    """Un plat, avec sa note moyenne et le nombre d'avis publiés."""
    plat = await catalogue.plat_vivant(session, plat_id)
    moyenne, nombre = (
        await session.execute(
            select(
                func.avg(
                    (Avis.note_gout + Avis.note_quantite + Avis.note_temperature + Avis.note_attente) / 4.0
                ),
                func.count(Avis.id),
            ).where(Avis.plat_id == plat.id, Avis.etat == "publie")
        )
    ).one()
    return vue_plat(plat).model_dump(mode="json") | {
        "note_moyenne": round(float(moyenne), 1) if moyenne is not None else None,
        "nombre_avis": int(nombre),
    }


@routeur.get("/plats/{plat_id}/photo", include_in_schema=True)
async def photo_du_plat(plat_id: uuid.UUID, session: SessionBase) -> Response:
    """La photo d'un plat, publique, mise en cache une heure."""
    contenu, type_mime = await catalogue.lire_photo(session, plat_id)
    return Response(content=contenu, media_type=type_mime, headers={"Cache-Control": "public, max-age=3600"})
