"""Routes /api/v1/admin/menus : semaine de l'admin, création, modification, publication, annulation, copies.

Rôle admin vérifié sur chaque route ; chaque écriture est journalisée.
"""

import uuid
from datetime import UTC, date, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Query, Request

from app.core.dependances import Admin, adresse_client
from app.db.session import SessionBase
from app.models import Menu
from app.schemas.menus import (
    AnnulationEntree,
    DuplicationEntree,
    DuplicationSemaineEntree,
    DuplicationSemaineSortie,
    MenuAdminSortie,
    MenuEntree,
    MenuModification,
    PlatDuMenuEntree,
    SemaineSortie,
)
from app.services import menus_admin
from app.services.menus_lecture import lire_semaine
from app.services.regles_menus import lundi_de

routeur = APIRouter(prefix="/api/v1/admin/menus", tags=["admin"])


async def _vue(session: SessionBase, menu: Menu) -> MenuAdminSortie:
    plats = await menus_admin.plats_du_menu(session, menu.id)
    return MenuAdminSortie(
        id=menu.id,
        date_service=menu.date_service,
        etat=menu.etat,
        publie_le=menu.publie_le,
        plats=[
            PlatDuMenuEntree(plat_id=p.plat_id, quantite_prevue=p.quantite_prevue, ordre=p.ordre)
            for p in plats
        ],
    )


@routeur.get("", response_model=SemaineSortie)
async def semaine_admin(
    admin: Admin, session: SessionBase, du: Annotated[date | None, Query()] = None
) -> SemaineSortie:
    """La semaine à préparer, brouillons compris ; par défaut la semaine prochaine, publiée le jeudi."""
    debut = lundi_de(du) if du else lundi_de(datetime.now(UTC).date()) + timedelta(days=7)
    return await lire_semaine(session, debut, admin.utilisateur, avec_brouillons=True)


@routeur.post("", response_model=MenuAdminSortie, status_code=201)
async def creer_menu(
    corps: MenuEntree, admin: Admin, request: Request, session: SessionBase
) -> MenuAdminSortie:
    """Crée le menu d'un jour, en brouillon."""
    menu = await menus_admin.creer_menu(
        session, admin.utilisateur.id, corps.date_service, corps.plats, adresse_client(request)
    )
    return await _vue(session, menu)


# Déclarée avant les routes en /{menu_id} : sinon « semaine » serait lu comme un identifiant de menu.
@routeur.post("/semaine/dupliquer", response_model=DuplicationSemaineSortie)
async def dupliquer_semaine(
    corps: DuplicationSemaineEntree, admin: Admin, request: Request, session: SessionBase
) -> DuplicationSemaineSortie:
    """Copie une semaine entière, du lundi `de` vers le lundi `vers`, en brouillons."""
    crees, ignores = await menus_admin.dupliquer_semaine(
        session, admin.utilisateur.id, corps.de, corps.vers, adresse_client(request)
    )
    return DuplicationSemaineSortie(crees=crees, ignores=ignores)


@routeur.patch("/{menu_id}", response_model=MenuAdminSortie)
async def modifier_menu(
    menu_id: uuid.UUID, corps: MenuModification, admin: Admin, request: Request, session: SessionBase
) -> MenuAdminSortie:
    """Remplace les plats d'un menu sans commande."""
    menu = await menus_admin.modifier_menu(
        session, admin.utilisateur.id, menu_id, corps.plats, adresse_client(request)
    )
    return await _vue(session, menu)


@routeur.post("/{menu_id}/publier", response_model=MenuAdminSortie)
async def publier_menu(
    menu_id: uuid.UUID, admin: Admin, request: Request, session: SessionBase
) -> MenuAdminSortie:
    """Publie un menu : les convives le voient et peuvent commander."""
    menu = await menus_admin.publier_menu(session, admin.utilisateur.id, menu_id, adresse_client(request))
    return await _vue(session, menu)


@routeur.post("/{menu_id}/annuler", response_model=MenuAdminSortie)
async def annuler_menu(
    menu_id: uuid.UUID, corps: AnnulationEntree, admin: Admin, request: Request, session: SessionBase
) -> MenuAdminSortie:
    """Annule un menu sans commande."""
    menu = await menus_admin.annuler_menu(
        session, admin.utilisateur.id, menu_id, corps.motif, adresse_client(request)
    )
    return await _vue(session, menu)


@routeur.post("/{menu_id}/dupliquer", response_model=MenuAdminSortie, status_code=201)
async def dupliquer_menu(
    menu_id: uuid.UUID, corps: DuplicationEntree, admin: Admin, request: Request, session: SessionBase
) -> MenuAdminSortie:
    """Copie un menu vers un autre jour, en brouillon."""
    menu = await menus_admin.dupliquer_menu(
        session, admin.utilisateur.id, menu_id, corps.vers_date, adresse_client(request)
    )
    return await _vue(session, menu)
