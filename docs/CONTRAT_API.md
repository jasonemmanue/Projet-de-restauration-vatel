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
- Compte à vérifier : tant que l'identifiant n'est pas vérifié, toute route autre que `GET /moi`, la
  vérification et la déconnexion répond 403 `a_verifier`.
- Action sensible du back office : en-tête `X-Mot-De-Passe-Actions`, contrôlé après le rôle admin.

Quand un code est demandé : à l'inscription, et à la connexion quand la session a dormi plus de cinq jours.
Nulle part ailleurs. Dans les deux cas, l'application enchaîne seule sur l'écran du code.

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
| POST /auth/inscription | public | `{"type": "telephone"\|"email", "identifiant", "mot_de_passe", "prenom", "nom", "role": "convive"\|"parent", "statut_convive", "conditions_acceptees": true, "appareil": {"nom", "plateforme"}}` ; `statut_convive` (eleve, etudiant, employe, autre) obligatoire pour un convive, absent pour un parent ; `appareil` facultatif | 201 `{"utilisateur_id", "etat": "a_verifier", "canal", "jeton", "jeton_rafraichissement", "expire_dans", "utilisateur"}` : le compte naît à vérifier et sa session s'ouvre | `compte_existe` 409, `identifiant_invalide` 422, `mot_de_passe_faible` 422, `conditions_requises` 422, `validation` 422 |
| POST /auth/connexion | public | `{"identifiant", "mot_de_passe", "appareil"}` ; identifiant numéro ou e-mail, `appareil` facultatif | `{"etape": "connecte", "jeton", "jeton_rafraichissement", "expire_dans", "utilisateur"}` ; `utilisateur.verifie` dit si le compte est vérifié. Si le compte vérifié n'a pas ouvert l'application depuis `session_inactivite_jours` (5), ou ne l'a jamais ouverte : `{"etape": "code_requis", "canal", "mode_livraison", "expire_le", "code_demo"}`, sans jeton, à confirmer par la route suivante | `identifiants_invalides` 401 (message unique, compte existant ou non), `trop_de_tentatives` 429 (blocage par compte et par IP), `compte_desactive` 403, `trop_de_requetes` 429 |
| POST /auth/connexion/confirmer | public | `{"identifiant", "code", "appareil"}` ; le code reçu après le mot de passe | `{"etape": "connecte", "jeton", "jeton_rafraichissement", "expire_dans", "utilisateur"}` | `code_invalide` 400, `code_expire` 410, `trop_essais` 429 |
| POST /auth/verification/envoyer | public | `{"identifiant", "canal", "usage": "verification_compte"}` | `{"mode_livraison": "demo", "code_demo": "123456", "expire_le"}` ; `code_demo` seulement en démo et pour un compte à vérifier : réponse identique sinon, sans `code_demo` | `trop_de_requetes` 429 (un code par minute, 5 par jour, limite par IP), `trop_essais` 429, `envoi_impossible` 502 (livraison `reel` avant E1) |
| POST /auth/verification/confirmer | public | `{"identifiant", "canal", "usage": "verification_compte", "code"}` ; code lu sans casse ni espaces | `{"verifie": true}` ; la session ouverte à l'inscription reste valable | `code_invalide` 400, `code_expire` 410, `trop_essais` 429 (au sixième code faux, 15 min) |
| POST /auth/mot-de-passe/oublie | public | `{"identifiant", "canal"}` | `{"mode_livraison", "expire_le", "code_demo"}` ; même réponse que le compte existe ou non, jamais de `code_demo` pour un compte inconnu | `trop_de_requetes` 429, `envoi_impossible` 502 |
| POST /auth/mot-de-passe/reinitialiser | public | `{"identifiant", "canal", "code", "nouveau_mot_de_passe"}` ; `canal` facultatif | `{"reinitialise": true}` ; toutes les sessions du compte sont fermées | `code_invalide` 400, `code_expire` 410, `trop_essais` 429, `mot_de_passe_faible` 422 |
| POST /auth/mot-de-passe/changer | tous | `{"ancien", "nouveau"}` | `{"change": true, "pin_a_redefinir": true}` | `identifiants_invalides` 401, `mot_de_passe_faible` 422 |
| POST /auth/code-secours | admin, parent | `{"utilisateur_id"}` | `{"code", "expire_le"}` | `acces_refuse` 403, `introuvable` 404 |
| POST /auth/rafraichir | public | `{"jeton_rafraichissement"}` ; prolonge la session de `session_inactivite_jours` | `{"jeton", "jeton_rafraichissement", "expire_dans"}` | `jeton_invalide` 401, `session_revoquee` 401 |
| POST /auth/deconnexion | tous, même non vérifié | aucun | `{"deconnecte": true}` ; ferme la session du jeton présenté | `non_authentifie` 401 |
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
| GET /moi/chiffres | convive, parent | `?du=&au=` | `{"repas", "depense_xof", "plat_favori", "repas_non_reclames"}` | `validation` |
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
| GET /menus/semaine | convive, parent, agent | `?du=` | 7 jours : date, état, moment du gel de ce jour (`gele_le`), `prix_xof` du jour pour le profil du demandeur, et les plats groupés par service (`entree`, `resistance`, `sortie`) avec leur `prix_supplement_xof` | `validation` |
| GET /menus/{date} | convive, parent, agent | aucun | menu du jour détaillé | `introuvable` 404 |
| GET /plats/{id} | tous sauf public | aucun | plat, allergènes, régimes, note moyenne, avis publiés | `introuvable` 404 |
| GET /medias/{chemin} | public | aucun | image du volume (photos des plats `plats/…`, images de démo `demo/…`), en cache une journée ; jamais hors du dossier des médias | `introuvable` 404 |
| GET /suggestions | convive | aucun | plats suggérés d'après l'historique et les allergies | 401 |

