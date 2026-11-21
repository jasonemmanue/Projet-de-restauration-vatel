# Contrat d'API

Adresse de production : `https://projet-de-restauration-vatel-production.up.railway.app` (santé sur `/health`).

Toutes les routes sont préfixées par `/api/v1`. Ce fichier fait foi : l'application et le site n'appellent
rien qui n'y figure pas. Une session qui a besoin d'un changement le signale dans son compte rendu.

## Conventions

- Authentification : en-tête `Authorization: Bearer <jeton>`. L'identité vient du jeton, jamais du corps.
- Rôles : `public` (aucun jeton), `convive`, `parent`, `agent`, `admin`. Refus par défaut.
- Dates en UTC, format ISO 8601. Montants en entiers XOF.
- Langue de réponse : en-tête `Accept-Language: fr` ou `en`, sinon la langue du compte.
- Idempotence : toute route qui crée de l'argent ou une réservation exige l'en-tête `Cle-Geste`, unique par
  geste de l'utilisateur. Un renvoi de la même clé rend la même réponse sans rien créer.
- Dépense : toute route qui débite le porte-monnaie exige en plus l'en-tête `X-Preuve-Pin`, obtenu par
  `/auth/pin/verifier` et valable deux minutes.
- Pagination : `?page=1&taille=20`, réponse `{"elements": [], "page": 1, "taille": 20, "total": 0}`.
- Version déployée : chaque réponse porte l'en-tête `X-Version-Commit`.

### Format d'erreur unique

```json
{"code": "solde_insuffisant", "message": "Le solde ne couvre pas ce repas."}
```

Codes communs : `validation` (422), `non_authentifie` (401), `acces_refuse` (403), `introuvable` (404),
`conflit` (409), `trop_de_requetes` (429), `erreur_serveur` (500). Les messages sont génériques et ne révèlent
jamais l'existence d'un compte ni un détail technique.

## Santé

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /sante | public | aucun | `{"etat": "ok", "commit": "abc1234", "version": "1.0.0", "base": "ok", "heure": "..."}` | 500 |

## Authentification

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /auth/inscription | public | `{"nom_complet", "identifiant", "mot_de_passe", "role", "statut_convive"}` | `{"utilisateur_id", "etat": "a_verifier", "canal": "telephone"}` | `identifiant_deja_pris` 409, `mot_de_passe_faible` 422, `validation` |
| POST /auth/connexion | public | `{"identifiant", "mot_de_passe", "appareil"}` | `{"jeton", "jeton_rafraichissement", "expire_dans", "utilisateur"}` | `identifiants_invalides` 401, `compte_a_verifier` 403, `compte_desactive` 403 |
| POST /auth/verification/envoyer | public | `{"identifiant", "canal", "usage"}` | `{"mode_livraison": "demo", "code_demo": "123456", "expire_le"}` ; en mode `reel`, pas de `code_demo` | `introuvable` 404, `trop_de_requetes` 429, `envoi_impossible` 502 |
| POST /auth/verification/confirmer | public | `{"identifiant", "canal", "usage", "code"}` | `{"verifie": true, "jeton", "jeton_rafraichissement"}` | `code_invalide` 400, `code_expire` 410, `trop_essais` 429 |
| POST /auth/mot-de-passe/oublie | public | `{"identifiant", "canal"}` | `{"mode_livraison", "code_demo"}` | `trop_de_requetes` 429 |
| POST /auth/mot-de-passe/reinitialiser | public | `{"identifiant", "code", "nouveau_mot_de_passe"}` | `{"reinitialise": true}` | `code_invalide` 400, `code_expire` 410, `mot_de_passe_faible` 422 |
| POST /auth/mot-de-passe/changer | tous | `{"ancien", "nouveau"}` | `{"change": true, "pin_a_redefinir": true}` | `identifiants_invalides` 401, `mot_de_passe_faible` 422 |
| POST /auth/code-secours | admin, parent | `{"utilisateur_id"}` | `{"code", "expire_le"}` | `acces_refuse` 403, `introuvable` 404 |
| POST /auth/rafraichir | public | `{"jeton_rafraichissement"}` | `{"jeton", "jeton_rafraichissement", "expire_dans"}` | `jeton_invalide` 401, `session_revoquee` 401 |
| POST /auth/deconnexion | tous | `{"jeton_rafraichissement"}` | `{"deconnecte": true}` | `non_authentifie` 401 |
| POST /auth/google | public | `{"jeton_google", "appareil"}` | `{"jeton", "jeton_rafraichissement", "profil_complet": false}` | `jeton_invalide` 401 |
| POST /auth/apple | public | `{"jeton_apple", "appareil"}` | idem Google | `jeton_invalide` 401 |
| POST /auth/profil/finaliser | tous | `{"nom_complet", "identifiant", "role", "statut_convive", "mot_de_passe"}` | `{"profil_complet": true, "verification_requise": true}` | `identifiant_deja_pris` 409, `validation` |

