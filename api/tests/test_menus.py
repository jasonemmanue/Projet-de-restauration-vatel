"""Tests des menus sur la base de test : droits, création, publication, lecture par le convive, copies."""

import secrets
from datetime import date, timedelta

import httpx
from fastapi import FastAPI
from sqlalchemy import update

from app.models import Utilisateur
from app.services import comptes
from tests.aides_comptes import connecter, creer_admin, entete, inscrire_et_verifier
from tests.conftest import exige_base

pytestmark = exige_base
PNG = b"\x89PNG\r\n\x1a\n" + secrets.token_bytes(64)


def lundi_lointain() -> date:
    """Un lundi tiré au hasard dans les années 2090 : les dates de menu ne se croisent pas entre tests."""
    jour = date(2090, 1, 2) + timedelta(weeks=secrets.randbelow(520))
    return jour - timedelta(days=jour.weekday())


async def _admin(client: httpx.AsyncClient, application: FastAPI) -> dict[str, str]:
    reponse = await connecter(client, await creer_admin(application))
    return entete(reponse.json()["jeton"])


async def _plat(client: httpx.AsyncClient, admin: dict[str, str], categorie: str, **champs: object) -> str:
    corps = {"nom_fr": f"Plat {secrets.token_hex(4)}", "nom_en": "Dish", "categorie": categorie} | champs
    reponse = await client.post("/api/v1/admin/plats", headers=admin, json=corps)
    assert reponse.status_code == 201, reponse.text
    return reponse.json()["id"]


async def test_ecriture_refusee_au_convive(client_base: httpx.AsyncClient) -> None:
    _, jeton = await inscrire_et_verifier(client_base)
    reponse = await client_base.post(
        "/api/v1/admin/plats",
        headers=entete(jeton),
        json={"nom_fr": "x", "nom_en": "x", "categorie": "entree"},
    )
    assert reponse.status_code == 403 and reponse.json()["code"] == "acces_refuse"


async def test_menu_publie_seul_visible_avec_prix_et_allergenes(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    admin = await _admin(client_base, application_base)
    entree = await _plat(client_base, admin, "entree", allergenes=["arachide"])
    resistance = await _plat(client_base, admin, "resistance", prix_supplement_xof=800)
    jour = lundi_lointain() + timedelta(days=1)
    cree = await client_base.post(
        "/api/v1/admin/menus",
        headers=admin,
        json={
            "date_service": jour.isoformat(),
            "plats": [
                {"plat_id": entree, "quantite_prevue": 40},
                {"plat_id": resistance, "quantite_prevue": 60},
            ],
        },
    )
    assert cree.status_code == 201 and cree.json()["etat"] == "brouillon"
    identifiant, jeton = await inscrire_et_verifier(client_base)
    async with application_base.state.fabrique_sessions() as session, session.begin():
        compte = await comptes.trouver(session, comptes.lire_identifiant(identifiant))
        await session.execute(
            update(Utilisateur).where(Utilisateur.id == compte.id).values(allergies=["arachide"])
        )
    assert (await client_base.get(f"/api/v1/menus/{jour}", headers=entete(jeton))).status_code == 404

    publie = await client_base.post(f"/api/v1/admin/menus/{cree.json()['id']}/publier", headers=admin)
    assert publie.status_code == 200 and publie.json()["etat"] == "publie"
    vu = await client_base.get(f"/api/v1/menus/{jour}", headers=entete(jeton))
    assert vu.status_code == 200
    corps = vu.json()
    assert corps["prix_xof"] == 1500
    assert corps["gele"] is False
    assert corps["services"]["entree"][0]["contient_allergene"] is True
    assert corps["services"]["entree"][0]["portions_restantes"] == 40
    assert corps["services"]["resistance"][0]["prix_supplement_xof"] == 800
    assert corps["services"]["sortie"] == []
    semaine = await client_base.get(f"/api/v1/menus/semaine?du={jour}", headers=entete(jeton))
    assert len(semaine.json()["jours"]) == 7


async def test_menu_vide_non_publiable_et_jour_unique(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    admin = await _admin(client_base, application_base)
    jour = lundi_lointain() + timedelta(days=2)
    cree = await client_base.post(
        "/api/v1/admin/menus", headers=admin, json={"date_service": jour.isoformat()}
    )
    vide = await client_base.post(f"/api/v1/admin/menus/{cree.json()['id']}/publier", headers=admin)
    assert vide.status_code == 409 and vide.json()["code"] == "menu_vide"
    doublon = await client_base.post(
        "/api/v1/admin/menus", headers=admin, json={"date_service": jour.isoformat()}
    )
    assert doublon.status_code == 409 and doublon.json()["code"] == "menu_existant"


async def test_photo_controlee_par_ses_octets(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    admin = await _admin(client_base, application_base)
    plat = await _plat(client_base, admin, "sortie")
    faux = await client_base.put(
        f"/api/v1/admin/plats/{plat}/photo",
        headers=admin,
        files={"photo": ("a.png", b"<svg></svg>", "image/png")},
    )
    assert faux.status_code == 422 and faux.json()["code"] == "fichier_invalide"
    vrai = await client_base.put(
        f"/api/v1/admin/plats/{plat}/photo", headers=admin, files={"photo": ("a.jpg", PNG, "image/jpeg")}
    )
    assert vrai.status_code == 200 and vrai.json()["image_url"].startswith("/medias/plats/")
    image = await client_base.get(vrai.json()["image_url"])
    assert image.status_code == 200 and image.headers["content-type"] == "image/png" and image.content == PNG


async def test_copie_d_une_semaine(client_base: httpx.AsyncClient, application_base: FastAPI) -> None:
    admin = await _admin(client_base, application_base)
    plat = await _plat(client_base, admin, "resistance")
    de = lundi_lointain()
    for decalage in (0, 3):
        jour = (de + timedelta(days=decalage)).isoformat()
        corps = {"date_service": jour, "plats": [{"plat_id": plat, "quantite_prevue": 10}]}
        assert (await client_base.post("/api/v1/admin/menus", headers=admin, json=corps)).status_code == 201
    vers = de + timedelta(weeks=1)
    copie = await client_base.post(
        "/api/v1/admin/menus/semaine/dupliquer",
        headers=admin,
        json={"de": de.isoformat(), "vers": vers.isoformat()},
    )
    assert copie.status_code == 200
    assert copie.json()["crees"] == [vers.isoformat(), (vers + timedelta(days=3)).isoformat()]
    semaine = await client_base.get(f"/api/v1/admin/menus?du={vers}", headers=admin)
    etats = [j["etat"] for j in semaine.json()["jours"]]
    assert etats.count("brouillon") == 2


async def test_medias_refuse_un_chemin_hors_du_dossier(client_base: httpx.AsyncClient) -> None:
    for chemin in (
        "/medias/../pyproject.toml",
        "/medias/%2e%2e/%2e%2e/etc/passwd",
        "/medias/plats/absent.png",
    ):
        assert (await client_base.get(chemin)).status_code == 404


def test_images_de_demo_copiees_sans_ecraser(tmp_path) -> None:
    from app.services.stockage import copier_demo

    assert copier_demo(str(tmp_path)) == 15
    assert copier_demo(str(tmp_path)) == 0
    assert (tmp_path / "demo" / "attieke.jpg").is_file()
