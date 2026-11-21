# Modèle de données

PostgreSQL. Toutes les clés primaires sont des `uuid` par défaut `gen_random_uuid()`, sauf mention contraire.
Toutes les dates sont des `timestamptz` en UTC. Tous les montants sont des `integer` en XOF, jamais de
flottant. Chaque table porte `cree_le timestamptz not null default now()` et, quand elle est modifiable,
`modifie_le timestamptz not null default now()`.

La colonne « propriétaire » nomme le bloc de `docs/PLAN.md` qui crée la table, écrit sa migration et reste
responsable de ses évolutions. Une autre session qui a besoin d'un changement le demande dans son compte rendu
au lieu de le faire.

Règles communes :
- Aucune valeur NULL qui voudrait dire « tout ». Une portée vide se représente par une ligne explicite.
- Toute suppression est logique (`supprime_le`), jamais un DELETE sans condition.
- Les états sont des colonnes `text` avec une contrainte `check` : pas de type enum, pour que le back office
  puisse évoluer sans migration de type.
- Chaque index se crée par une migration Alembic.

## utilisateurs
Propriétaire : A3.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| nom_complet | text | not null |
| telephone | text | unique, format +225XXXXXXXXXX, nullable si e-mail fourni |
| email | text | unique en minuscules, nullable si téléphone fourni |
| mot_de_passe_hache | text | not null |
| role | text | not null, check in (convive, parent, agent, admin) |
| statut_convive | text | null sauf role convive, check in (eleve, etudiant, employe) |
| langue | text | not null default fr, check in (fr, en) |
| pin_hache | text | null |
| pin_essais | integer | not null default 0 |
| pin_bloque_jusqua | timestamptz | null |
| email_verifie_le | timestamptz | null |
| telephone_verifie_le | timestamptz | null |
| google_id | text | unique, null |
| apple_id | text | unique, null |
| profil_complet | boolean | not null default true |
| allergies | text[] | not null default tableau vide |
| seuil_alerte_solde | integer | null, >= 0 |
| actif | boolean | not null default true |
| supprime_le | timestamptz | null |

Contraintes et index : `check (telephone is not null or email is not null)` ; unique sur `lower(email)` ;
unique sur `telephone` ; index sur `role`, sur `statut_convive`, sur `google_id`, sur `apple_id`.
Un compte créé par Google ou Apple reçoit un mot de passe haché aléatoire inutilisable et `profil_complet` à
faux jusqu'à la finalisation du profil, ce qui garde la colonne obligatoire.

## sessions
Propriétaire : A3. Une ligne par appareil connecté, pour la déconnexion à distance.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| utilisateur_id | uuid | fk utilisateurs, on delete cascade, not null |
| jeton_rafraichissement_hache | text | not null, unique |
| appareil_nom | text | not null |
| plateforme | text | not null, check in (android, ios, web) |
| adresse_ip | inet | null |
| derniere_activite | timestamptz | not null default now() |
| expire_le | timestamptz | not null |
| revoquee_le | timestamptz | null |

Index : `utilisateur_id`, `expire_le`.

## liens_parent_enfant
Propriétaire : A5.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| parent_id | uuid | fk utilisateurs, not null |
| enfant_id | uuid | fk utilisateurs, not null |
| code_liaison | text | not null, unique, 8 caractères |
| etat | text | not null, check in (en_attente, actif, revoque) |
| cree_par | uuid | fk utilisateurs, not null |
| valide_le | timestamptz | null |

Index : unique `(parent_id, enfant_id)` ; index sur `enfant_id` ; unique sur `code_liaison`.

## plats
Propriétaire : A4.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| nom_fr | text | not null |
| nom_en | text | not null |
| description_fr | text | not null default chaîne vide |
| description_en | text | not null default chaîne vide |
| categorie | text | not null, check in (entree, plat, accompagnement, dessert, boisson) |
| image_url | text | null |
| allergenes | text[] | not null default tableau vide |
| regimes | text[] | not null default tableau vide, valeurs sans_porc, sans_gluten, vegetarien, halal |
| calories | integer | null, >= 0 |
| actif | boolean | not null default true |
| supprime_le | timestamptz | null |

Index : `categorie`, `actif`. Unique sur `lower(nom_fr)` parmi les lignes non supprimées.

## tarifs
Propriétaire : A4. Le prix dépend du plat et du profil du convive.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| plat_id | uuid | fk plats, not null |
| profil | text | not null, check in (eleve, etudiant, employe, visiteur) |
| prix_xof | integer | not null, >= 0 |
| actif_du | timestamptz | not null |
| actif_au | timestamptz | null |

Index : unique `(plat_id, profil, actif_du)` ; index sur `(plat_id, profil)`.

