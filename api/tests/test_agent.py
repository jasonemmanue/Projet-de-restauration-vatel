"""Tests du comptoir : signature du QR, scan accepté puis déjà servi, ticket inventé, file rejouée."""

import secrets
from datetime import UTC, datetime

import httpx
from fastapi import FastAPI

from app.services.agent import contenu_qr, lire_qr
from tests.aides_comptes import MOT_DE_PASSE, connecter, email_unique, entete
from tests.conftest import exige_base
from tests.test_commandes import _commande, _crediter, _preparer

ACTIONS = {"X-Mot-De-Passe-Actions": "mot-de-passe-actions-test"}


def test_signature_du_qr() -> None:
    contenu = contenu_qr("k" * 48, "ABCDEF123456")
    assert lire_qr("k" * 48, contenu) == "ABCDEF123456"
    assert lire_qr("k" * 48, contenu[:-1] + ("0" if contenu[-1] != "0" else "1")) is None
    assert lire_qr("autre-secret" * 4, contenu) is None
    assert lire_qr("k" * 48, "n'importe quoi") is None


async def _agent(client: httpx.AsyncClient, admin: str) -> dict[str, str]:
    email = email_unique()
    corps = {
        "type": "email",
        "identifiant": email,
        "mot_de_passe": MOT_DE_PASSE,
        "prenom": "Ali",
        "nom": "Comptoir",
        "role": "agent",
    }
    cree = await client.post("/api/v1/admin/utilisateurs", headers={**entete(admin), **ACTIONS}, json=corps)
    assert cree.status_code == 201
    return entete((await connecter(client, email)).json()["jeton"])


@exige_base
async def test_scan_accepte_puis_deja_servi_et_file_rejouee(
    client_base: httpx.AsyncClient, application_base: FastAPI
) -> None:
    aujourd_hui = datetime.now(UTC).date()
    admin, plat, jeton, convive_id = await _preparer(client_base, application_base, aujourd_hui)
    await _crediter(client_base, admin, convive_id, 5000)
    # Le jour même est gelé depuis la veille : la commande se pose directement en base pour ce test.
    from sqlalchemy import update

    from app.models import Parametre

    async with application_base.state.fabrique_sessions() as session, session.begin():
        await session.execute(
            update(Parametre).where(Parametre.cle == "gel_jours_avant_service").values(valeur=-1)
        )
    try:
        commande = await client_base.post(
            "/api/v1/reservations",
            headers={**entete(jeton), "Cle-Geste": secrets.token_hex(8)},
            json=_commande(aujourd_hui, plat),
        )
    finally:
        async with application_base.state.fabrique_sessions() as session, session.begin():
            await session.execute(
                update(Parametre).where(Parametre.cle == "gel_jours_avant_service").values(valeur=1)
            )
    assert commande.status_code == 201, commande.text
    reservation_id = commande.json()["reservations"][0]["id"]
    ticket = (
        await client_base.get(f"/api/v1/reservations/{reservation_id}/ticket", headers=entete(jeton))
    ).json()

    agent = await _agent(client_base, admin)
    convive_refuse = await client_base.get("/api/v1/agent/service", headers=entete(jeton))
    assert convive_refuse.status_code == 403
    scan = {"code_ticket": ticket["contenu_qr"]}
    premier = await client_base.post(
        "/api/v1/agent/scan", headers={**agent, "Cle-Geste": secrets.token_hex(8)}, json=scan
    )
    assert premier.json()["resultat"] == "accepte" and premier.json()["plats"]
    second = await client_base.post(
        "/api/v1/agent/scan", headers={**agent, "Cle-Geste": secrets.token_hex(8)}, json=scan
    )
    assert second.json()["resultat"] == "deja_servi" and second.json()["detail"]
    faux = await client_base.post(
        "/api/v1/agent/scan",
        headers={**agent, "Cle-Geste": secrets.token_hex(8)},
        json={"code_ticket": "x" * 30 + ".0123456789abcdef"},
    )
    assert faux.json()["resultat"] == "inconnu"

    file = [{"code_ticket": ticket["contenu_qr"], "cle_unique": secrets.token_hex(8)}]
    une = await client_base.post("/api/v1/agent/scan/file", headers=agent, json=file)
    deux = await client_base.post("/api/v1/agent/scan/file", headers=agent, json=file)
    assert une.json()[0]["resultat"] == deux.json()[0]["resultat"] == "deja_servi"
    assert deux.json()[0]["rejoue"] is True
    service = (await client_base.get("/api/v1/agent/service", headers=agent)).json()
    assert service["servis"] >= 1
    liste = (await client_base.get("/api/v1/agent/service/jour", headers=agent)).json()
    assert any(t["contenu_qr"] == ticket["contenu_qr"] for t in liste)
