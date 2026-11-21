"""Bloc « auth » : inscription par e-mail et par numéro avec code_demo, connexion, blocages, route admin
refusée, puis suppression des comptes de recette par l'admin de recette, même après un échec.

Aucun SMS ni e-mail réel : les adresses sont en .invalid et la recette exige la livraison « demo ».
"""

import secrets

import httpx

from recette.comptes import lire_identifiants_admin, lire_mot_de_passe_actions, nom_compte_recette
from recette.executeur import Recette

AUTH = "/api/v1/auth"


def _entete(jeton: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {jeton}"}


def _inscription(client: httpx.Client, type_: str, identifiant: str, mot_de_passe: str) -> httpx.Response:
    nom = nom_compte_recette()
    return client.post(
        f"{AUTH}/inscription",
        json={
            "type": type_,
            "identifiant": identifiant,
            "mot_de_passe": mot_de_passe,
            "prenom": nom,
            "nom": "recette",
            "role": "convive",
            "statut_convive": "autre",
            "conditions_acceptees": True,
            "appareil": {"nom": "recette", "plateforme": "web"},
        },
    )


def _verifier(recette: Recette, identifiant: str, canal: str, longueur: int) -> None:
    client = recette.client
    envoi = client.post(f"{AUTH}/verification/envoyer", json={"identifiant": identifiant, "canal": canal})
    corps = envoi.json() if envoi.status_code == 200 else {}
    code = corps.get("code_demo", "")
    recette.verifier(
        f"code_demo rendu en démo ({canal})",
        corps.get("mode_livraison") == "demo" and len(code) == longueur,
        f"statut {envoi.status_code}",
    )
    confirme = client.post(
        f"{AUTH}/verification/confirmer",
        json={"identifiant": identifiant, "canal": canal, "code": code.lower()},
    )
    recette.verifier(
        f"code confirmé ({canal})", confirme.status_code == 200, f"statut {confirme.status_code}"
    )


def lancer(recette: Recette) -> None:
    """Lance les contrôles du bloc auth."""
    client = recette.client
    admin = lire_identifiants_admin()
    actions = {"X-Mot-De-Passe-Actions": lire_mot_de_passe_actions()}
    connexion_admin = client.post(
        f"{AUTH}/connexion", json={"identifiant": admin.identifiant, "mot_de_passe": admin.mot_de_passe}
    )
    if not recette.verifier("connexion de l'admin de recette", connexion_admin.status_code == 200):
        return
    jeton_admin = connexion_admin.json()["jeton"]

    def _a_supprimer(utilisateur_id: str) -> None:
        def _supprimer() -> None:
            reponse = client.delete(
                f"/api/v1/admin/utilisateurs/{utilisateur_id}", headers={**_entete(jeton_admin), **actions}
            )
            recette.verifier(
                "compte de recette supprimé", reponse.status_code == 200, f"statut {reponse.status_code}"
            )

        recette.a_nettoyer(_supprimer)

    mot_de_passe = "Recette" + secrets.token_hex(4) + "9"
    email = f"{nom_compte_recette()}-{secrets.token_hex(3)}@recette.invalid"
    inscription = _inscription(client, "email", email, mot_de_passe)
    if not recette.verifier("inscription par e-mail en 201", inscription.status_code == 201):
        return
    corps = inscription.json()
    _a_supprimer(corps["utilisateur_id"])
    jeton = corps["jeton"]
    recette.verifier("compte né à vérifier", corps["etat"] == "a_verifier")
    doublon = _inscription(client, "email", email.upper(), mot_de_passe)
    recette.verifier("doublon refusé en 409 compte_existe", doublon.json().get("code") == "compte_existe")
    refus = client.post("/api/v1/admin/utilisateurs", headers=_entete(jeton), json={})
    recette.verifier("compte non vérifié refusé en 403 a_verifier", refus.json().get("code") == "a_verifier")
    _verifier(recette, email, "email", 5)
    moi = client.get("/api/v1/moi", headers=_entete(jeton))
    recette.verifier("profil vérifié", moi.status_code == 200 and moi.json().get("verifie") is True)
    refus_role = client.post("/api/v1/admin/utilisateurs", headers=_entete(jeton), json={})
    recette.verifier("route admin refusée au convive", refus_role.json().get("code") == "acces_refuse")

    telephone = "+22507" + "".join(secrets.choice("0123456789") for _ in range(8))
    par_numero = _inscription(client, "telephone", telephone, mot_de_passe)
    if recette.verifier("inscription par numéro en 201", par_numero.status_code == 201):
        _a_supprimer(par_numero.json()["utilisateur_id"])
        _verifier(recette, telephone, "telephone", 6)

    connexion = client.post(f"{AUTH}/connexion", json={"identifiant": email, "mot_de_passe": mot_de_passe})
    recette.verifier(
        "connexion par mot de passe",
        connexion.status_code == 200 and connexion.json()["utilisateur"]["verifie"] is True,
    )
    faux = {"identifiant": telephone, "mot_de_passe": "Mauvais" + secrets.token_hex(3) + "1"}
    statuts = [client.post(f"{AUTH}/connexion", json=faux).status_code for _ in range(5)]
    recette.verifier("cinq mots de passe faux en 401", statuts == [401] * 5, str(statuts))
    sixieme = client.post(f"{AUTH}/connexion", json={"identifiant": telephone, "mot_de_passe": mot_de_passe})
    recette.verifier("sixième essai bloqué en 429", sixieme.json().get("code") == "trop_de_tentatives")

    inconnu = client.post(
        f"{AUTH}/verification/envoyer",
        json={"identifiant": f"inconnu-{secrets.token_hex(4)}@recette.invalid", "canal": "email"},
    )
    recette.verifier(
        "aucun code_demo pour un compte inconnu",
        inconnu.status_code == 200 and "code_demo" not in inconnu.json(),
    )
