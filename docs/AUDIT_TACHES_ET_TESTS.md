# Audit des tâches et des tests

Format : une section par bloc, ajoutée au bas du fichier par la session qui termine ce bloc, avec cinq
rubriques dans cet ordre : Fait, Vérifié par Claude, À tester par vous, Résultat, Reste à faire. Personne ne
modifie une section déjà écrite par une autre session.

## Synthèse

À remplir en fin de journée.

| Bloc | Recette en ligne | Testé sur téléphone | Reste à faire |
| --- | --- | --- | --- |
| | | | |

---

## P00, cadrage du dépôt

**Fait.** Dépôt git initialisé sur `main`, `.gitignore` complet (Python, Flutter, Node, secrets, clés de
signature), `.env.example` commenté sans aucune valeur, `README.md`, dossiers `api/`, `app/` et `site/` avec
leur README. Documentation : `CLAUDE.md`, `docs/CAHIER.md`, `docs/MODELE_DONNEES.md` (26 tables),
`docs/CONTRAT_API.md` (toutes les routes `/api/v1`), `docs/CHARTE.md`, `docs/PLAN.md`,
`docs/AUDIT_TACHES_ET_TESTS.md`.

**Vérifié par Claude.** Aucun test automatique à ce stade, aucun code d'application écrit. `git check-ignore`
confirme que `uiux vatel/` et `firebase-debug.log` sont exclus. Les propriétaires de tables du modèle de
données ont été recalés sur les définitions d'étapes de `uiux vatel/PROMPTS_HACKATHON.md`.

**À tester par vous.**
1. Sur l'ordinateur, ouvrir `docs/CONTRAT_API.md` et vérifier qu'aucune fonctionnalité promise au jury n'y
   manque.
2. Sur l'ordinateur, ouvrir `docs/MODELE_DONNEES.md` et vérifier que la colonne propriétaire correspond bien
   au découpage des sessions prévu.
3. Sur GitHub, ouvrir le dépôt et vérifier qu'aucun secret n'apparaît dans `.env.example`.

**Résultat.**

**Reste à faire.** Remplir `[HEURE_LIMITE]` réelle dans `parametres` à l'étape A1. Décider si la maquette est
copiée dans `docs/maquette/`.

---

## P01, charte et marque

**Fait.** `docs/CHARTE.md` porte les deux palettes complètes reprises de `tokens.css`, les règles d'affichage,
les tailles de texte par type d'écran et le tableau de contraste. `docs/marque/` contient 9 SVG (symbole, logo
complet, versions noire et blanche, silhouette), les 3 graisses de Plus Jakarta Sans avec leur licence OFL, et
16 exports PNG dans `docs/marque/exports/`. Le nom est converti en tracés : aucune police n'est requise pour
afficher les SVG.

**Vérifié par Claude.** `python docs/marque/outils/contraste.py` : 32 paires mesurées, 23 conformes, 9
signalées sans modification. Les 16 PNG ont été relus un par un avec Pillow : dimensions exactes et couche
alpha présente là où elle est attendue (premier plan et monochrome Android, icône de notification). Planche de
contrôle visuel faite sur les écrans de lancement, la bannière Play Store, l'icône et les silhouettes. Aucune
recette en ligne : il n'y a pas encore d'API.

**À tester par vous.**
1. Sur ordinateur, ouvrir `docs/marque/exports/play-store-1024x500.png` et confirmer que c'est bien le logo
   retenu.
2. Sur téléphone Android, regarder `docs/marque/exports/icone-notification-96.png` sur un fond coloré : la
   silhouette doit rester lisible, blanche et sans halo.
3. Sur ordinateur, ouvrir `lancement-clair.png` puis `lancement-sombre.png` et vérifier que le logo reste
   lisible dans les deux modes.
4. Lire la section « Paires signalées » de `docs/CHARTE.md` et dire si l'on garde la palette telle quelle ou
   si l'on retouche les couleurs de succès, danger et alerte pour le mode clair.

**Résultat.**

**Reste à faire.** Reporter les valeurs de `docs/CHARTE.md` dans le thème Flutter à l'étape F1. Trancher les
paires de contraste signalées. Copier la maquette dans `docs/maquette/` pour que les chemins cités par
`CLAUDE.md` existent.

---

## A1, fondations de l'API

