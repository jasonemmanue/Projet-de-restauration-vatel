"""Routes /api/v1/admin/plats et /admin/tarifs : catalogue des plats, photo et prix du menu par profil.

Rôle admin vérifié sur chaque route ; chaque écriture est journalisée.
"""

import uuid

from fastapi import APIRouter, Request, UploadFile

from app.core.dependances import Admin, adresse_client
from app.db.session import SessionBase
from app.routes.menus import vue_plat
from app.schemas.catalogue import PlatEntree, PlatModification, PlatSortie, TarifEntree, TarifSortie
from app.services import catalogue

routeur = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def _vue_tarif(tarif) -> TarifSortie:
    return TarifSortie(
        id=tarif.id,
        profil=tarif.profil,
        prix_xof=tarif.prix_xof,
        actif_du=tarif.actif_du,
        actif_au=tarif.actif_au,
        menu_id=tarif.menu_id,
    )


@routeur.get("/plats", response_model=list[PlatSortie])
async def lister_plats(admin: Admin, session: SessionBase) -> list[PlatSortie]:
    """Tous les plats du catalogue, actifs ou non."""
    return [vue_plat(p) for p in await catalogue.lister_plats(session)]


@routeur.post("/plats", response_model=PlatSortie, status_code=201)
async def creer_plat(corps: PlatEntree, admin: Admin, request: Request, session: SessionBase) -> PlatSortie:
    """Crée un plat dans l'un des trois services."""
    plat = await catalogue.creer_plat(session, admin.utilisateur.id, corps, adresse_client(request))
    return vue_plat(plat)


@routeur.patch("/plats/{plat_id}", response_model=PlatSortie)
async def modifier_plat(
    plat_id: uuid.UUID, corps: PlatModification, admin: Admin, request: Request, session: SessionBase
) -> PlatSortie:
    """Modifie les champs envoyés d'un plat."""
    plat = await catalogue.modifier_plat(
        session, admin.utilisateur.id, plat_id, corps, adresse_client(request)
    )
    return vue_plat(plat)


@routeur.delete("/plats/{plat_id}")
async def retirer_plat(
    plat_id: uuid.UUID, admin: Admin, request: Request, session: SessionBase
) -> dict[str, bool]:
    """Retire un plat du catalogue, sans effacer son historique."""
    await catalogue.retirer_plat(session, admin.utilisateur.id, plat_id, adresse_client(request))
    return {"retire": True}


@routeur.put("/plats/{plat_id}/photo", response_model=PlatSortie)
async def envoyer_photo(
    plat_id: uuid.UUID, photo: UploadFile, admin: Admin, request: Request, session: SessionBase
) -> PlatSortie:
    """Range la photo d'un plat, envoyée en multipart ; son type est vérifié par ses premiers octets."""
    taille_max = request.app.state.config.taille_requete_max_octets
    contenu = await photo.read(taille_max + 1)
    plat = await catalogue.ranger_photo(
        session, admin.utilisateur.id, plat_id, contenu, taille_max, adresse_client(request)
    )
    return vue_plat(plat)


@routeur.get("/tarifs", response_model=list[TarifSortie])
async def lister_tarifs(admin: Admin, session: SessionBase) -> list[TarifSortie]:
    """Tous les tarifs, du plus récent au plus ancien par profil."""
    return [_vue_tarif(t) for t in await catalogue.lister_tarifs(session)]


@routeur.post("/tarifs", response_model=TarifSortie, status_code=201)
async def creer_tarif(
    corps: TarifEntree, admin: Admin, request: Request, session: SessionBase
) -> TarifSortie:
    """Pose un nouveau prix du menu pour un profil, à partir d'une date."""
    tarif = await catalogue.creer_tarif(session, admin.utilisateur.id, corps, adresse_client(request))
    return _vue_tarif(tarif)
