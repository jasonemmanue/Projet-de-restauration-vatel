"""Bloc « menus » : écriture refusée au convive, menu brouillon invisible, publication, lecture avec prix.

Le menu de recette est posé sur un jour lointain puis annulé à la fin ; le plat est retiré du catalogue.
"""

import secrets
from datetime import date, timedelta

from recette.blocs.auth import _connecter_admin, _entete, _inscription, _verifier
from recette.comptes import lire_identifiants_admin, lire_mot_de_passe_actions
from recette.executeur import Recette


def lancer(recette: Recette) -> None:
    """Lance les contrôles du bloc menus."""
    client = recette.client
    admin = lire_identifiants_admin()
    actions = {"X-Mot-De-Passe-Actions": lire_mot_de_passe_actions()}
    connexion = _connecter_admin(client, admin.identifiant, admin.mot_de_passe)
    if not recette.verifier("connexion de l'admin de recette", connexion.status_code == 200):
        return
    jeton_admin = _entete(connexion.json()["jeton"])

    mot_de_passe = "Recette" + secrets.token_hex(4) + "9"
    email = f"recette-menus-{secrets.token_hex(4)}@recette.invalid"
    inscription = _inscription(client, "email", email, mot_de_passe)
    if not recette.verifier("convive de recette créé", inscription.status_code == 201):
        return
    convive_id = inscription.json()["utilisateur_id"]
    recette.a_nettoyer(
        lambda: client.delete(f"/api/v1/admin/utilisateurs/{convive_id}", headers={**jeton_admin, **actions})
    )
    _verifier(recette, email, "email", 5)
    jeton = _entete(inscription.json()["jeton"])

    refus = client.post(
        "/api/v1/admin/plats", headers=jeton, json={"nom_fr": "x", "nom_en": "x", "categorie": "entree"}
    )
    recette.verifier("écriture du catalogue refusée au convive", refus.json().get("code") == "acces_refuse")

    plat = client.post(
        "/api/v1/admin/plats",
        headers=jeton_admin,
        json={"nom_fr": f"recette {secrets.token_hex(4)}", "nom_en": "test dish", "categorie": "resistance"},
    )
    if not recette.verifier("plat créé par l'admin", plat.status_code == 201):
        return
    plat_id = plat.json()["id"]
    recette.a_nettoyer(lambda: client.delete(f"/api/v1/admin/plats/{plat_id}", headers=jeton_admin))

    jour = date(2095, 1, 3) + timedelta(days=secrets.randbelow(3000))
    menu = client.post(
        "/api/v1/admin/menus",
        headers=jeton_admin,
        json={"date_service": jour.isoformat(), "plats": [{"plat_id": plat_id, "quantite_prevue": 5}]},
    )
    if not recette.verifier("menu créé en brouillon", menu.status_code == 201):
        return
    menu_id = menu.json()["id"]
    recette.a_nettoyer(
        lambda: client.post(
            f"/api/v1/admin/menus/{menu_id}/annuler", headers=jeton_admin, json={"motif": "recette"}
        )
    )
    cache = client.get(f"/api/v1/menus/{jour}", headers=jeton)
    recette.verifier("menu brouillon invisible au convive", cache.status_code == 404)
    publie = client.post(f"/api/v1/admin/menus/{menu_id}/publier", headers=jeton_admin)
    recette.verifier("menu publié", publie.status_code == 200)
    vu = client.get(f"/api/v1/menus/{jour}", headers=jeton)
    corps = vu.json() if vu.status_code == 200 else {}
    recette.verifier("menu publié visible au convive", vu.status_code == 200)
    recette.verifier(
        "portions restantes rendues par le serveur",
        corps.get("services", {}).get("resistance", [{}])[0].get("portions_restantes") == 5,
    )
    recette.verifier("gel calculé par le serveur", "gele_le" in corps)
    sans_jeton = client.get("/api/v1/menus/semaine")
    recette.verifier("menus refusés sans jeton", sans_jeton.status_code == 401)