**Fait.** Structure FastAPI dans `api/` (configuration qui refuse de démarrer sans variable obligatoire ou avec
une valeur d'exemple, erreurs uniformes `{"code", "message"}` en fr et en, CORS en liste exacte, en-têtes de
sécurité, taille et débit limités), les 26 tables du modèle et la migration `0001` avec 91 index et 11
paramètres de départ, `GET /health` (aussi `/api/v1/sante`), module `python -m recette` avec le bloc « sante »,
Dockerfile non root, `railway.json`, `docker-compose.yml`.

**Vérifié par Claude.** `ruff check .` propre ; `pytest` : 40 tests verts sur un PostgreSQL 16 local (santé,
format d'erreur sur 404, 405, 413, 422, 429 et 500 sans trace, CORS refusé, écriture relue après validation,
annulation sur erreur, base migrée identique aux modèles). Image Docker lancée sur une base vide : migration
appliquée, utilisateur `vatel`, recette « sante » 13 contrôles, 0 échec, avec `--commit`. Recette en ligne pas
encore lancée : aucun service Railway n'est relié (étape A2).

**À tester par vous.**
1. Sur ordinateur, dans un terminal à la racine, lancer `railway link` et choisir le projet de l'API : la
   commande `railway status` doit ensuite nommer le projet.
2. Sur ordinateur, dans Railway, vérifier que le service API a pour dossier racine `/api` et porte les
   variables `DATABASE_URL`, `SECRET_KEY`, `ADMIN_ACTIONS_PASSWORD` et `CORS_ORIGINS` : le déploiement doit
   passer le contrôle `/health`.
3. Sur téléphone, mode clair puis mode sombre du navigateur, ouvrir `https://[URL_API]/health` : un JSON avec
   `"etat": "ok"` et un commit de 7 caractères s'affiche.
4. Sur ordinateur, ouvrir `https://[URL_API]/docs` : la page Swagger s'affiche ; avec `DOCS_ENABLED=false`
   dans Railway, la même adresse doit répondre 404 au format `{"code", "message"}`.

**Résultat.**

**Reste à faire.** A2 : déploiement Railway et recette « sante » en ligne. Le `.env.example` de la racine
emploie encore `JWT_SECRET`, `CORS_ORIGINES` et `APP_COMMIT` : l'API les accepte en alias, mais les noms de
référence sont ceux de `api/.env.example`.

---

## A2, déploiement de l'API sur Railway

**Fait.** Le service API construisait depuis la racine du dépôt (Railpack, échec) : réglé par la CLI sur le
dossier `/api` et le Dockerfile, contrôle `/health` sur 300 s, PostgreSQL ajouté sans domaine public, variables
posées sans qu'aucune valeur ne soit affichée ni écrite, domaine public créé pour l'API seule. Adresse de
production ajoutée à `docs/CONTRAT_API.md`.

**Vérifié par Claude.** Déploiement `891c7911` en SUCCESS sur le commit `314fc8b`, construit depuis
`api/Dockerfile`. Dans le conteneur : `alembic current` donne `0001 (head)`, 27 tables, 11 paramètres. En
ligne : `GET /health` en 200 avec `{"etat":"ok","version":"0.1.0","commit":"314fc8b","base":"ok"}` et les
quatre en-têtes de sécurité ; pré-vérification CORS d'une origine inconnue en 403
`{"code":"origine_refusee"}` sans `Access-Control-Allow-Origin` ; `http://` en 301 vers `https://` ; route
inconnue en 404 `{"code":"introuvable"}` ; `/docs` en 200. Recette : `python -m recette --url
https://projet-de-restauration-vatel-production.up.railway.app --bloc sante --commit 314fc8b` donne
13 contrôles, 0 échecs. Pas de nouveau code, donc ruff et pytest inchangés depuis A1 (40 tests verts).

**À tester par vous.**
1. Sur téléphone, en mode clair, ouvrir `https://projet-de-restauration-vatel-production.up.railway.app/health` :
   le JSON affiche `"etat":"ok"` et `"commit":"314fc8b"`.
2. Sur téléphone, en mode sombre, ouvrir la même adresse en `http://` : le navigateur bascule tout seul en
   `https://` et affiche le même JSON.
3. Sur ordinateur, ouvrir `https://projet-de-restauration-vatel-production.up.railway.app/docs` : Swagger
   s'affiche avec la seule route de santé.