### Code PIN et biométrie

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /auth/pin/definir | tous | `{"pin"}` | `{"defini": true}` | `pin_faible` 422, `conflit` 409 |
| POST /auth/pin/verifier | tous | `{"pin"}` | `{"preuve": "...", "expire_dans": 120}` | `pin_invalide` 401, `pin_bloque` 423 |
| POST /auth/pin/changer | tous | `{"ancien_pin", "nouveau_pin"}` | `{"change": true}` | `pin_invalide` 401, `pin_bloque` 423 |
| POST /auth/pin/apres-mot-de-passe | tous | `{"mot_de_passe", "nouveau_pin"}` | `{"defini": true}` | `identifiants_invalides` 401 |
| POST /auth/biometrie/activer | tous | `{"appareil_id", "secret"}` | `{"active": true}` | `appareil_inconnu` 404 |
| POST /auth/biometrie/couper | tous | `{"appareil_id"}` | `{"active": false}` | `appareil_inconnu` 404 |
| POST /auth/biometrie/preuve | tous | `{"appareil_id", "secret"}` | `{"preuve", "expire_dans": 120}` | `biometrie_inactive` 403, `secret_invalide` 401 |

### Connexion par QR code

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /auth/qr/demander | public | `{"appareil"}` | `{"jeton_demande", "expire_le"}` | `trop_de_requetes` 429 |
| POST /auth/qr/lire | tous | `{"jeton_demande"}` | `{"appareil_demandeur", "adresse_ip", "etat": "lu"}` | `introuvable` 404, `qr_expire` 410 |
| POST /auth/qr/confirmer | tous | `{"jeton_demande", "accepte": true}` | `{"etat": "confirme"}` | `qr_expire` 410, `acces_refuse` 403 |
| GET /auth/qr/etat | public | `?jeton_demande=` | `{"etat", "jeton", "jeton_rafraichissement"}` quand confirmé | `introuvable` 404, `qr_expire` 410 |

### Sessions ouvertes

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /auth/sessions | tous | aucun | liste `{id, appareil_nom, plateforme, derniere_activite, actuelle}` | `non_authentifie` 401 |
| DELETE /auth/sessions/{id} | tous | aucun | `{"revoquee": true}` | `introuvable` 404, `acces_refuse` 403 |
| DELETE /auth/sessions | tous | aucun | `{"revoquees": 3}` | `non_authentifie` 401 |

## Profil

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /moi | tous | aucun | profil complet : informations, préférences, avatar, chiffres, comptes liés | 401 |
| PATCH /moi | tous | `{"nom_complet", "allergies", "seuil_alerte_solde"}` | profil mis à jour | `validation` |
| PUT /moi/preferences | tous | `{"langue", "theme", "notifications"}` | préférences | `validation` |
| PUT /moi/avatar | tous | `{"avatar_id"}` ou fichier multipart | `{"url"}` | `fichier_invalide` 422, `trop_lourd` 413 |
| GET /moi/chiffres | convive, parent | `?du=&au=` | `{"repas", "depense_xof", "plat_favori", "economie_anti_gaspi"}` | `validation` |
| GET /moi/recus | tous | pagination | liste de reçus `{id, date, montant_xof, type, url_pdf}` | 401 |
| GET /moi/recus/{id} | tous | aucun | PDF | `introuvable` 404 |
| GET /moi/comptes-lies | tous | aucun | `{"google": true, "apple": false, "parents": [], "enfants": []}` | 401 |
| DELETE /moi/comptes-lies/{fournisseur} | tous | aucun | `{"delie": true}` | `conflit` 409 si c'est la seule méthode de connexion |
| POST /moi/export | tous | aucun | `{"demande": true}`, fichier envoyé quand il est prêt | `trop_de_requetes` 429 |
| DELETE /moi | tous | `{"mot_de_passe"}` | `{"supprime": true}` | `identifiants_invalides` 401, `conflit` 409 si solde non nul |
| POST /assistance/signalements | tous | `{"sujet", "message", "reference_type", "reference_id"}` | signalement créé | `validation` |
| GET /assistance/signalements | tous | pagination | ses signalements et leurs réponses | 401 |

