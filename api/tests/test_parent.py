"""Tests de la liaison parent-enfant : code juste, code faux, enfant d'un autre introuvable, réglages."""

import httpx
from fastapi import FastAPI

from tests.aides_comptes import entete, inscrire, inscrire_et_verifier
from tests.conftest import exige_base

pytestmark = exige_base


async def _parent_verifie(client: httpx.AsyncClient) -> str:
    reponse = await inscrire(client, role="parent", statut_convive=None)
    email = reponse.json()["utilisateur"]["email"]
    code = (
        await client.post("/api/v1/auth/verification/envoyer", json={"identifiant": email, "canal": "email"})
    ).json()["code_demo"]
    await client.post(
        "/api/v1/auth/verification/confirmer", json={"identifiant": email, "canal": "email", "code": code}
    )
    return reponse.json()["jeton"]


async def test_parent_lie_son_enfant_et_lui_seul(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    _, enfant = await inscrire_et_verifier(client_base)
    _, autre_enfant = await inscrire_et_verifier(client_base)
    parent = await _parent_verifie(client_base)
    code = (await client_base.get("/api/v1/moi/code-liaison", headers=entete(enfant))).json()["code_liaison"]
    faux = await client_base.post(
        "/api/v1/parent/liaison", headers=entete(parent), json={"code_liaison": "ZZZZZZZZ"}
    )
    assert faux.status_code == 400 and faux.json()["code"] == "code_invalide"
    lie = await client_base.post(
        "/api/v1/parent/liaison", headers=entete(parent), json={"code_liaison": code.lower()}
    )
    assert lie.status_code == 200 and lie.json()["etat"] == "actif"
    enfant_id = lie.json()["enfant"]["id"]
    deja = await client_base.post(
        "/api/v1/parent/liaison", headers=entete(parent), json={"code_liaison": code}
    )
    assert deja.json()["code"] == "deja_lie"
    liste = (await client_base.get("/api/v1/parent/enfants", headers=entete(parent))).json()
    assert [e["id"] for e in liste] == [enfant_id]

    autre_id = (await client_base.get("/api/v1/moi", headers=entete(autre_enfant))).json()["id"]
    assert (
        await client_base.get(f"/api/v1/parent/enfants/{autre_id}/repas", headers=entete(parent))
    ).status_code == 404
    assert (
        await client_base.get(f"/api/v1/parent/enfants/{enfant_id}/repas", headers=entete(parent))
    ).json() == []
    seuil = await client_base.put(
        f"/api/v1/parent/enfants/{enfant_id}/seuil", headers=entete(parent), json={"seuil_alerte_solde": 2000}
    )
    assert seuil.json()["seuil_alerte_solde"] == 2000
    allergies = await client_base.put(
        f"/api/v1/parent/enfants/{enfant_id}/allergies",
        headers=entete(parent),
        json={"allergies": ["arachide"]},
    )
    assert allergies.json()["allergies"] == ["arachide"]
    assert (await client_base.get("/api/v1/parent/enfants", headers=entete(enfant))).status_code == 403
    delie = await client_base.delete(f"/api/v1/parent/enfants/{enfant_id}", headers=entete(parent))
    assert delie.json() == {"delie": True}
    assert (await client_base.get("/api/v1/parent/enfants", headers=entete(parent))).json() == []