4. Sur ordinateur, dans le tableau de bord Railway, vérifier que le service `Postgres` n'a aucun domaine
   public et que le service API est vert.

**Résultat.**

**Reste à faire.** `CORS_ORIGINS` vaut provisoirement `http://localhost:3000` : y ajouter l'URL web de
l'application (F8) et celle du site (S2) dès qu'elles existent. Lire l'adresse réelle du client derrière le
relais (`PROXIES_DE_CONFIANCE=1`) reste à confirmer en A3 avec les premières limites par route.

---

## F1, fondations de l'application Flutter

**Fait.** Projet `com.vatel.cantine` (Android, iOS, web) avec `lib/core` (thème des deux modes repris de la
charte, responsive à trois tailles, client API, stockage sécurisé, routes par rôle, socle hors ligne),
`lib/features` pour les neuf domaines et `lib/shared/widgets`. Traductions fr et en, polices embarquées,
icônes et écrans de lancement générés depuis `docs/marque/exports/`. Firebase branché sur `vatel-project`,
boutons Google, Apple et code QR qui ne se déforment pas, paiement ouvert à tout convive.

**Vérifié par Claude.** `flutter analyze` : « No issues found » (relancé après chaque lot). `flutter test` :
1 test vert, l'application démarre sur l'écran de bienvenue. `flutter build web` : réussi. Les trois
applications Firebase sont créées et leurs configurations téléchargées ; l'empreinte SHA-1 de débogage
`CA:8A:1F:20:6C:05:3D:5D:29:AE:7D:EF:BB:82:19:C9:AB:73:19:76` est enregistrée sur l'app Android. Recette en
ligne non lancée : l'application ne consomme encore aucune route.

**À tester par vous.**
1. Sur Android, `flutter run --dart-define=API_URL=https://<URL_API>/api/v1` : l'écran de bienvenue montre le
   symbole qui se dessine, puis les boutons Google et code QR, sans bouton Apple.
2. Sur iPhone ou dans Chrome sur PC, même écran : les boutons Google, Apple et code QR sont là, aucun logo
   écrasé, aucun texte coupé.
3. Sur Android, mode clair puis mode sombre du système : toutes les couleurs suivent, le contenu passe sous
   les barres système sans être masqué par l'encoche.
4. Sur Android, réduire les animations dans les réglages d'accessibilité, rouvrir l'application : le symbole
   s'affiche d'un coup, sans animation.

**Résultat.**

**Reste à faire.** F2 : inscription, connexion et vérification. Les écrans sont encore des pages d'attente
qui nomment leur étape. Firebase n'est pas encore utilisé pour les notifications (F7). Le code couleur Vatel
(bleu relevé à `#7CB5E3`) n'est pas appliqué : il attend le code officiel.

---

## Paiements ouverts à tous, et rythme de la semaine

**Fait.** Tout convive peut recharger son propre porte-monnaie, élève compris ; un parent lié peut en plus
recharger celui de ses enfants ; un employé, un étudiant ou un compte « autre » n'a besoin d'aucune liaison.
Le statut `autre` est ajouté à `utilisateurs.statut_convive` et à `tarifs.profil`. Le lien de paiement est
accessible depuis les écrans d'argent de tous les rôles. Le menu de la semaine est publié le jeudi pour la
semaine suivante : deux réglages (`jour_publication_menu`, `semaines_preparees_a_l_avance`) entrent dans
`parametres`.

**Vérifié par Claude.** Documents mis à jour : `CLAUDE.md`, `docs/CAHIER.md`, `docs/MODELE_DONNEES.md`,
`docs/CONTRAT_API.md`. Côté application, les routes `/convive/compte/recharge`,
`/convive/compte/lien-paiement` et `/parent/recharge/lien-paiement` existent ; `flutter analyze` propre.
Rien n'est vérifié côté API : ces règles sont à implémenter en A5 et A6.

**À tester par vous.**
1. Sur ordinateur, relire la ligne « Qui peut être bénéficiaire » de `docs/CONTRAT_API.md` et confirmer que
   c'est bien la règle voulue.
2. Dire si le statut `autre` doit avoir son propre tarif ou suivre celui des employés.

**Résultat.**

**Reste à faire.** A5 et A6 doivent appliquer la règle côté serveur : un bénéficiaire autre que soi-même ou
un enfant lié rend `beneficiaire_interdit` 403.

