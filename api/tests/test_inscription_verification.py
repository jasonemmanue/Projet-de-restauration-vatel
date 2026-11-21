"""Tests de l'inscription et de la vérification par code, sur la base de test."""

from datetime import UTC, datetime, timedelta

import httpx
from fastapi import FastAPI
from sqlalchemy import update

from app.models import CodeVerification, Parametre
from tests.aides_comptes import email_unique, entete, inscrire, telephone_unique
from tests.conftest import exige_base

pytestmark = exige_base
ENVOYER = "/api/v1/auth/verification/envoyer"
CONFIRMER = "/api/v1/auth/verification/confirmer"


async def test_inscription_par_numero_ouvre_la_session(client_base: httpx.AsyncClient) -> None:
    national = telephone_unique()[4:]
    saisie = " ".join(national[i : i + 2] for i in range(0, 10, 2))
    reponse = await inscrire(client_base, "telephone", saisie)
    assert reponse.status_code == 201, reponse.text
    corps = reponse.json()
    assert corps["etat"] == "a_verifier" and corps["canal"] == "telephone"
    assert corps["jeton"] and corps["jeton_rafraichissement"]
    assert corps["utilisateur"]["verifie"] is False
    assert corps["utilisateur"]["telephone"].startswith("+22507")


async def test_inscription_par_email_en_minuscules_et_doublon(client_base: httpx.AsyncClient) -> None:
    reponse = await inscrire(client_base, "email", "Awa." + email_unique().upper())
    assert reponse.status_code == 201
    email = reponse.json()["utilisateur"]["email"]
    assert email == email.lower()
    doublon = await inscrire(client_base, "email", email.upper())
    assert doublon.status_code == 409
    assert doublon.json()["code"] == "compte_existe"


async def test_mot_de_passe_faible_et_conditions_refusees(client_base: httpx.AsyncClient) -> None:
    faible = await inscrire(client_base, mot_de_passe="motdepasse")
    assert faible.status_code == 422 and faible.json()["code"] == "mot_de_passe_faible"
    sans_conditions = await inscrire(client_base, conditions_acceptees=False)
    assert sans_conditions.json()["code"] == "conditions_requises"
    sans_statut = await inscrire(client_base, statut_convive=None)
    assert sans_statut.json()["code"] == "validation"


async def test_compte_non_verifie_limite_au_profil(client_base: httpx.AsyncClient) -> None:
    jeton = (await inscrire(client_base)).json()["jeton"]
    assert (await client_base.get("/api/v1/moi", headers=entete(jeton))).status_code == 200
    refus = await client_base.post("/api/v1/admin/utilisateurs", headers=entete(jeton), json={})
    assert refus.status_code == 403 and refus.json()["code"] == "a_verifier"


async def test_code_juste_en_minuscules_verifie_le_compte(client_base: httpx.AsyncClient) -> None:
    inscription = (await inscrire(client_base)).json()
    email = inscription["utilisateur"]["email"]
    envoi = (await client_base.post(ENVOYER, json={"identifiant": email, "canal": "email"})).json()
    assert envoi["mode_livraison"] == "demo" and len(envoi["code_demo"]) == 5
    saisie = " ".join(envoi["code_demo"].lower())
    confirme = await client_base.post(
        CONFIRMER, json={"identifiant": email, "canal": "email", "code": saisie}
    )
    assert confirme.status_code == 200 and confirme.json() == {"verifie": True}
    moi = await client_base.get("/api/v1/moi", headers=entete(inscription["jeton"]))
    assert moi.json()["verifie"] is True


async def test_renvoi_avant_le_delai_refuse(client_base: httpx.AsyncClient) -> None:
    email = (await inscrire(client_base)).json()["utilisateur"]["email"]
    assert (await client_base.post(ENVOYER, json={"identifiant": email, "canal": "email"})).status_code == 200
    second = await client_base.post(ENVOYER, json={"identifiant": email, "canal": "email"})
    assert second.status_code == 429 and second.json()["code"] == "trop_de_requetes"


async def test_code_faux_puis_sixieme_bloque(client_base: httpx.AsyncClient) -> None:
    telephone = (await inscrire(client_base, "telephone")).json()["utilisateur"]["telephone"]
    code = (await client_base.post(ENVOYER, json={"identifiant": telephone, "canal": "telephone"})).json()[
        "code_demo"
    ]
    faux = "000000" if code != "000000" else "111111"
    corps = {"identifiant": telephone, "canal": "telephone", "code": faux}
    statuts = [(await client_base.post(CONFIRMER, json=corps)).status_code for _ in range(5)]
    assert statuts == [400] * 5
    sixieme = await client_base.post(CONFIRMER, json={**corps, "code": code})
    assert sixieme.status_code == 429 and sixieme.json()["code"] == "trop_essais"


async def test_code_expire(client_base: httpx.AsyncClient, application_base: FastAPI) -> None:
    email = (await inscrire(client_base)).json()["utilisateur"]["email"]
    code = (await client_base.post(ENVOYER, json={"identifiant": email, "canal": "email"})).json()[
        "code_demo"
    ]
    async with application_base.state.fabrique_sessions() as session, session.begin():
        await session.execute(
            update(CodeVerification)
            .where(CodeVerification.identifiant_vise == email)
            .values(expire_le=datetime.now(UTC) - timedelta(minutes=1))
        )
    reponse = await client_base.post(CONFIRMER, json={"identifiant": email, "canal": "email", "code": code})
    assert reponse.status_code == 410 and reponse.json()["code"] == "code_expire"


async def test_aucun_code_demo_pour_un_compte_inconnu(client_base: httpx.AsyncClient) -> None:
    envoi = await client_base.post(ENVOYER, json={"identifiant": email_unique(), "canal": "email"})
    assert envoi.status_code == 200 and "code_demo" not in envoi.json()
    oubli = await client_base.post(
        "/api/v1/auth/mot-de-passe/oublie", json={"identifiant": email_unique(), "canal": "email"}
    )
    assert oubli.status_code == 200 and "code_demo" not in oubli.json()


async def test_mode_reel_sans_code_demo(client_base: httpx.AsyncClient, application_base: FastAPI) -> None:
    email = (await inscrire(client_base)).json()["utilisateur"]["email"]
    cle = "livraison_verification_email"

    async def _regler(valeur: str) -> None:
        async with application_base.state.fabrique_sessions() as session, session.begin():
            await session.execute(update(Parametre).where(Parametre.cle == cle).values(valeur=valeur))

    await _regler("reel")
    try:
        reponse = await client_base.post(ENVOYER, json={"identifiant": email, "canal": "email"})
    finally:
        await _regler("demo")
    assert reponse.status_code == 502
    assert reponse.json()["code"] == "envoi_impossible" and "code_demo" not in reponse.text