## Menus et plats

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /menus/semaine | convive, parent, agent | `?du=` | 7 jours : date, état, heure limite, plats avec prix du profil, créneaux et places restantes | `validation` |
| GET /menus/{date} | convive, parent, agent | aucun | menu du jour détaillé | `introuvable` 404 |
| GET /plats/{id} | tous sauf public | aucun | plat, allergènes, régimes, note moyenne, avis publiés | `introuvable` 404 |
| GET /suggestions | convive | aucun | plats suggérés d'après l'historique et les allergies | 401 |

## Réservations

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /reservations | convive | `{"date_service", "plat_id", "creneau_id"}` + `Cle-Geste` + `X-Preuve-Pin` | réservation avec `code_ticket` et prix débité | `heure_limite_depassee` 409, `creneau_complet` 409, `reservation_existante` 409, `solde_insuffisant` 402, `menu_non_publie` 409, `pin_requis` 428 |
| GET /reservations | convive | `?du=&au=` pagination | liste des réservations | 401 |
| GET /reservations/{id} | convive | aucun | réservation détaillée | `introuvable` 404, `acces_refuse` 403 |
| GET /reservations/{id}/ticket | convive | aucun | `{"code_ticket", "date_service", "creneau", "plat", "etat"}` | `introuvable` 404 |
| POST /reservations/{id}/annuler | convive | `Cle-Geste` | `{"annulee": true, "rembourse_xof": 1000}` | `annulation_trop_tard` 409, `deja_servie` 409 |

## Porte-monnaie

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /porte-monnaie | convive, parent | aucun | `{"solde_xof", "devise", "gele", "a_jour_le"}` | 401 |
| GET /porte-monnaie/mouvements | convive, parent | `?du=&au=` pagination | mouvements avec sens, motif, montant, solde après | 401 |
| GET /porte-monnaie/{utilisateur_id} | parent | aucun | solde d'un enfant lié | `acces_refuse` 403 |

## Paiements

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /paiements/recharge | convive, parent | `{"beneficiaire_id", "montant_xof", "operateur", "telephone_payeur"}` + `Cle-Geste` | `{"paiement_id", "etat": "en_attente", "mode", "url_redirection"}` | `montant_invalide` 422, `beneficiaire_interdit` 403, `operateur_inconnu` 422, `mode_paiement_invalide` 409 |
| GET /paiements/{id} | convive, parent | aucun | état du paiement | `introuvable` 404, `acces_refuse` 403 |
| GET /paiements | convive, parent | pagination | ses paiements | 401 |
| POST /paiements/webhook/test | public, signé | charge utile GeniusPay de test | `{"recu": true}` | `signature_invalide` 401 |
| POST /paiements/webhook/reel | public, signé | charge utile GeniusPay réelle | `{"recu": true}` | `signature_invalide` 401 |
| GET /paiements/retour | public | `?reference=` | page de retour, redirige vers l'application | `introuvable` 404 |

Le webhook vérifie la signature, écrit le paiement et le mouvement dans une seule transaction, puis envoie la
notification après la validation. Un second appel avec la même référence ne crédite rien.

## Liens de paiement

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /liens-paiement | convive, parent | `{"beneficiaire_id", "montant_xof", "message", "expire_dans_heures"}` | `{"id", "url_publique", "expire_le"}` | `beneficiaire_interdit` 403, `validation` |
| GET /liens-paiement | convive, parent | pagination | ses liens et leur état | 401 |
| DELETE /liens-paiement/{id} | convive, parent | aucun | `{"annule": true}` | `deja_paye` 409 |
| GET /public/liens-paiement/{jeton} | public | aucun | `{"beneficiaire_prenom", "montant_xof", "message", "etat"}` | `introuvable` 404, `lien_expire` 410 |
| POST /public/liens-paiement/{jeton}/payer | public | `{"operateur", "telephone_payeur", "montant_xof"}` + `Cle-Geste` | `{"paiement_id", "url_redirection"}` | `lien_expire` 410, `deja_paye` 409 |

