# Plan de la journée

Ce fichier est le point de reprise. Un compte Claude coupé est remplacé par un autre, qui lit ce tableau et
reprend la ligne « en cours » à sa « prochaine action ». Chaque session met sa ligne à jour au moins toutes les
20 à 30 minutes et à chaque sous-partie terminée, puis commit et pousse.

États possibles : `à faire`, `en cours`, `fait`, `bloqué`.
Remplir la colonne « session et compte » avec le nom de la session et le compte Claude qui la tient, par
exemple `API-1 / compte 2`.

## Ce que contient chaque étape

| Étape | Contenu |
| --- | --- |
| P00 | Cadrage : CLAUDE.md, cahier, modèle de données, contrat d'API, charte provisoire, plan, dépôt |
| P01 | Charte définitive à partir du logo et de `docs/maquette` : valeurs de couleur des deux modes, thème |
| A1 | Socle API : configuration, base, Alembic, santé avec commit, erreurs, CORS, `parametres`, `journal_admin`, module `recette` |
| A2 | Authentification : inscription, connexion, jetons, sessions, codes de vérification, journal des vérifications |
| A3 | Profil complet : informations, préférences, avatars, reçus, export, assistance et signalements |
| A3b | Code PIN, preuve de dépense, biométrie par secret d'appareil |
| A3c | Connexion d'un ordinateur par QR code scanné avec le téléphone |
| A4 | Cœur métier : plats, tarifs, menus, créneaux, réservations, ticket, porte-monnaie et mouvements |
| A5 | Paiements GeniusPay, webhooks test et réel, liens de paiement et page publique |
| A6 | Parent : code de liaison, enfants, repas, seuil d'alerte, allergies |
| A7 | Avis, modération et réponse de la cantine, suggestions |
| A8 | Agent : scan, service du jour, file des scans hors ligne |
| A9 | Notifications : appareils FCM, notifications in-app, envois ciblés |
| A10 | Back office : tableau de bord, commandes du jour, utilisateurs, stocks, rapports CSV et PDF, anti-gaspillage, réglages, remise à zéro |
| F1 | Socle Flutter : thème clair et sombre, GoRouter, Riverpod, Dio, traductions, stockage local |
| F2 | Espace convive : accueil, menu, réservation, ticket, solde |
| F2b | Hors ligne : cache lisible, file d'envoi, boutons d'argent grisés |
| F2c | Français et anglais sur tous les écrans livrés |
| F3 | Espace parent |
| F4 | Espace agent avec scan de QR |
| F5 | Espace admin dans la même application |
| F6 | Recharge Mobile Money et liens de paiement dans l'application |
| F7 | Notifications push et centre de notifications |
| F8 | Connexion Google, Apple et par QR code |
| F9 | Finition : zones sûres, haptique, transitions, accessibilité, aucun texte coupé |
| M1 | Minimum jury : inscription, vérification et connexion de bout en bout |
| M2 | Minimum jury : menu de la semaine affiché |
| M3 | Minimum jury : réservation d'un repas et ticket QR |
| M4 | Minimum jury : solde et historique |
| M5 | Minimum jury : admin, menus, commandes du jour, tableau de bord |
| S1 | Site vitrine Next.js |
| S2 | Pages légales et page publique de paiement |
| S3 | Responsive, référencement, déploiement du site |
| E1 | Déploiement Railway : base, API, variables, domaines, FCM, clés GeniusPay |
| T1 | Jeu de données de démonstration et remise à zéro |
| T2 | Recette complète en ligne, bloc par bloc |
| T3 | Répétition de la démonstration du jury |
| T4 | Corrections finales, bascule de l'e-mail en réel |

## Phase 1, le minimum exigé par le jury

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| P00 | fait | Cadrage / compte 1 | CLAUDE.md, docs/, .gitignore, .env.example, README.md | Dépôt initialisé et cadrage écrit | Rien, étape close |
| P01 | à faire | | docs/CHARTE.md | | Lire `docs/maquette/src/shared/styles/tokens.css` et reporter les valeurs des deux modes |
| A1 | à faire | | api/ | | Créer le squelette FastAPI, la configuration et la migration initiale |
| A2 | à faire | | api/ | | Écrire les tables `utilisateurs`, `sessions`, `codes_verification` et leurs routes |
| F1 | à faire | | app/ | | Créer le projet Flutter, le thème des deux modes et la navigation |
| M1 | à faire | | app/, api/ | | Enchaîner inscription, code de vérification en mode démo et connexion |
| A4 | à faire | | api/ | | Écrire plats, menus, créneaux, réservations, porte-monnaie et leurs routes |
| M2 | à faire | | app/ | | Afficher le menu de la semaine depuis `GET /menus/semaine` |
| M3 | à faire | | app/ | | Réserver en trois touchers et afficher le ticket QR |
| M4 | à faire | | app/ | | Afficher le solde et l'historique des mouvements |
| M5 | à faire | | app/ | | Ouvrir l'espace admin : menus, commandes du jour, tableau de bord |

## Phase 2, le reste de l'API

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| A3 | à faire | | api/ | | Écrire le profil complet, les avatars et les signalements |
| A3b | à faire | | api/ | | Écrire le code PIN, la preuve de dépense et la biométrie |
| A3c | à faire | | api/ | | Écrire la connexion par QR code et ses quatre routes |
| A5 | à faire | | api/ | | Brancher GeniusPay en mode test et écrire les deux webhooks |
| A6 | à faire | | api/ | | Écrire la liaison parent enfant et le suivi des repas |
| A7 | à faire | | api/ | | Écrire les avis, leur modération et les suggestions |
| A8 | à faire | | api/ | | Écrire le scan, le service du jour et la file hors ligne |
| A9 | à faire | | api/ | | Brancher Firebase Cloud Messaging et les notifications in-app |
| A10 | à faire | | api/ | | Écrire le back office, les rapports et la remise à zéro |

## Phase 3, l'application

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| F2 | à faire | | app/ | | Compléter l'espace convive au-delà du minimum |
| F2b | à faire | | app/ | | Mettre en place le cache lisible hors ligne et la file d'envoi |
| F2c | à faire | | app/ | | Sortir tous les textes dans les fichiers fr et en |
| F3 | à faire | | app/ | | Construire l'espace parent |
| F4 | à faire | | app/ | | Construire l'espace agent et le scan de QR |
| F5 | à faire | | app/ | | Compléter l'espace admin |
| F6 | à faire | | app/ | | Brancher la recharge Mobile Money et les liens de paiement |
| F7 | à faire | | app/ | | Brancher les notifications push et le centre de notifications |
| F8 | à faire | | app/ | | Ajouter Google, Apple et la connexion par QR |
| F9 | à faire | | app/ | | Passer la finition sur tous les écrans, en clair et en sombre |

## Phase 4, le site

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| S1 | à faire | | site/ | | Créer le projet Next.js et la page d'accueil |
| S2 | à faire | | site/ | | Écrire les pages légales et la page publique de paiement |
| S3 | à faire | | site/ | | Vérifier le responsive, le référencement et déployer |

## Phase 5, le déploiement

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| E1 | à faire | | api/, railway | | Créer la base et le service API sur Railway, poser les variables |

## Phase 6, la recette

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| T1 | à faire | | api/ | | Écrire le jeu de démonstration et la remise à zéro |
| T2 | à faire | | api/ | | Lancer `python -m recette` sur chaque bloc en ligne |
| T3 | à faire | | app/ | | Répéter la démonstration du jury de bout en bout |
| T4 | à faire | | api/, app/ | | Corriger les croix et basculer l'e-mail en mode réel |