---

## Réservation par période et repas en trois services

**Fait.** Un repas se compose de l'entrée, de la résistance et de la sortie : `plats.categorie` ne connaît
plus que ces trois valeurs. Un convive réserve pour la portée qu'il choisit, jour, semaine ou mois : nouvelle
table `lots_reservation`, `reservations` rattachée à son lot avec un ticket par jour, et nouvelle table
`lignes_reservation` qui porte le plat choisi par service. Les prévisions de la cuisine se comptent sur ces
lignes, et `GET /admin/previsions` les rend par jour, par service et par plat.

**Vérifié par Claude.** Documents mis à jour et relus : `CLAUDE.md`, `docs/CAHIER.md`,
`docs/MODELE_DONNEES.md` (trois tables réécrites), `docs/CONTRAT_API.md` (réservation par période, lots,
ticket à trois services, menu groupé par service, prévisions). Côté application, les mots des trois services
et des trois portées sont dans les traductions fr et en ; `flutter analyze` propre. Rien n'est implémenté
côté API ni côté écrans : A4, A5 et M3 restent à faire sur cette base.

**À tester par vous.**
1. Sur ordinateur, relire la section `lots_reservation` de `docs/MODELE_DONNEES.md` et confirmer la règle du
   tout ou rien : un seul jour déjà réservé fait échouer toute la période.
2. Tranché le 21/11 : les services sont au choix, mais le prix ne bouge pas. Un convive peut ne prendre que
   la résistance ; il paie le prix du menu de ce jour pour son profil, comme celui qui prend les trois. Une
   réservation porte au moins une ligne ; un jour sans aucun service est refusé par `aucun_service` 422. Le
   tarif porte donc sur le menu du jour et le profil, plus sur le plat. Le réglage `services_obligatoires`
   reste vide.
3. Dire si l'annulation d'un lot entier doit être possible après le premier jour servi, ou seulement jour par
   jour.

**Résultat.**

**Reste à faire.** A4 doit créer les plats avec les trois services, A5 le lot et ses lignes, M3 l'écran qui
choisit un plat par service puis la portée. Le tarif par profil s'applique à chaque ligne, donc le total d'un
jour est la somme de ses trois services.

---

## Flux de commande : ni heure ni créneau, gel la veille, frais GeniusPay

**Fait.** Le flux est désormais commande, paiement, livraison, sortie de stock. La table `creneaux` disparaît
et `reservations` n'a plus de `creneau_id` : un convive qui a commandé pour un jour vient manger quand il
veut, les heures d'ouverture ne sont qu'un affichage (`heure_ouverture_service`, `heure_fermeture_service`).
La commande se gèle la veille à 18 h 00 (`heure_gel_commandes`) : après, plus de modification, suppression
possible sans remboursement, état `supprimee`. On peut commander plusieurs parts : `lignes_reservation`
gagne `quantite` et `supplement_xof`, et `plats` gagne `prix_supplement_xof`. Les frais GeniusPay sont
portés par `paiements.frais_xof` et `paiements.net_xof`, avec trois taux réglables, et le tableau de bord
montre recettes brutes, frais supportés et net attendu.

**Vérifié par Claude.** Les quatre documents sont relus et ne contiennent plus aucune mention de créneau
réservable : `CLAUDE.md`, `docs/CAHIER.md`, `docs/MODELE_DONNEES.md`, `docs/CONTRAT_API.md`. Nouvelles
routes au contrat : `PATCH /reservations/{id}` (refusée après le gel par `commande_gelee` 409) et
`GET /admin/frais`. Rien n'est implémenté : A4, A5, A6 et A8 partent de cette base.

**À tester par vous.**
1. Sur ordinateur, relire la section « Le flux » de `docs/CAHIER.md` et confirmer l'heure de gel à 18 h 00 la
   veille.
2. Donner les trois taux réels de ton contrat GeniusPay : pourcentage à l'encaissement, part fixe par
   transaction, pourcentage au retrait. Ils sont à zéro tant que tu ne les donnes pas.
3. Dire si une part en plus se paie au prix du plat ou à un forfait, et donner ce prix pour les plats
   concernés.

**Résultat.**