## Parent

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /parent/liaison | parent | `{"code_liaison"}` | `{"enfant": {...}, "etat": "actif"}` | `code_invalide` 400, `deja_lie` 409 |
| GET /parent/enfants | parent | aucun | enfants liés avec solde, allergies, seuil | 401 |
| DELETE /parent/enfants/{id} | parent | aucun | `{"delie": true}` | `introuvable` 404 |
| GET /parent/enfants/{id}/repas | parent | `?du=&au=` | repas réservés et servis | `acces_refuse` 403 |
| PUT /parent/enfants/{id}/seuil | parent | `{"seuil_alerte_solde"}` | seuil enregistré | `validation` |
| PUT /parent/enfants/{id}/allergies | parent | `{"allergies": []}` | allergies enregistrées | `validation` |

## Avis et suggestions

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /avis | convive | `{"reservation_id", "note_gout", "note_quantite", "note_temperature", "note_attente", "commentaire"}` + `Cle-Geste` | avis en état `a_examiner` | `repas_non_servi` 409, `avis_existant` 409, `validation` |
| GET /avis/plat/{plat_id} | tous sauf public | pagination | avis publiés et moyennes par critère | `introuvable` 404 |
| GET /avis/miens | convive | pagination | ses avis avec leur état | 401 |
| POST /suggestions | convive | `{"message", "plat_souhaite"}` | suggestion enregistrée | `validation` |

## Agent

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /agent/service | agent | aucun | service en cours : créneau, attendus, servis, restants | `aucun_service` 404 |
| POST /agent/scan | agent | `{"code_ticket", "scanne_le"}` + `Cle-Geste` | `{"resultat": "accepte", "convive", "plat", "creneau"}` | `ticket_inconnu` 404, `deja_servi` 409, `mauvais_jour` 409, `reservation_annulee` 409 |
| POST /agent/scan/file | agent | `[{"code_ticket", "scanne_le", "cle_unique"}]` | résultat par clé unique | `validation` |
| GET /agent/service/jour | agent | `?date=` | liste des réservations du jour par créneau | `acces_refuse` 403 |

## Anti-gaspillage

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /anti-gaspillage | convive | aucun | portions restantes après le dernier créneau, prix réduit, quantité | `aucune_offre` 404 |
| POST /anti-gaspillage/{id}/prendre | convive | `Cle-Geste` + `X-Preuve-Pin` | réservation immédiate avec ticket | `offre_epuisee` 409, `solde_insuffisant` 402, `offre_fermee` 409 |
| POST /admin/anti-gaspillage | admin | `{"menu_id", "plat_id", "quantite", "remise_pourcent", "ouvre_le", "ferme_le"}` | offre créée | `validation`, `service_en_cours` 409 |

## Notifications

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /appareils | tous | `{"jeton_fcm", "plateforme", "modele", "version_app"}` | appareil enregistré | `validation` |
| DELETE /appareils/{id} | tous | aucun | `{"supprime": true}` | `introuvable` 404 |
| GET /notifications | tous | pagination | notifications de l'utilisateur | 401 |
| POST /notifications/{id}/lue | tous | aucun | `{"lue": true}` | `introuvable` 404 |
| POST /notifications/toutes-lues | tous | aucun | `{"lues": 7}` | 401 |

## Back office admin

Toutes ces routes exigent le rôle `admin`. Chaque écriture ajoute une ligne dans `journal_admin`.

### Tableau de bord et rapports

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET /admin/tableau-bord | `?du=&au=` | repas servis, taux de présence, recettes XOF, gaspillage évité, plats les mieux notés, courbe par jour | `validation` |
| GET /admin/commandes-jour | `?date=` | commandes par plat et par créneau, total à cuisiner | `validation` |
| GET /admin/rapports/csv | `?type=&du=&au=` | fichier CSV | `type_inconnu` 422 |
| GET /admin/rapports/pdf | `?type=&du=&au=` | fichier PDF, préparé en tâche de fond | `type_inconnu` 422, `rapport_en_cours` 202 |

### Plats, tarifs, stocks

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET POST /admin/plats | plat complet, deux langues | liste ou plat créé | `validation`, `conflit` 409 |
| PATCH DELETE /admin/plats/{id} | champs modifiés | plat mis à jour ou désactivé | `introuvable` 404, `plat_utilise` 409 |
| GET POST /admin/tarifs | `{"plat_id", "profil", "prix_xof", "actif_du"}` | tarifs | `validation`, `chevauchement` 409 |
| GET POST /admin/ingredients | ingrédient | liste ou créé | `validation` |
| POST /admin/stocks/mouvement | `{"ingredient_id", "sens", "quantite", "commentaire"}` | mouvement et quantité après | `stock_insuffisant` 409 |
| GET /admin/stocks/alertes | aucun | ingrédients sous le seuil | 401 |