## menus
Propriétaire : A4. Un menu par jour de service.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| date_service | date | not null, unique |
| etat | text | not null, check in (brouillon, publie, annule) |
| heure_limite | time | not null, heure limite de réservation en UTC |
| publie_le | timestamptz | null |
| publie_par | uuid | fk utilisateurs, null |

Index : unique `date_service` ; index sur `etat`.

## menus_plats
Propriétaire : A4. Les plats proposés un jour donné, avec la quantité prévue.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| menu_id | uuid | fk menus, on delete cascade, not null |
| plat_id | uuid | fk plats, not null |
| quantite_prevue | integer | not null, >= 0 |
| ordre | integer | not null default 0 |

Index : unique `(menu_id, plat_id)` ; index sur `menu_id`.

## creneaux
Propriétaire : A4. Les créneaux de passage d'un jour, avec leur capacité.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| menu_id | uuid | fk menus, on delete cascade, not null |
| debut | time | not null, UTC |
| fin | time | not null, UTC, > debut |
| capacite | integer | not null, >= 0 |
| actif | boolean | not null default true |

Index : unique `(menu_id, debut)` ; index sur `menu_id`.

## reservations
Propriétaire : A5. Une seule réservation vivante par convive et par jour.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| convive_id | uuid | fk utilisateurs, not null |
| menu_id | uuid | fk menus, not null |
| creneau_id | uuid | fk creneaux, not null |
| plat_id | uuid | fk plats, not null |
| date_service | date | not null |
| prix_xof | integer | not null, >= 0, prix figé à la réservation |
| etat | text | not null, check in (confirmee, servie, annulee, expiree) |
| code_ticket | text | not null, unique, contenu du QR |
| servie_le | timestamptz | null |
| servie_par | uuid | fk utilisateurs, null |
| annulee_le | timestamptz | null |
| cle_unique | text | not null, unique, clé de geste envoyée par le client |

Index : unique partiel `(convive_id, date_service)` sur les lignes `etat in (confirmee, servie)` ; unique sur
`code_ticket` ; unique sur `cle_unique` ; index sur `(date_service, creneau_id)` et sur `(menu_id, etat)`.

## porte_monnaie
Propriétaire : A5. Une ligne par utilisateur. Ne contient pas de solde modifiable.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| utilisateur_id | uuid | fk utilisateurs, not null, unique |
| devise | text | not null default XOF, check = XOF |
| gele | boolean | not null default false |
| solde_cache_xof | integer | not null default 0, valeur de lecture rapide |
| recalcule_le | timestamptz | not null default now() |

`solde_cache_xof` n'est jamais écrit à la main : il est recalculé dans la même transaction que l'insertion
d'un mouvement, à partir de la somme des mouvements, puis relu pour vérification.

## mouvements
Propriétaire : A5. Le solde n'existe que par ces lignes. Table en ajout seul.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| porte_monnaie_id | uuid | fk porte_monnaie, not null |
| sens | text | not null, check in (credit, debit) |
| montant_xof | integer | not null, > 0 |
| motif | text | not null, check in (recharge, reservation, annulation, remboursement, ajustement_admin, anti_gaspillage) |
| reference_type | text | null, check in (reservation, paiement, lien_paiement) |
| reference_id | uuid | null |
| solde_apres_xof | integer | not null, >= 0 |
| cle_unique | text | not null, unique |
| cree_par | uuid | fk utilisateurs, null, renseigné pour un ajustement admin |

Index : `(porte_monnaie_id, cree_le desc)` ; unique sur `cle_unique` ; index sur `(reference_type, reference_id)`.
Aucune mise à jour ni suppression. Une correction se fait par un mouvement inverse.

## paiements
Propriétaire : A6. Recharges Mobile Money par GeniusPay.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| payeur_id | uuid | fk utilisateurs, null si lien public |
| beneficiaire_id | uuid | fk utilisateurs, not null |
| lien_paiement_id | uuid | fk liens_paiement, null |
| montant_xof | integer | not null, > 0 |
| operateur | text | not null, check in (orange, mtn, moov, wave) |
| telephone_payeur | text | not null |
| mode | text | not null, check in (test, reel) |
| etat | text | not null, check in (initie, en_attente, reussi, echoue, expire) |
| reference_geniuspay | text | unique, null tant que non initié chez le prestataire |
| cle_geste | text | not null, unique |
| charge_utile_webhook | jsonb | null |
| motif_echec | text | null |
| confirme_le | timestamptz | null |

Index : unique `cle_geste` ; unique `reference_geniuspay` ; index sur `(beneficiaire_id, cree_le desc)`, sur
`etat`, sur `mode`.
Le crédit du porte-monnaie se fait dans la transaction qui passe le paiement à `reussi`, jamais avant. La
notification part après la validation de cette transaction.