**Reste à faire.** La signature de la marque est « Créneau · Repas · QR », or les créneaux n'existent plus :
elle est dans les SVG, les exports PNG et l'écran de bienvenue. À trancher avant la démonstration.

---

## APP-04, inscription, connexion et code de vérification

**Fait.** Écrans d'inscription (bascule Numéro ou E-mail sur un seul champ, indicatif +225, prénom, nom,
rôle, profil tarifaire, mot de passe avec ses trois règles cochées en direct, conditions), de connexion,
du code (6 cases pour un numéro, 5 pour un e-mail, remplies seules et pastille « Mode démo » quand l'API
renvoie `code_demo`, sinon vides avec le rappel des indésirables, renvoi rouvert après 60 secondes comptées
sur l'appareil), et de mot de passe oublié en trois temps sur un seul écran. Déconnexion depuis l'espace
compte. Un compte non vérifié, ou une session qui a dormi plus de cinq jours, renvoie vers l'écran du code au
lieu d'un message d'erreur.

**Vérifié par Claude.** `flutter analyze` : « No issues found ». `flutter test` : 3 tests verts, dont les
deux de l'écran du code, rempli en mode démo et vide en mode réel. Contre l'API de production : inscription
par numéro et par e-mail réussies, et `POST /auth/verification/envoyer` rend bien `mode_livraison: demo` avec
un code à 6 chiffres pour le téléphone et de 5 caractères pour l'e-mail. Les écrans sont calqués sur le
`openapi.json` de l'API déployée, pas sur une supposition.

**À tester par vous.**
1. Sur Android, créer un compte par numéro : les 6 cases se remplissent seules, la pastille « Mode démo »
   s'affiche, et le compte s'ouvre sur l'accueil de son rôle.
2. Sur Android, créer un compte par e-mail : 5 cases, majuscules acceptées en minuscules aussi.
3. Sur iPhone ou dans Chrome, mode sombre : les trois règles du mot de passe se cochent en direct et aucun
   texte n'est coupé.
4. Se déconnecter depuis l'onglet Compte, puis se reconnecter avec le même mot de passe.

**Résultat.**

**Reste à faire.** Le PIN, Google, Apple et la connexion par QR restent pour APP suivants. Côté API, le code
`verification_requise` après cinq jours d'inactivité est écrit au contrat mais pas encore implémenté.

---

## APP-05, accueil et menu, et volume des images

**Fait.** Accueil du convive (salutation, solde sur surface de contraste, repas du jour ou bouton
« Commander un repas », menu du jour), menu de la semaine avec sélecteur de jour, prix du jour pour le profil
et plats groupés par service, cartes de plat à photo en bord perdu avec alerte rouge si le plat porte un
allergène déclaré, et fiche du plat. Un volume Railway de 5 Go est créé et monté sur `/app/medias` du service
API, avec `STOCKAGE_DOSSIER`, `STOCKAGE_URL_PUBLIQUE` et `STOCKAGE_TAILLE_MAX_MO`. Le contrat gagne
`POST` et `DELETE /admin/plats/{id}/image` et `GET /medias/{fichier}`.

**Vérifié par Claude.** `flutter analyze` : « No issues found ». `railway volume list` montre
`projet-de-restauration-vatel-volume`, attaché au service `Projet-de-restauration-vatel`, chemin
`/app/medias`, état Ready. Les trois variables sont relues sur le service. `GET /menus/semaine` n'existe pas
encore côté API : l'écran retombe sur une semaine de démonstration, et basculera seul dès que A4 livrera la
route.

**À tester par vous.**
1. Sur Android, ouvrir l'accueil puis l'onglet Menu, en clair et en sombre : les photos des plats sont à bord
   perdu, aucun texte n'est coupé, le prix du jour s'affiche.
2. Sur ordinateur, élargir la fenêtre : le contenu reste centré à 1200 px et les cartes gardent leur photo.
3. Toucher une carte : la fiche du plat s'ouvre avec allergènes, régimes, calories et note.

**Résultat.**

**Reste à faire.** Les 13 photos envoyées ne sont pas arrivées sur le disque : à déposer dans
`app/assets/plats/` pour remplacer les cinq photos de la maquette. Le jeu de démonstration
(`features/menus/donnees/jeu_demo.dart`) disparaît dès que A4 est en ligne. Le solde reste un tiret tant que
A5 n'a pas livré `/porte-monnaie`.
