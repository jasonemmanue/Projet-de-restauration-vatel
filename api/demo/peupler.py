"""Jeu de démonstration, idempotent : python -m demo.peupler depuis api/, avec les variables de l'API.

Crée, s'ils n'existent pas : un admin et deux convives déjà vérifiés, les plats ivoiriens avec leurs photos du
volume (/medias/demo/...), les menus publiés de cette semaine et de la suivante, 14 jours d'historique et des
soldes crédités. Un second lancement ne crée rien de plus.

Les mots de passe sont tirés au hasard et affichés une seule fois dans le terminal de l'exploitant : le dépôt
est public, ils ne sont jamais écrits dans un fichier.
"""

import asyncio
import random
import secrets
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import func, select

from app.core.config import lire_configuration
from app.db.moteur import creer_fabrique, creer_moteur
from app.models import LigneReservation, LotReservation, Menu, MenuPlat, Plat, Reservation
from app.services import comptes, porte_monnaie
from app.services.regles_comptes import Identifiant

COMPTES = (
    ("demo-admin@vatel.demo", "Awa", "Admin", "admin", None),
    ("demo-eleve@vatel.demo", "Koffi", "N'Guessan", "convive", "eleve"),
    ("demo-employe@vatel.demo", "Aminata", "Traoré", "convive", "employe"),
)
# (nom français, nom anglais, service, image du volume ou None, prix d'une part en plus)
PLATS = (
    ("Alloco", "Fried plantain", "entree", "alloco.jpg", 300),
    ("Brochettes", "Skewers", "entree", "brochettes.jpg", 500),
    ("Attiéké poisson", "Attieke with fish", "resistance", "attieke-poisson.jpg", 1000),
    ("Kédjénou de poulet", "Chicken kedjenou", "resistance", "kedjenou.jpg", 1200),
    ("Foutou sauce graine", "Foutou with palm nut sauce", "resistance", "foutou-sauce-graine.jpg", 1000),
    ("Foutou sauce arachide", "Foutou with peanut sauce", "resistance", "foutou-sauce-arachide.jpg", 1000),
    ("Riz gras", "Jollof rice", "resistance", "riz-gras.jpg", 800),
    ("Poulet braisé", "Grilled chicken", "resistance", "poulet-braise.jpg", 1200),
    ("Poisson braisé", "Grilled fish", "resistance", "poisson-braise.jpg", 1200),
    ("Sauce graine au crabe", "Palm nut sauce with crab", "resistance", "sauce-graine-crabe.jpg", 1500),
    ("Foufou sauce gombo", "Foufou with okra sauce", "resistance", "foufou-sauce-gombo.jpg", 1000),
    ("Foutou placali", "Foutou and placali", "resistance", "foutou-placali.jpg", 1000),
    ("Salade de fruits", "Fruit salad", "sortie", None, 300),
    ("Dêguê", "Millet yoghurt", "sortie", None, 300),
    ("Banane douce", "Sweet banana", "sortie", None, 200),
)
CREDIT_INITIAL = 60_000
JOURS_HISTORIQUE = 14


async def _comptes(session, config) -> dict[str, object]:
    trouves = {}
    for email, prenom, nom, role, statut in COMPTES:
        identifiant = Identifiant("email", email)
        utilisateur = await comptes.trouver(session, identifiant)
        if utilisateur is None:
            mot_de_passe = "Vatel" + secrets.token_hex(5) + "7"
            donnees = comptes.NouveauCompte(identifiant, mot_de_passe, prenom, nom, role, statut)
            utilisateur = await comptes.creer_compte(
                session, config, donnees, verifie=True, consentement=True
            )
            print(f"  créé    {email:28} mot de passe : {mot_de_passe}")
        else:
            print(f"  existe  {email:28} mot de passe inchangé")
        trouves[email] = utilisateur
    return trouves


async def _plats(session) -> dict[str, list[Plat]]:
    par_service: dict[str, list[Plat]] = {"entree": [], "resistance": [], "sortie": []}
    for nom_fr, nom_en, service, image, supplement in PLATS:
        plat = (
            await session.execute(
                select(Plat).where(func.lower(Plat.nom_fr) == nom_fr.lower(), Plat.supprime_le.is_(None))
            )
        ).scalar_one_or_none()
        if plat is None:
            plat = Plat(
                nom_fr=nom_fr,
                nom_en=nom_en,
                categorie=service,
                prix_supplement_xof=supplement,
                image_url=f"/medias/demo/{image}" if image else None,
                photo_type="image/jpeg" if image else None,
            )
            session.add(plat)
            await session.flush()
        par_service[service].append(plat)
    return par_service