## Réservations

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /reservations | convive | `{"portee": "jour" \| "semaine" \| "mois", "debut", "jours": [{"date_service", "plats": [{"plat_id", "quantite"}]}]}` ; au moins un plat par jour, aucune heure ni créneau à choisir + `Cle-Geste` + `X-Preuve-Pin` | le lot créé, son `total_xof` débité en une fois (menu du jour plus suppléments), et une commande par jour avec son `code_ticket` | `commande_gelee` 409 (jour déjà gelé), `reservation_existante` 409 (avec la liste des jours en cause), `solde_insuffisant` 402, `menu_non_publie` 409, `plat_hors_menu` 422, `aucun_service` 422, `pin_requis` 428 |
| GET /reservations/lots | convive | `?du=&au=` pagination | ses lots, avec portée, période, total et état | 401 |
| POST /reservations/lots/{id}/annuler | convive | `Cle-Geste` | `{"jours_annules": 4, "rembourse_xof": 6000}`, les jours déjà servis ou passés restent | `deja_servie` 409, `annulation_trop_tard` 409 |
| GET /reservations | convive | `?du=&au=` pagination | liste des réservations | 401 |
| GET /reservations/{id} | convive | aucun | réservation détaillée | `introuvable` 404, `acces_refuse` 403 |
| GET /reservations/{id}/ticket | convive | aucun | `{"code_ticket", "date_service", "plats": [{"nom", "service", "quantite"}], "etat"}` | `introuvable` 404 |
| PATCH /reservations/{id} | convive | `{"plats": [{"plat_id", "quantite"}]}` + `Cle-Geste` | commande modifiée, écart débité ou remboursé | `commande_gelee` 409, `deja_servie` 409, `plat_hors_menu` 422 |
| POST /reservations/{id}/annuler | convive | `Cle-Geste` | avant le gel `{"annulee": true, "rembourse_xof": 1500}` ; après le gel `{"supprimee": true, "rembourse_xof": 0}` | `deja_servie` 409 |

## Porte-monnaie

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| GET /porte-monnaie | convive, parent | aucun | `{"solde_xof", "devise", "gele", "a_jour_le"}` | 401 |
| GET /porte-monnaie/mouvements | convive, parent | `?du=&au=` pagination | mouvements avec sens, motif, montant, solde après | 401 |
| GET /porte-monnaie/{utilisateur_id} | parent | aucun | solde d'un enfant lié | `acces_refuse` 403 |

