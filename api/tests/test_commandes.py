"""Tests des commandes et du porte-monnaie : débit unique, doublon, gel, épuisement, solde, annulation."""

import secrets
from datetime import UTC, datetime, timedelta

import httpx
from fastapi import FastAPI

from app.services.regles_commandes import LigneCommandee, fin_de_periode, supplements
from tests.aides_comptes import connecter, creer_admin, entete, inscrire_et_verifier
from tests.conftest import exige_base
from tests.test_menus import _plat, lundi_lointain

ACTIONS = {"X-Mot-De-Passe-Actions": "mot-de-passe-actions-test"}


def test_supplement_au_dela_d_une_part_par_service() -> None:
    lignes = [
        LigneCommandee("a", "resistance", 2, 800),
        LigneCommandee("b", "resistance", 1, 500),
        LigneCommandee("c", "entree", 1, 300),
    ]
    assert supplements(lignes) == [800, 500, 0]


def test_fin_de_periode() -> None:
    debut = datetime(2026, 11, 23, tzinfo=UTC).date()
    assert fin_de_periode("jour", debut) == debut
    assert fin_de_periode("semaine", debut) == debut + timedelta(days=6)
    assert fin_de_periode("mois", debut).day == 30


async def _preparer(client: httpx.AsyncClient, application: FastAPI, jour, quantite: int = 40):
    admin = (await connecter(client, await creer_admin(application))).json()["jeton"]
    plat = await _plat(client, entete(admin), "resistance", prix_supplement_xof=500)
    menu = await client.post(
        "/api/v1/admin/menus",
        headers=entete(admin),
        json={"date_service": jour.isoformat(), "plats": [{"plat_id": plat, "quantite_prevue": quantite}]},
    )
    await client.post(f"/api/v1/admin/menus/{menu.json()['id']}/publier", headers=entete(admin))
    _, jeton = await inscrire_et_verifier(client)
    moi = (await client.get("/api/v1/moi", headers=entete(jeton))).json()
    return admin, plat, jeton, moi["id"]


async def _crediter(client: httpx.AsyncClient, admin: str, cible: str, montant: int) -> httpx.Response:
    return await client.post(
        f"/api/v1/admin/utilisateurs/{cible}/ajustement",
        headers={**entete(admin), **ACTIONS, "Cle-Geste": secrets.token_hex(8)},
        json={"sens": "credit", "montant_xof": montant, "motif": "essai"},
    )


def _commande(jour, plat: str, quantite: int = 1) -> dict:
    return {
        "portee": "jour",
        "debut": jour.isoformat(),
        "jours": [{"date_service": jour.isoformat(), "plats": [{"plat_id": plat, "quantite": quantite}]}],
    }


@exige_base
async def test_commande_debitee_une_fois_puis_annulee(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    jour = lundi_lointain() + timedelta(days=1)
    admin, plat, jeton, convive_id = await _preparer(client_base, application_base, jour)
    assert (await _crediter(client_base, admin, convive_id, 5000)).json()["solde_apres_xof"] == 5000
    geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    premiere = await client_base.post("/api/v1/reservations", headers=geste, json=_commande(jour, plat, 2))
    assert premiere.status_code == 201, premiere.text
    assert premiere.json()["total_xof"] == 1500 + 500
    double_clic = await client_base.post("/api/v1/reservations", headers=geste, json=_commande(jour, plat, 2))
    assert double_clic.json()["id"] == premiere.json()["id"]
    solde = (await client_base.get("/api/v1/porte-monnaie", headers=entete(jeton))).json()["solde_xof"]
    assert solde == 3000
    autre_geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    deuxieme = await client_base.post("/api/v1/reservations", headers=autre_geste, json=_commande(jour, plat))
    assert deuxieme.status_code == 409 and deuxieme.json()["code"] == "reservation_existante"
    cuisine = (
        await client_base.get(f"/api/v1/admin/commandes-jour?date={jour}", headers=entete(admin))
    ).json()
    assert cuisine["total_parts"] == 2 and cuisine["services"]["resistance"][0]["parts"] == 2

    reservation_id = premiere.json()["reservations"][0]["id"]
    annulee = await client_base.post(f"/api/v1/reservations/{reservation_id}/annuler", headers=geste)
    assert annulee.json() == {"etat": "annulee", "rembourse_xof": 2000}
    assert (await client_base.get("/api/v1/porte-monnaie", headers=entete(jeton))).json()["solde_xof"] == 5000
    cuisine = await client_base.get(f"/api/v1/admin/commandes-jour?date={jour}", headers=entete(admin))
    assert cuisine.status_code == 200 and cuisine.json()["total_parts"] == 0
    tableau = await client_base.get(f"/api/v1/admin/tableau-bord?du={jour}&au={jour}", headers=entete(admin))
    assert tableau.json()["annulees"] == 1 and tableau.json()["recettes_xof"] == 0
    refus = await client_base.get("/api/v1/admin/tableau-bord", headers=entete(jeton))
    assert refus.status_code == 403
    mouvements = (await client_base.get("/api/v1/porte-monnaie/mouvements", headers=entete(jeton))).json()
    assert [m["motif"] for m in mouvements["elements"]] == ["annulation", "reservation", "ajustement_admin"]


@exige_base
async def test_solde_insuffisant_et_commande_d_un_autre(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    jour = lundi_lointain() + timedelta(days=2)
    _, plat, jeton, _ = await _preparer(client_base, application_base, jour)
    geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    pauvre = await client_base.post("/api/v1/reservations", headers=geste, json=_commande(jour, plat))
    assert pauvre.status_code == 402 and pauvre.json()["code"] == "solde_insuffisant"
    _, autre = await inscrire_et_verifier(client_base)
    inconnue = await client_base.get(
        f"/api/v1/reservations/{secrets.token_hex(16)[:8]}-0000-0000-0000-000000000000", headers=entete(autre)
    )
    assert inconnue.status_code in (404, 422)


@exige_base
async def test_jour_gele_et_plat_epuise(client_base: httpx.AsyncClient, application_base: FastAPI) -> None:
    hier = datetime.now(UTC).date() - timedelta(days=secrets.randbelow(3000) + 400)
    admin, plat, jeton, convive_id = await _preparer(client_base, application_base, hier)
    await _crediter(client_base, admin, convive_id, 10000)
    geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    gele = await client_base.post("/api/v1/reservations", headers=geste, json=_commande(hier, plat))
    assert gele.status_code == 409 and gele.json()["code"] == "commande_gelee"
    jour = lundi_lointain() + timedelta(days=3)
    admin2, plat2, jeton2, convive2 = await _preparer(client_base, application_base, jour, quantite=1)
    await _crediter(client_base, admin2, convive2, 10000)
    epuise = await client_base.post(
        "/api/v1/reservations",
        headers={**entete(jeton2), "Cle-Geste": secrets.token_hex(8)},
        json=_commande(jour, plat2, 2),
    )
    assert epuise.status_code == 409 and epuise.json()["code"] == "plat_epuise"


@exige_base
async def test_sans_cle_geste_refuse(client_base: httpx.AsyncClient) -> None:
    _, jeton = await inscrire_et_verifier(client_base)
    reponse = await client_base.post("/api/v1/reservations", headers=entete(jeton), json={})
    assert reponse.status_code in (422, 428)
