"""Tests de la connexion, des jetons, du mot de passe oublié et des routes admin de comptes."""

from datetime import UTC, datetime, timedelta

import httpx
from fastapi import FastAPI
from sqlalchemy import update

from app.models import CodeVerification, SessionAppareil
from app.services import comptes
from app.services.amorcage import creer_admin_initial
from tests.aides_comptes import (
    MOT_DE_PASSE,
    connecter,
    creer_admin,
    email_unique,
    entete,
    inscrire,
    inscrire_et_verifier,
)
from tests.conftest import client_pour, configuration_test, exige_base

pytestmark = exige_base
ACTIONS = {"X-Mot-De-Passe-Actions": "mot-de-passe-actions-test"}


async def test_connexion_dit_si_le_compte_est_verifie(client_base: httpx.AsyncClient) -> None:
    email = (await inscrire(client_base)).json()["utilisateur"]["email"]
    reponse = await connecter(client_base, email.upper())
    assert reponse.status_code == 200
    assert reponse.json()["utilisateur"]["verifie"] is False


async def test_message_identique_compte_inconnu_ou_mot_de_passe_faux(client_base: httpx.AsyncClient) -> None:
    email = (await inscrire(client_base)).json()["utilisateur"]["email"]
    faux = await connecter(client_base, email, "Mauvais2026")
    inconnu = await connecter(client_base, email_unique())
    assert faux.status_code == inconnu.status_code == 401
    assert faux.json() == inconnu.json()
    assert faux.json()["message"] == "Identifiant ou mot de passe incorrect."


async def test_sixieme_mot_de_passe_faux_bloque(application_base: FastAPI) -> None:
    async with client_pour(application_base) as client:
        email = (await inscrire(client)).json()["utilisateur"]["email"]
        statuts = [(await connecter(client, email, "Mauvais2026")).status_code for _ in range(5)]
    assert statuts == [401] * 5
    # Depuis une autre adresse, et avec le bon mot de passe : le compte reste bloqué.
    async with client_pour(application_base) as autre:
        sixieme = await connecter(autre, email)
    assert sixieme.status_code == 429 and sixieme.json()["code"] == "trop_de_tentatives"


async def test_rafraichissement_remplace_le_jeton(client_base: httpx.AsyncClient) -> None:
    ancien = (await inscrire(client_base)).json()["jeton_rafraichissement"]
    nouveau = await client_base.post("/api/v1/auth/rafraichir", json={"jeton_rafraichissement": ancien})
    assert nouveau.status_code == 200
    rejoue = await client_base.post("/api/v1/auth/rafraichir", json={"jeton_rafraichissement": ancien})
    assert rejoue.status_code == 401 and rejoue.json()["code"] == "jeton_invalide"


async def test_deconnexion_revoque_la_session(client_base: httpx.AsyncClient) -> None:
    jeton = (await inscrire(client_base)).json()["jeton"]
    assert (await client_base.post("/api/v1/auth/deconnexion", headers=entete(jeton))).status_code == 200
    apres = await client_base.get("/api/v1/moi", headers=entete(jeton))
    assert apres.status_code == 401 and apres.json()["code"] == "session_revoquee"


async def test_mot_de_passe_oublie_puis_reinitialise(client_base: httpx.AsyncClient) -> None:
    inscription = (await inscrire(client_base)).json()
    email = inscription["utilisateur"]["email"]
    oubli = await client_base.post(
        "/api/v1/auth/mot-de-passe/oublie", json={"identifiant": email, "canal": "email"}
    )
    code = oubli.json()["code_demo"]
    reponse = await client_base.post(
        "/api/v1/auth/mot-de-passe/reinitialiser",
        json={"identifiant": email, "code": code, "nouveau_mot_de_passe": "Nouveau2026"},
    )
    assert reponse.status_code == 200
    assert (await connecter(client_base, email)).status_code == 401
    assert (await connecter(client_base, email, "Nouveau2026")).status_code == 200
    ancienne = await client_base.get("/api/v1/moi", headers=entete(inscription["jeton"]))
    assert ancienne.json()["code"] == "session_revoquee"


