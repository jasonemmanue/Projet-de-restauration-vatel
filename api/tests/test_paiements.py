"""Tests des recharges GeniusPay : signature des webhooks, recharge, crédit unique, refus."""

import hashlib
import hmac
import json
import secrets
import time

import httpx
from fastapi import FastAPI

from app.services.geniuspay import en_xof, signature_valide
from tests.aides_comptes import entete, inscrire_et_verifier
from tests.conftest import SECRET_WEBHOOK_TEST, exige_base


def _signer(corps: bytes, secret: str = SECRET_WEBHOOK_TEST, horodatage: int | None = None) -> dict[str, str]:
    instant = str(horodatage or int(time.time()))
    signature = hmac.new(secret.encode(), instant.encode() + b"." + corps, hashlib.sha256).hexdigest()
    return {
        "X-Webhook-Signature": signature,
        "X-Webhook-Timestamp": instant,
        "X-Webhook-Environment": "sandbox",
        "Content-Type": "application/json",
    }


def test_signature_et_horodatage() -> None:
    corps = b'{"event":"payment.success"}'
    entetes = _signer(corps)
    horodatage, signature = entetes["X-Webhook-Timestamp"], entetes["X-Webhook-Signature"]
    assert signature_valide(SECRET_WEBHOOK_TEST, horodatage, corps, signature)
    assert not signature_valide("autre", horodatage, corps, signature)
    assert not signature_valide(SECRET_WEBHOOK_TEST, horodatage, corps + b" ", signature)
    vieux = str(int(time.time()) - 600)
    assert not signature_valide(
        SECRET_WEBHOOK_TEST, vieux, corps, _signer(corps, horodatage=int(vieux))["X-Webhook-Signature"]
    )


def test_montants_en_entiers() -> None:
    assert en_xof("10000.00") == 10000 and en_xof(250) == 250 and en_xof(None) == 0


def _faux_geniuspay(application: FastAPI, reference: str) -> list[dict]:
    recus: list[dict] = []

    def repondre(requete: httpx.Request) -> httpx.Response:
        recus.append(json.loads(requete.content))
        donnees = {"reference": reference, "payment_url": "https://pay.test/x", "fees": 30, "net_amount": 970}
        return httpx.Response(201, json={"success": True, "data": donnees})

    application.state.client_http = httpx.AsyncClient(transport=httpx.MockTransport(repondre))
    return recus


@exige_base
async def test_recharge_puis_webhook_credite_une_fois(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    reference = "MTX-" + secrets.token_hex(5).upper()
    recus = _faux_geniuspay(application_base, reference)
    _, jeton = await inscrire_et_verifier(client_base)
    geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    corps = {"montant_xof": 1000, "operateur": "wave", "telephone_payeur": "0707070707"}
    recharge = await client_base.post("/api/v1/paiements/recharge", headers=geste, json=corps)
    assert recharge.status_code == 201, recharge.text
    assert (
        recharge.json()["etat"] == "en_attente" and recharge.json()["url_redirection"] == "https://pay.test/x"
    )
    assert recus[0]["payment_method"] == "wave" and recus[0]["amount"] == 1000
    rejoue = await client_base.post("/api/v1/paiements/recharge", headers=geste, json=corps)
    assert rejoue.json()["paiement_id"] == recharge.json()["paiement_id"] and len(recus) == 1

    evenement = {
        "event": "payment.success",
        "data": {
            "reference": reference,
            "amount": "1000.00",
            "fees": "30.00",
            "net_amount": "970.00",
            "metadata": {},
        },
    }
    brut = json.dumps(evenement).encode()
    faux = await client_base.post(
        "/api/v1/paiements/webhook/test", content=brut, headers=_signer(brut, "mauvais")
    )
    assert faux.status_code == 401 and faux.json()["code"] == "signature_invalide"
    for _ in range(2):
        recu = await client_base.post("/api/v1/paiements/webhook/test", content=brut, headers=_signer(brut))
        assert recu.json() == {"recu": True}
    solde = (await client_base.get("/api/v1/porte-monnaie", headers=entete(jeton))).json()["solde_xof"]
    assert solde == 1000
    vu = await client_base.get(f"/api/v1/paiements/{recharge.json()['paiement_id']}", headers=entete(jeton))
    assert vu.json()["etat"] == "reussi"
    mauvais_mode = await client_base.post(
        "/api/v1/paiements/webhook/reel", content=brut, headers=_signer(brut)
    )
    assert mauvais_mode.status_code == 401


@exige_base
async def test_recharges_refusees(client_base: httpx.AsyncClient, application_base: FastAPI) -> None:
    _faux_geniuspay(application_base, "MTX-" + secrets.token_hex(5))
    _, jeton = await inscrire_et_verifier(client_base)
    _, autre = await inscrire_et_verifier(client_base)
    autre_id = (await client_base.get("/api/v1/moi", headers=entete(autre))).json()["id"]
    geste = {**entete(jeton), "Cle-Geste": secrets.token_hex(8)}
    base = {"operateur": "orange", "telephone_payeur": "0707070707"}
    trop_peu = await client_base.post(
        "/api/v1/paiements/recharge", headers=geste, json={**base, "montant_xof": 10}
    )
    assert trop_peu.json()["code"] == "montant_invalide"
    pour_un_autre = await client_base.post(
        "/api/v1/paiements/recharge",
        headers={**entete(jeton), "Cle-Geste": secrets.token_hex(8)},
        json={**base, "montant_xof": 1000, "beneficiaire_id": autre_id},
    )
    assert pour_un_autre.status_code == 403 and pour_un_autre.json()["code"] == "beneficiaire_interdit"
