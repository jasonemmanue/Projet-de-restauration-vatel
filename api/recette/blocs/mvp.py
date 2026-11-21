"""Bloc « mvp » : parcours complet du convive et de l'admin, sans paiement réel.

Admin : plat créé, menu créé puis publié sur un jour lointain, crédit du convive par ajustement, commandes du
jour, tableau de bord. Convive : menu, commande, solde, historique, annulation remboursée. Tout ce qui est
créé est retiré à la fin : commande annulée, menu annulé, plat retiré, compte supprimé.
"""

import secrets
from datetime import date, timedelta

from recette.blocs.auth import _connecter_admin, _entete, _verifier
from recette.comptes import lire_identifiants_admin, lire_mot_de_passe_actions
from recette.executeur import Recette


def lancer(recette: Recette) -> None:
    """Lance les contrôles du bloc mvp."""
    client = recette.client
    admin = lire_identifiants_admin()
    actions = {"X-Mot-De-Passe-Actions": lire_mot_de_passe_actions()}
    connexion = _connecter_admin(client, admin.identifiant, admin.mot_de_passe)
    if not recette.verifier("connexion de l'admin de recette", connexion.status_code == 200):
        return
    jeton_admin = _entete(connexion.json()["jeton"])

    email = f"recette-mvp-{secrets.token_hex(4)}@recette.invalid"
    inscription = client.post(
        "/api/v1/auth/inscription",
        json={
            "type": "email",
            "identifiant": email,
            "mot_de_passe": "Recette" + secrets.token_hex(4) + "9",
            "prenom": "recette",
            "nom": "mvp",
            "role": "convive",
            "statut_convive": "eleve",
            "conditions_acceptees": True,
        },
    )
    if not recette.verifier("convive élève de recette créé", inscription.status_code == 201):
        return
    convive_id = inscription.json()["utilisateur_id"]
    recette.a_nettoyer(
        lambda: client.delete(f"/api/v1/admin/utilisateurs/{convive_id}", headers={**jeton_admin, **actions})
    )
    _verifier(recette, email, "email", 5)
    jeton = _entete(inscription.json()["jeton"])

    plat = client.post(
        "/api/v1/admin/plats",
        headers=jeton_admin,
        json={
            "nom_fr": f"recette mvp {secrets.token_hex(4)}",
            "nom_en": "mvp dish",
            "categorie": "resistance",
        },
    )
    if not recette.verifier("plat créé", plat.status_code == 201):
        return
    plat_id = plat.json()["id"]
    recette.a_nettoyer(lambda: client.delete(f"/api/v1/admin/plats/{plat_id}", headers=jeton_admin))
    jour = date(2096, 1, 2) + timedelta(days=secrets.randbelow(3000))
    menu = client.post(
        "/api/v1/admin/menus",
        headers=jeton_admin,
        json={"date_service": jour.isoformat(), "plats": [{"plat_id": plat_id, "quantite_prevue": 10}]},
    )
    if not recette.verifier("menu créé", menu.status_code == 201):
        return
    menu_id = menu.json()["id"]
    recette.a_nettoyer(
        lambda: client.post(
            f"/api/v1/admin/menus/{menu_id}/annuler", headers=jeton_admin, json={"motif": "recette"}
        )
    )
    recette.verifier(
        "menu publié",
        client.post(f"/api/v1/admin/menus/{menu_id}/publier", headers=jeton_admin).status_code == 200,
    )

    credit = client.post(
        f"/api/v1/admin/utilisateurs/{convive_id}/ajustement",
        headers={**jeton_admin, **actions, "Cle-Geste": secrets.token_hex(8)},
        json={"sens": "credit", "montant_xof": 3000, "motif": "recette"},
    )
    recette.verifier("convive crédité par l'admin", credit.json().get("solde_apres_xof") == 3000)
    vu = client.get(f"/api/v1/menus/{jour}", headers=jeton)
    recette.verifier(
        "menu et prix lus par le convive", vu.status_code == 200 and vu.json().get("prix_xof") == 1500
    )

    geste = {**jeton, "Cle-Geste": secrets.token_hex(8)}
    corps = {
        "portee": "jour",
        "debut": jour.isoformat(),
        "jours": [{"date_service": jour.isoformat(), "plats": [{"plat_id": plat_id, "quantite": 1}]}],
    }
    commande = client.post("/api/v1/reservations", headers=geste, json=corps)
    if not recette.verifier("commande passée", commande.status_code == 201):
        return
    reservation_id = commande.json()["reservations"][0]["id"]
    double = client.post("/api/v1/reservations", headers=geste, json=corps)
    recette.verifier("double clic sans second débit", double.json().get("id") == commande.json()["id"])
    solde = client.get("/api/v1/porte-monnaie", headers=jeton).json().get("solde_xof")
    recette.verifier("solde débité une fois", solde == 1500, f"solde {solde}")
    cuisine = client.get(f"/api/v1/admin/commandes-jour?date={jour}", headers=jeton_admin).json()
    recette.verifier("commandes du jour pour la cuisine", cuisine.get("total_parts") == 1)
    annulation = client.post(f"/api/v1/reservations/{reservation_id}/annuler", headers=geste)
    recette.verifier("annulation remboursée avant le gel", annulation.json().get("rembourse_xof") == 1500)
    historique = client.get("/api/v1/porte-monnaie/mouvements", headers=jeton).json()
    recette.verifier("historique de trois mouvements", historique.get("total") == 3)
    tableau = client.get("/api/v1/admin/tableau-bord", headers=jeton_admin)
    recette.verifier(
        "tableau de bord lu par l'admin", tableau.status_code == 200 and "courbe" in tableau.json()
    )
    recette.verifier(
        "tableau de bord refusé au convive",
        client.get("/api/v1/admin/tableau-bord", headers=jeton).status_code == 403,
    )