### Menus et créneaux

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET POST /admin/menus | `{"date_service", "heure_limite", "plats": [], "creneaux": []}` | menu créé en brouillon | `menu_existant` 409, `validation` |
| PATCH /admin/menus/{id} | champs modifiés | menu mis à jour | `menu_publie` 409 si une réservation existe |
| POST /admin/menus/{id}/publier | aucun | `{"etat": "publie"}`, notification aux convives après validation | `menu_vide` 409 |
| POST /admin/menus/{id}/annuler | `{"motif"}` | menu annulé, réservations remboursées | `deja_servi` 409 |
| POST /admin/menus/{id}/dupliquer | `{"vers_date"}` | nouveau brouillon | `menu_existant` 409 |
| GET POST PATCH /admin/creneaux | créneau | créneaux du menu | `chevauchement` 409 |

### Utilisateurs

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET /admin/utilisateurs | `?role=&recherche=` pagination | liste | `validation` |
| POST /admin/utilisateurs | `{"nom_complet", "identifiant", "role", "statut_convive"}` | compte créé, code de vérification selon le mode | `identifiant_deja_pris` 409 |
| PATCH /admin/utilisateurs/{id} | champs modifiés | compte mis à jour | `introuvable` 404 |
| POST /admin/utilisateurs/{id}/desactiver | `{"motif"}` | compte désactivé, sessions révoquées | `conflit` 409 |
| POST /admin/utilisateurs/{id}/ajustement | `{"sens", "montant_xof", "motif"}` + `Cle-Geste` | mouvement créé | `montant_invalide` 422, `motif_requis` 422 |
| POST /admin/utilisateurs/{id}/code-liaison | aucun | `{"code_liaison", "expire_le"}` | `role_invalide` 409 |

### Vérification des identifiants

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET /admin/verification | aucun | `{"telephone": {"livraison": "demo"}, "email": {"livraison": "reel"}, "compteurs": {...}}` | 403 |
| PUT /admin/verification | `{"canal", "livraison"}` | réglage enregistré | `canal_inconnu` 422, `livraison_inconnue` 422 |
| GET /admin/verification/journal | `?canal=&etape=` pagination | journal avec identifiants masqués | `validation` |
| POST /admin/verification/code | `{"utilisateur_id", "canal", "usage"}` | `{"code", "expire_le"}`, code à dicter à l'utilisateur | `introuvable` 404, `trop_de_requetes` 429 |

### Paiements, avis, notifications, réglages

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET /admin/paiements | `?etat=&mode=` pagination | paiements | `validation` |
| GET /admin/mode-paiement | aucun | `{"mode": "test"}` | 403 |
| PUT /admin/mode-paiement | `{"mode": "reel"}` | mode enregistré, tracé au journal | `mode_inconnu` 422, `cles_absentes` 409 |
| GET /admin/liens-paiement | pagination | tous les liens | 403 |
| GET /admin/avis | `?etat=` pagination | avis à modérer | `validation` |
| POST /admin/avis/{id}/publier | aucun | avis publié | `introuvable` 404 |
| POST /admin/avis/{id}/refuser | `{"motif"}` | avis refusé | `motif_requis` 422 |
| POST /admin/avis/{id}/repondre | `{"reponse"}` | réponse de la cantine | `avis_non_publie` 409 |
| GET /admin/suggestions | pagination | suggestions des convives | 403 |
| GET /admin/signalements | `?etat=` pagination | signalements | `validation` |
| POST /admin/signalements/{id}/repondre | `{"reponse", "etat"}` | signalement traité | `introuvable` 404 |
| POST /admin/notifications | `{"cible": {"role", "statut", "utilisateur_ids"}, "titre", "corps"}` | `{"destinataires": 128}` | `cible_vide` 422 |
| GET PUT /admin/parametres | `{"cle", "valeur"}` | paramètres | `cle_inconnue` 404, `non_modifiable` 409 |
| GET /admin/journal | `?admin_id=&cible_type=` pagination | journal des actions | `validation` |
| POST /admin/demo/reinitialiser | `{"confirmation": "REINITIALISER"}` | `{"tables_videes": [], "jeu_recree": true}` | `confirmation_invalide` 422, `mode_reel` 409 |

La remise à zéro refuse de s'exécuter si le mode de paiement est `reel`, et ne touche jamais les comptes
admin.