async def test_route_admin_refusee_a_un_convive(client_base: httpx.AsyncClient) -> None:
    _, jeton = await inscrire_et_verifier(client_base)
    reponse = await client_base.post(
        "/api/v1/admin/utilisateurs", headers={**entete(jeton), **ACTIONS}, json={}
    )
    assert reponse.status_code == 403 and reponse.json()["code"] == "acces_refuse"


async def test_admin_cree_puis_supprime_un_compte(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    admin = (await connecter(client_base, await creer_admin(application_base))).json()["jeton"]
    corps = {
        "type": "email",
        "identifiant": email_unique(),
        "mot_de_passe": MOT_DE_PASSE,
        "prenom": "Agent",
        "nom": "Comptoir",
        "role": "agent",
    }
    sans_actions = await client_base.post("/api/v1/admin/utilisateurs", headers=entete(admin), json=corps)
    assert sans_actions.status_code == 403 and sans_actions.json()["code"] == "mot_de_passe_actions_invalide"
    cree = await client_base.post(
        "/api/v1/admin/utilisateurs", headers={**entete(admin), **ACTIONS}, json=corps
    )
    assert cree.status_code == 201 and cree.json()["verifie"] is True
    supprime = await client_base.delete(
        f"/api/v1/admin/utilisateurs/{cree.json()['id']}", headers={**entete(admin), **ACTIONS}
    )
    assert supprime.status_code == 200
    assert (await connecter(client_base, corps["identifiant"])).status_code == 401


async def test_admin_initial_cree_une_seule_fois(application_base: FastAPI) -> None:
    email = email_unique()
    config = configuration_test(
        application_base.state.config.database_url,
        ADMIN_INITIAL_EMAIL=email,
        ADMIN_INITIAL_MOT_DE_PASSE="AdminInitial2026",
    )
    await creer_admin_initial(application_base.state.fabrique_sessions, config)
    await creer_admin_initial(application_base.state.fabrique_sessions, config)
    async with client_pour(application_base) as client:
        reponse = await connecter(client, email, "AdminInitial2026")
    assert reponse.status_code == 200
    assert reponse.json()["utilisateur"]["role"] == "admin"


async def test_retour_apres_absence_demande_un_code(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    identifiant, _ = await inscrire_et_verifier(client_base)
    async with application_base.state.fabrique_sessions() as session, session.begin():
        utilisateur = await comptes.trouver(session, comptes.lire_identifiant(identifiant))
        await session.execute(
            update(SessionAppareil)
            .where(SessionAppareil.utilisateur_id == utilisateur.id)
            .values(derniere_activite=datetime.now(UTC) - timedelta(days=6))
        )
        # Le code de vérification de l'inscription date lui aussi d'avant l'absence.
        await session.execute(
            update(CodeVerification)
            .where(CodeVerification.identifiant_vise == identifiant)
            .values(cree_le=datetime.now(UTC) - timedelta(days=6))
        )
    etape = await connecter(client_base, identifiant, confirmer=False)
    assert etape.status_code == 200
    corps = etape.json()
    assert corps["etape"] == "code_requis" and "jeton" not in corps and corps["code_demo"]
    faux = await client_base.post(
        "/api/v1/auth/connexion/confirmer", json={"identifiant": identifiant, "code": "ZZZZZ"}
    )
    assert faux.status_code == 400
    juste = await client_base.post(
        "/api/v1/auth/connexion/confirmer", json={"identifiant": identifiant, "code": corps["code_demo"]}
    )
    assert juste.status_code == 200 and juste.json()["etape"] == "connecte" and juste.json()["jeton"]


async def test_sans_absence_pas_de_code(client_base: httpx.AsyncClient) -> None:
    identifiant, _ = await inscrire_et_verifier(client_base)
    reponse = await connecter(client_base, identifiant, confirmer=False)
    assert reponse.json()["etape"] == "connecte"