## liens_paiement
Propriétaire : A6. Un parent ou un convive demande à un proche de payer.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| createur_id | uuid | fk utilisateurs, not null |
| beneficiaire_id | uuid | fk utilisateurs, not null |
| jeton_public | text | not null, unique, utilisé dans l'URL |
| montant_xof | integer | null si montant libre |
| message | text | not null default chaîne vide |
| etat | text | not null, check in (actif, paye, expire, annule) |
| expire_le | timestamptz | not null |
| paiement_id | uuid | fk paiements, null |

Index : unique `jeton_public` ; index sur `(createur_id, cree_le desc)`, sur `etat`.

## avis
Propriétaire : A9. Note d'un plat servi, modérée par l'admin.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| auteur_id | uuid | fk utilisateurs, not null |
| plat_id | uuid | fk plats, not null |
| reservation_id | uuid | fk reservations, not null |
| note_gout | integer | not null, 1 à 5 |
| note_quantite | integer | not null, 1 à 5 |
| note_temperature | integer | not null, 1 à 5 |
| note_attente | integer | not null, 1 à 5 |
| commentaire | text | not null default chaîne vide |
| etat | text | not null default a_examiner, check in (a_examiner, publie, refuse) |
| motif_refus | text | null |
| reponse_cantine | text | null |
| repondu_par | uuid | fk utilisateurs, null |
| repondu_le | timestamptz | null |
| cle_unique | text | not null, unique, clé d'envoi du client hors ligne |

Index : unique `(auteur_id, reservation_id)` ; unique `cle_unique` ; index sur `(plat_id, etat)`.

## ingredients
Propriétaire : A8. Stock de matière, pour l'alerte et le rapport.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| nom | text | not null, unique en minuscules |
| unite | text | not null, check in (kg, g, l, cl, piece) |
| quantite_actuelle | numeric(12,3) | not null default 0, >= 0 |
| seuil_alerte | numeric(12,3) | not null default 0, >= 0 |
| actif | boolean | not null default true |

Index : unique sur `lower(nom)` ; index partiel sur les lignes sous le seuil.

## mouvements_stock
Propriétaire : A8. Table en ajout seul.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| ingredient_id | uuid | fk ingredients, not null |
| sens | text | not null, check in (entree, sortie, perte, inventaire) |
| quantite | numeric(12,3) | not null, > 0 |
| quantite_apres | numeric(12,3) | not null, >= 0 |
| reference_type | text | null, check in (reservation, service, achat) |
| reference_id | uuid | null |
| commentaire | text | not null default chaîne vide |
| cree_par | uuid | fk utilisateurs, not null |

Index : `(ingredient_id, cree_le desc)`.

## appareils
Propriétaire : A7, sauf les colonnes de biométrie qui appartiennent à A3b. Un appareil connu, pour les
notifications et la biométrie.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| utilisateur_id | uuid | fk utilisateurs, on delete cascade, not null |
| session_id | uuid | fk sessions, null |
| jeton_fcm | text | unique, null |
| plateforme | text | not null, check in (android, ios, web) |
| modele | text | not null default chaîne vide |
| version_app | text | not null default chaîne vide |
| secret_biometrique_hache | text | null |
| biometrie_active | boolean | not null default false |
| derniere_vue_le | timestamptz | not null default now() |

Index : unique `jeton_fcm` ; index sur `utilisateur_id`.

## notifications
Propriétaire : A7. Notification dans l'application, doublée ou non d'un envoi push.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| destinataire_id | uuid | fk utilisateurs, not null |
| type | text | not null, check in (menu_publie, rappel_limite, solde_bas, paiement_recu, repas_servi, anti_gaspillage, message_admin) |
| titre | text | not null |
| corps | text | not null |
| donnees | jsonb | not null default objet vide |
| lue_le | timestamptz | null |
| envoi_push | text | not null default non_demande, check in (non_demande, en_attente, envoye, echoue) |
| envoye_le | timestamptz | null |

Index : `(destinataire_id, cree_le desc)` ; index partiel sur les non lues.

## parametres
Propriétaire : A1. Tout réglage modifiable du produit.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| cle | text | pk |
| valeur | jsonb | not null |
| type_valeur | text | not null, check in (texte, entier, booleen, heure, liste, objet) |
| libelle_fr | text | not null |
| libelle_en | text | not null |
| groupe | text | not null, check in (service, paiement, verification, notification, general) |
| modifiable | boolean | not null default true |
| modifie_par | uuid | fk utilisateurs, null |

Clés prévues au départ : `heure_limite_defaut`, `delai_annulation_minutes`, `capacite_creneau_defaut`,
`mode_paiement` (test ou reel), `livraison_verification_telephone` (demo ou reel),
`livraison_verification_email` (demo ou reel), `duree_code_verification_minutes`, `essais_code_max`,
`seuil_alerte_solde_defaut`, `remise_anti_gaspillage_pourcent`, `langues_actives`.