## Paiements

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /paiements/recharge | convive, parent | `{"beneficiaire_id", "montant_xof", "operateur", "telephone_payeur"}` ; `beneficiaire_id` absent vaut soi-même + `Cle-Geste` | `{"paiement_id", "etat": "en_attente", "mode", "url_redirection"}` | `montant_invalide` 422, `beneficiaire_interdit` 403, `operateur_inconnu` 422, `mode_paiement_invalide` 409 |
| GET /paiements/{id} | convive, parent | aucun | état du paiement | `introuvable` 404, `acces_refuse` 403 |
| GET /paiements | convive, parent | pagination | ses paiements | 401 |
| POST /paiements/webhook/test | public, signé | charge utile GeniusPay de test | `{"recu": true}` | `signature_invalide` 401 |
| POST /paiements/webhook/reel | public, signé | charge utile GeniusPay réelle | `{"recu": true}` | `signature_invalide` 401 |
| GET /paiements/retour | public | `?reference=` | page de retour, redirige vers l'application | `introuvable` 404 |

Services au choix, prix du menu : un convive prend les services qu'il veut, au moins un par jour, et paie le
prix du menu de ce jour pour son profil. Prendre seulement la résistance coûte autant que prendre les trois :
le menu est vendu comme un tout. Une part en plus, une deuxième résistance par exemple, s'ajoute au prix du
menu au tarif `prix_supplement_xof` du plat.

Ni heure ni créneau : un convive qui a commandé pour un jour vient manger quand il veut ce jour-là, aux
heures d'ouverture du réfectoire. Rien ne lui est imposé.

Gel de la commande, repas par repas : chaque jour se gèle `gel_jours_avant_service` jours avant son propre
service (1, la veille, par défaut), à `heure_gel_commandes` (18 h 00 par défaut) ; l'admin règle les deux. Une commande posée pour la semaine ne gèle pas d'un bloc : seuls
les jours dont la veille est passée sont figés, les autres restent modifiables. `PATCH /reservations/{id}`
porte donc sur un jour précis et ne refuse que celui-là, par `commande_gelee` 409. Un jour gelé peut encore
être supprimé, sans remboursement. Avant son gel, modification et annulation remboursent intégralement. Le réglage `services_obligatoires` de la table `parametres` peut un jour en
rendre un obligatoire ; il est vide par défaut.

Où vivent les images : sur un volume Railway monté sur `/app/medias`, pas dans l image du conteneur. Un
déploiement ne les écrase donc jamais. L API lit `STOCKAGE_DOSSIER` (ou `RAILWAY_VOLUME_MOUNT_PATH`), écrit
les fichiers sous ce chemin et les sert sur `/medias`. `STOCKAGE_URL_PUBLIQUE` donne le préfixe rendu dans
`image_url`, et `STOCKAGE_TAILLE_MAX_MO` la taille acceptée.

Qui peut être bénéficiaire : soi-même, quel que soit le statut du compte, ou un enfant lié quand le payeur est son parent. Toute autre valeur rend `beneficiaire_interdit` 403. Un lien de paiement se crée depuis n importe quel écran d argent de l application, pour se faire payer par un proche.

Le webhook vérifie la signature, écrit le paiement et le mouvement dans une seule transaction, puis envoie la
notification après la validation. Un second appel avec la même référence ne crédite rien.

## Liens de paiement

| Route | Rôle | Corps | Réponse | Erreurs |
| --- | --- | --- | --- | --- |
| POST /liens-paiement | convive, parent | `{"beneficiaire_id", "montant_xof", "message", "expire_dans_heures"}` ; `beneficiaire_id` absent vaut soi-même | `{"id", "url_publique", "expire_le"}` | `beneficiaire_interdit` 403, `validation` |
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
| GET /agent/service | agent | aucun | le service du jour : attendus, servis, restants, par service et par plat | `aucun_service` 404 |
| POST /agent/scan | agent | `{"code_ticket", "scanne_le"}` + `Cle-Geste` | `{"resultat": "accepte", "convive", "plats": [{"nom", "service", "quantite"}]}` | `ticket_inconnu` 404, `deja_servi` 409, `mauvais_jour` 409, `reservation_annulee` 409 |
| POST /agent/scan/file | agent | `[{"code_ticket", "scanne_le", "cle_unique"}]` | résultat par clé unique | `validation` |
| GET /agent/service/jour | agent | `?date=` | liste des commandes du jour, servies et non servies | `acces_refuse` 403 |

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
| GET /admin/tableau-bord | `?du=&au=` | repas servis, repas commandés mais non réclamés, taux de présence, recettes brutes XOF, frais GeniusPay supportés, net attendu après retrait, plats les mieux notés, courbe par jour | `validation` |
| GET /admin/commandes-jour | `?date=` | commandes par service et par plat, total de parts à cuisiner, suppléments compris | `validation` |
| GET /admin/previsions | `?du=&au=` | ce qui est déjà réservé pour les jours à venir : par jour, par service et par plat, le nombre de parts, en face de la quantité prévue au menu | `validation` |
| GET /admin/rapports/csv | `?type=&du=&au=` | fichier CSV | `type_inconnu` 422 |
| GET /admin/rapports/pdf | `?type=&du=&au=` | fichier PDF, préparé en tâche de fond | `type_inconnu` 422, `rapport_en_cours` 202 |