async def _menu(session, jour: date, plats: dict[str, list[Plat]], hasard: random.Random) -> Menu:
    menu = (await session.execute(select(Menu).where(Menu.date_service == jour))).scalar_one_or_none()
    if menu is not None:
        return menu
    menu = Menu(date_service=jour, etat="publie", publie_le=datetime.now(UTC))
    session.add(menu)
    await session.flush()
    choix = (
        hasard.sample(plats["entree"], 2)
        + hasard.sample(plats["resistance"], 4)
        + hasard.sample(plats["sortie"], 2)
    )
    for ordre, plat in enumerate(choix):
        session.add(MenuPlat(menu_id=menu.id, plat_id=plat.id, quantite_prevue=80, ordre=ordre))
    await session.flush()
    return menu


async def _historique(session, convive, menu: Menu, prix: int, hasard: random.Random) -> None:
    deja = await session.scalar(
        select(func.count())
        .select_from(Reservation)
        .where(Reservation.convive_id == convive.id, Reservation.date_service == menu.date_service)
    )
    if deja:
        return
    offres = (
        (
            await session.execute(
                select(Plat).join(MenuPlat, MenuPlat.plat_id == Plat.id).where(MenuPlat.menu_id == menu.id)
            )
        )
        .scalars()
        .all()
    )
    resistance = hasard.choice([p for p in offres if p.categorie == "resistance"])
    entree = hasard.choice([p for p in offres if p.categorie == "entree"])
    portefeuille = await porte_monnaie.verrouiller(session, convive.id)
    lot = LotReservation(
        convive_id=convive.id,
        portee="jour",
        debut=menu.date_service,
        fin=menu.date_service,
        jours_reserves=1,
        total_xof=prix,
        etat="confirme",
        cle_unique=f"demo:{convive.id}:{menu.date_service}",
    )
    session.add(lot)
    await session.flush()
    etat = "non_reclamee" if hasard.random() < 0.15 else "servie"
    reservation = Reservation(
        lot_id=lot.id,
        convive_id=convive.id,
        menu_id=menu.id,
        date_service=menu.date_service,
        total_xof=prix,
        etat=etat,
        code_ticket=secrets.token_urlsafe(18),
        servie_le=datetime.combine(menu.date_service, datetime.min.time(), tzinfo=UTC) + timedelta(hours=12)
        if etat == "servie"
        else None,
    )
    session.add(reservation)
    await session.flush()
    for plat in (entree, resistance):
        session.add(LigneReservation(reservation_id=reservation.id, plat_id=plat.id, service=plat.categorie))
    await porte_monnaie.ecrire(
        session, portefeuille, "debit", prix, "reservation", f"lot:{lot.id}", "lot_reservation", lot.id
    )


async def peupler() -> None:
    """Crée le jeu de démonstration ; ne touche jamais à ce qui existe déjà."""
    config = lire_configuration()
    moteur = creer_moteur(config)
    hasard = random.Random(2026)  # noqa: S311  tirage de démonstration, sans enjeu de sécurité
    async with creer_fabrique(moteur)() as session, session.begin():
        print("Comptes de démonstration :")
        trouves = await _comptes(session, config)
        plats = await _plats(session)
        aujourd_hui = datetime.now(UTC).date()
        lundi = aujourd_hui - timedelta(days=aujourd_hui.weekday())
        a_venir = [lundi + timedelta(days=i) for i in range(12) if (lundi + timedelta(days=i)).weekday() < 5]
        passes = [
            aujourd_hui - timedelta(days=i)
            for i in range(1, JOURS_HISTORIQUE + 1)
            if (aujourd_hui - timedelta(days=i)).weekday() < 5
        ]
        for jour in sorted(set(a_venir + passes)):
            await _menu(session, jour, plats, hasard)
        prix = {"eleve": 1500, "employe": 2500}
        for email, *_reste, statut in COMPTES:
            if statut is None:
                continue
            convive = trouves[email]
            portefeuille = await porte_monnaie.verrouiller(session, convive.id)
            if await porte_monnaie.mouvement_existant(session, f"demo:credit:{email}") is None:
                await porte_monnaie.ecrire(
                    session,
                    portefeuille,
                    "credit",
                    CREDIT_INITIAL,
                    "ajustement_admin",
                    f"demo:credit:{email}",
                )
            for jour in passes:
                menu = (await session.execute(select(Menu).where(Menu.date_service == jour))).scalar_one()
                await _historique(session, convive, menu, prix[statut], hasard)
    await moteur.dispose()
    print(
        f"Jeu de démonstration prêt : {len(PLATS)} plats, menus de {len(a_venir)} jours à venir, "
        f"{len(passes)} jours d'historique."
    )


if __name__ == "__main__":
    asyncio.run(peupler())