## journal_admin
Propriétaire : A1. Table en ajout seul, toute action sensible du back office.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| admin_id | uuid | fk utilisateurs, not null |
| action | text | not null |
| cible_type | text | not null |
| cible_id | uuid | null |
| avant | jsonb | null |
| apres | jsonb | null |
| adresse_ip | inet | null |

Index : `(admin_id, cree_le desc)` ; index sur `(cible_type, cible_id)`.

## codes_verification
Propriétaire : A3.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| utilisateur_id | uuid | fk utilisateurs, null tant que le compte n'existe pas |
| identifiant_vise | text | not null, numéro ou e-mail visé |
| canal | text | not null, check in (telephone, email) |
| code_hache | text | not null |
| origine | text | not null, check in (api, admin, parent) |
| usage | text | not null, check in (verification_compte, reinitialisation_mot_de_passe, secours, changement_identifiant) |
| mode_livraison | text | not null, check in (demo, reel) |
| essais | integer | not null default 0 |
| essais_max | integer | not null default 5 |
| expire_le | timestamptz | not null |
| utilise_le | timestamptz | null |

Index : `(identifiant_vise, canal, usage)` ; index sur `expire_le`.
Le code en clair ne revient dans la réponse que si `mode_livraison` vaut `demo`. Six chiffres pour le
téléphone, cinq caractères majuscules et chiffres pour l'e-mail.

## journal_verifications
Propriétaire : A3. Table en ajout seul, sans identifiant en clair.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| identifiant_masque | text | not null, par exemple +225 07 XX XX 12 ou j***@gmail.com |
| canal | text | not null, check in (telephone, email) |
| etape | text | not null, check in (demande, envoye, verifie, echec) |
| raison | text | null, check in (code_faux, expire, trop_essais, envoi_impossible) |
| adresse_ip | inet | null |

Index : `(cree_le desc)` ; index sur `(canal, etape)`.

## file_scans
Propriétaire : A5. Scans faits hors ligne par l'agent, envoyés au retour du réseau.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| agent_id | uuid | fk utilisateurs, not null |
| code_ticket | text | not null |
| reservation_id | uuid | fk reservations, null si ticket inconnu |
| scanne_le | timestamptz | not null, heure du scan sur l'appareil |
| recu_le | timestamptz | not null default now() |
| cle_unique | text | not null, unique |
| resultat | text | not null, check in (accepte, deja_servi, inconnu, mauvais_jour, annule) |
| detail | text | not null default chaîne vide |

Index : unique `cle_unique` ; index sur `(agent_id, recu_le desc)` ; index sur `code_ticket`.
Un renvoi du même `cle_unique` ne crée rien et renvoie le résultat déjà enregistré.

## connexions_qr
Propriétaire : A3b. Connexion d'un ordinateur ou d'une tablette par QR scanné avec le téléphone connecté.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| jeton_demande | text | not null, unique, contenu du QR |
| etat | text | not null, check in (en_attente, lu, confirme, refuse, expire) |
| appareil_demandeur | text | not null |
| adresse_ip_demandeur | inet | null |
| utilisateur_id | uuid | fk utilisateurs, null tant que non confirmé |
| session_id | uuid | fk sessions, null |
| lu_le | timestamptz | null |
| confirme_le | timestamptz | null |
| expire_le | timestamptz | not null, deux minutes après la création |

Index : unique `jeton_demande` ; index sur `expire_le`.

## avatars
Propriétaire : A3c. Images de profil, prédéfinies ou envoyées.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| utilisateur_id | uuid | fk utilisateurs, null pour un avatar du catalogue |
| type | text | not null, check in (catalogue, envoye) |
| url | text | not null |
| actif | boolean | not null default true |

Index : index partiel unique sur `utilisateur_id` parmi les avatars envoyés actifs.

## signalements
Propriétaire : A3c. Assistance et signalements envoyés depuis l'application.

| Colonne | Type | Contraintes |
| --- | --- | --- |
| id | uuid | pk |
| auteur_id | uuid | fk utilisateurs, not null |
| sujet | text | not null, check in (repas, paiement, compte, application, autre) |
| message | text | not null |
| reference_type | text | null, check in (reservation, paiement, avis) |
| reference_id | uuid | null |
| etat | text | not null default ouvert, check in (ouvert, en_cours, clos) |
| reponse | text | null |
| traite_par | uuid | fk utilisateurs, null |
| traite_le | timestamptz | null |

Index : `(etat, cree_le desc)` ; index sur `auteur_id`.

## Vues de lecture
Aucune vue matérialisée au départ. Le tableau de bord lit des agrégats calculés à la demande sur
`reservations`, `mouvements` et `paiements`, avec les index ci-dessus. Si une page devient lente, on ajoute un
index par migration avant d'envisager une vue.