### Plats, tarifs, stocks

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET POST /admin/plats | plat complet, deux langues | liste ou plat créé | `validation`, `conflit` 409 |
| PATCH DELETE /admin/plats/{id} | champs modifiés | plat mis à jour ou désactivé | `introuvable` 404, `plat_utilise` 409 |
| PUT /admin/plats/{id}/photo | multipart `photo` | plat avec `image_url` (`/medias/plats/…`, rangée sur le volume) ; type vérifié par les premiers octets, taille bornée | `fichier_invalide` 422, `trop_lourd` 413, `introuvable` 404 |
| POST /admin/plats/{id}/image | fichier multipart, 5 Mo au plus, jpeg ou png | `{"image_url"}` | `fichier_invalide` 422, `trop_lourd` 413 |
| DELETE /admin/plats/{id}/image | aucun | `{"image_url": null}`, le plat retombe sur son aplat de secours | `introuvable` 404 |
| GET /medias/{fichier} | public | aucun | le fichier image, servi depuis le volume | `introuvable` 404 |
| GET POST /admin/tarifs | `{"profil", "prix_xof", "actif_du", "menu_id"}` ; `menu_id` absent vaut le tarif courant du profil | tarifs | `validation`, `chevauchement` 409 |
| GET POST /admin/ingredients | ingrédient | liste ou créé | `validation` |
| POST /admin/stocks/mouvement | `{"ingredient_id", "sens", "quantite", "commentaire"}` | mouvement et quantité après | `stock_insuffisant` 409 |
| GET /admin/stocks/alertes | aucun | ingrédients sous le seuil | 401 |

### Menus

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET POST /admin/menus | `{"date_service", "plats": []}` ; le gel suit les réglages `gel_jours_avant_service` et `heure_gel_commandes` | menu créé en brouillon | `menu_existant` 409, `validation` |
| POST /admin/menus/semaine/dupliquer | `{"de", "vers"}`, deux lundis | `{"crees": [], "ignores": []}` ; copie en brouillons, un jour déjà pris est laissé tel quel | `validation` 422 |
| PATCH /admin/menus/{id} | champs modifiés | menu mis à jour | `menu_publie` 409 si une réservation existe |
| POST /admin/menus/{id}/publier | aucun | `{"etat": "publie"}`, notification aux convives après validation | `menu_vide` 409 |
| POST /admin/menus/{id}/annuler | `{"motif"}` | menu annulé, réservations remboursées | `deja_servi` 409 |
| POST /admin/menus/{id}/dupliquer | `{"vers_date"}` | nouveau brouillon | `menu_existant` 409 |
| GET /admin/frais | `?du=&au=` | recettes brutes, frais GeniusPay retenus, frais de retrait estimés et net attendu, par jour et sur la période | `validation` |

### Utilisateurs

| Route | Corps | Réponse | Erreurs |
| --- | --- | --- | --- |
| GET /admin/utilisateurs | `?role=&recherche=` pagination | liste | `validation` |
| POST /admin/utilisateurs | `{"type", "identifiant", "mot_de_passe", "prenom", "nom", "role", "statut_convive"}` + `X-Mot-De-Passe-Actions` ; tous rôles, compte créé déjà vérifié | 201 compte créé | `compte_existe` 409, `mot_de_passe_actions_invalide` 403, `validation` 422 |
| DELETE /admin/utilisateurs/{id} | `X-Mot-De-Passe-Actions` | `{"supprime": true}` ; suppression logique : identifiants libérés, sessions fermées, ligne au journal | `introuvable` 404, `suppression_interdite` 409 (compte admin ou soi-même) |
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
