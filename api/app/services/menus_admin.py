"""Menus côté admin : création en brouillon, modification, publication, annulation et copies.

Le menu se prépare et se publie le jeudi pour la semaine suivante : la copie d'une semaine entière est donc
le geste courant. Un menu qui porte déjà des commandes ne se modifie plus ici.
"""

import uuid
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import exists, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.erreurs import ErreurApi
from app.models import Menu, MenuPlat, Plat, Reservation, Utilisateur
from app.schemas.menus import PlatDuMenuEntree
from app.services.journal import ecrire_journal
from app.services.notifications import notifier


async def menu_par_id(session: AsyncSession, menu_id: uuid.UUID) -> Menu:
    """Charge un menu verrouillé, ou répond 404."""
    menu = await session.get(Menu, menu_id, with_for_update=True)
    if menu is None:
        raise ErreurApi("introuvable", 404)
    return menu


async def plats_du_menu(session: AsyncSession, menu_id: uuid.UUID) -> list[MenuPlat]:
    """Plats d'un menu, dans l'ordre d'affichage."""
    requete = select(MenuPlat).where(MenuPlat.menu_id == menu_id).order_by(MenuPlat.ordre)
    return list((await session.execute(requete)).scalars().all())


async def _a_des_commandes(session: AsyncSession, menu_id: uuid.UUID) -> bool:
    # Une commande annulée avant le gel ne retient plus le menu : sa part a été rendue.
    condition = (Reservation.menu_id == menu_id, Reservation.etat != "annulee")
    return bool(await session.scalar(select(exists().where(*condition))))


async def _remplacer_plats(session: AsyncSession, menu: Menu, plats: list[PlatDuMenuEntree]) -> None:
    identifiants = {p.plat_id for p in plats}
    if len(identifiants) != len(plats):
        raise ErreurApi("validation", 422)
    if identifiants:
        vivants = await session.scalars(
            select(Plat.id).where(Plat.id.in_(identifiants), Plat.supprime_le.is_(None), Plat.actif.is_(True))
        )
        if set(vivants.all()) != identifiants:
            raise ErreurApi("plat_inconnu", 422)
    for ancien in await plats_du_menu(session, menu.id):
        await session.delete(ancien)
    await session.flush()
    for plat in plats:
        session.add(MenuPlat(menu_id=menu.id, **plat.model_dump()))


def _etat(menu: Menu) -> dict[str, str]:
    return {"date_service": menu.date_service.isoformat(), "etat": menu.etat}


async def creer_menu(
    session: AsyncSession, admin_id: uuid.UUID, jour: date, plats: list[PlatDuMenuEntree], ip: str | None
) -> Menu:
    """Crée le menu d'un jour en brouillon ; 409 menu_existant si ce jour a déjà un menu."""
    menu = Menu(date_service=jour, etat="brouillon")
    session.add(menu)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("menu_existant", 409) from exc
    await _remplacer_plats(session, menu, plats)
    ecrire_journal(session, admin_id, "creation_menu", "menu", menu.id, None, _etat(menu), ip)
    return menu


async def modifier_menu(
    session: AsyncSession,
    admin_id: uuid.UUID,
    menu_id: uuid.UUID,
    plats: list[PlatDuMenuEntree],
    ip: str | None,
) -> Menu:
    """Remplace les plats d'un menu qui n'a encore aucune commande."""
    menu = await menu_par_id(session, menu_id)
    if menu.etat == "annule":
        raise ErreurApi("menu_annule", 409)
    if await _a_des_commandes(session, menu.id):
        raise ErreurApi("menu_publie", 409)
    await _remplacer_plats(session, menu, plats)
    ecrire_journal(session, admin_id, "modification_menu", "menu", menu.id, _etat(menu), _etat(menu), ip)
    return menu


async def publier_menu(
    session: AsyncSession, admin_id: uuid.UUID, menu_id: uuid.UUID, ip: str | None
) -> Menu:
    """Publie un menu qui propose au moins un plat."""
    menu = await menu_par_id(session, menu_id)
    if menu.etat == "annule":
        raise ErreurApi("menu_annule", 409)
    if not await plats_du_menu(session, menu.id):
        raise ErreurApi("menu_vide", 409)
    avant = _etat(menu)
    menu.etat = "publie"
    menu.publie_le = datetime.now(UTC)
    menu.publie_par = admin_id
    ecrire_journal(session, admin_id, "publication_menu", "menu", menu.id, avant, _etat(menu), ip)
    convives = await session.scalars(
        select(Utilisateur.id).where(
            Utilisateur.role == "convive", Utilisateur.actif.is_(True), Utilisateur.supprime_le.is_(None)
        )
    )
    await notifier(
        session,
        convives.all(),
        "menu_publie",
        {"date": menu.date_service.strftime("%d/%m")},
        {"date_service": menu.date_service.isoformat()},
    )
    return menu


async def annuler_menu(
    session: AsyncSession, admin_id: uuid.UUID, menu_id: uuid.UUID, motif: str, ip: str | None
) -> Menu:
    """Annule un menu sans commande. Le remboursement des commandes arrive avec M2 : d'ici là, 409."""
    menu = await menu_par_id(session, menu_id)
    if await _a_des_commandes(session, menu.id):
        raise ErreurApi("menu_publie", 409)
    avant = _etat(menu)
    menu.etat = "annule"
    ecrire_journal(
        session, admin_id, "annulation_menu", "menu", menu.id, avant, _etat(menu) | {"motif": motif}, ip
    )
    return menu


async def dupliquer_menu(
    session: AsyncSession, admin_id: uuid.UUID, menu_id: uuid.UUID, vers: date, ip: str | None
) -> Menu:
    """Copie les plats d'un menu vers un autre jour, en brouillon."""
    source = await menu_par_id(session, menu_id)
    plats = [
        PlatDuMenuEntree(plat_id=p.plat_id, quantite_prevue=p.quantite_prevue, ordre=p.ordre)
        for p in await plats_du_menu(session, source.id)
    ]
    return await creer_menu(session, admin_id, vers, plats, ip)


async def dupliquer_semaine(
    session: AsyncSession, admin_id: uuid.UUID, de: date, vers: date, ip: str | None
) -> tuple[list[date], list[date]]:
    """Copie chaque menu de la semaine `de` vers la semaine `vers` ; un jour déjà pris est laissé tel quel."""
    if de.weekday() != 0 or vers.weekday() != 0 or de == vers:
        raise ErreurApi("validation", 422)
    sources = (
        await session.execute(
            select(Menu).where(Menu.date_service >= de, Menu.date_service < de + timedelta(days=7))
        )
    ).scalars()
    crees, ignores = [], []
    for source in sources.all():
        if source.etat == "annule":
            continue
        cible = vers + (source.date_service - de)
        if await session.scalar(select(exists().where(Menu.date_service == cible))):
            ignores.append(cible)
            continue
        await dupliquer_menu(session, admin_id, source.id, cible, ip)
        crees.append(cible)
    return sorted(crees), sorted(ignores)
