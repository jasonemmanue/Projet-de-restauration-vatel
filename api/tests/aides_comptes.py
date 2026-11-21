"""Aides des tests de comptes : identifiants uniques, inscription, vérification, admin de test."""

import secrets

import httpx
from fastapi import FastAPI

from app.services import comptes
from app.services.regles_comptes import Identifiant

MOT_DE_PASSE = "Cantine2026"


def email_unique() -> str:
    """Adresse de test jamais distribuable, unique par appel."""
    return f"test-{secrets.token_hex(6)}@essai.invalid"


def telephone_unique() -> str:
    """Numéro ivoirien mobile de test, unique par appel."""
    return "+22507" + "".join(secrets.choice("0123456789") for _ in range(8))


async def inscrire(
    client: httpx.AsyncClient, type_: str = "email", identifiant: str | None = None, **champs: object
) -> httpx.Response:
    """Inscrit un convive élève et rend la réponse brute."""
    corps: dict[str, object] = {
        "type": type_,
        "identifiant": identifiant or (email_unique() if type_ == "email" else telephone_unique()),
        "mot_de_passe": MOT_DE_PASSE,
        "prenom": "Awa",
        "nom": "Koné",
        "role": "convive",
        "statut_convive": "eleve",
        "conditions_acceptees": True,
    }
    corps.update(champs)
    return await client.post("/api/v1/auth/inscription", json=corps)


def entete(jeton: str) -> dict[str, str]:
    """En-tête d'authentification."""
    return {"Authorization": f"Bearer {jeton}"}


async def inscrire_et_verifier(client: httpx.AsyncClient, type_: str = "email") -> tuple[str, str]:
    """Inscrit puis vérifie un compte ; rend son identifiant et son jeton d'accès."""
    reponse = await inscrire(client, type_)
    identifiant = reponse.json()["utilisateur"]["email" if type_ == "email" else "telephone"]
    code = (
        await client.post(
            "/api/v1/auth/verification/envoyer", json={"identifiant": identifiant, "canal": type_}
        )
    ).json()["code_demo"]
    confirme = await client.post(
        "/api/v1/auth/verification/confirmer", json={"identifiant": identifiant, "canal": type_, "code": code}
    )
    assert confirme.status_code == 200
    return identifiant, reponse.json()["jeton"]


async def creer_admin(application: FastAPI) -> str:
    """Crée en base un admin vérifié et rend son e-mail."""
    email = email_unique()
    donnees = comptes.NouveauCompte(Identifiant("email", email), MOT_DE_PASSE, "Ada", "Admin", "admin", None)
    async with application.state.fabrique_sessions() as session, session.begin():
        await comptes.creer_compte(
            session, application.state.config, donnees, verifie=True, consentement=False
        )
    return email


async def connecter(
    client: httpx.AsyncClient, identifiant: str, mot_de_passe: str = MOT_DE_PASSE, confirmer: bool = True
) -> httpx.Response:
    """Connexion par mot de passe ; si un code est demandé et `confirmer` vaut vrai, le confirme aussitôt."""
    reponse = await client.post(
        "/api/v1/auth/connexion", json={"identifiant": identifiant, "mot_de_passe": mot_de_passe}
    )
    if confirmer and reponse.status_code == 200 and reponse.json().get("etape") == "code_requis":
        return await client.post(
            "/api/v1/auth/connexion/confirmer",
            json={"identifiant": identifiant, "code": reponse.json()["code_demo"]},
        )
    return reponse
