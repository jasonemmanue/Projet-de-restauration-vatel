# Plan de la journée

Ce fichier est le point de reprise. Un compte Claude coupé est remplacé par un autre, qui lit ce tableau et
reprend la ligne « en cours » à sa « prochaine action ». Chaque session met sa ligne à jour au moins toutes les
20 à 30 minutes et à chaque sous-partie terminée, puis commit et pousse.

États possibles : `à faire`, `en cours`, `fait`, `bloqué`. La colonne « session et compte » porte le nom de la
session et le compte Claude qui la tient, par exemple `api / compte A`.

Références de fond, déjà écrites avant le jour J et à ne pas réinventer :

- `uiux vatel/PROMPTS_HACKATHON.md` : le contenu détaillé de chaque étape, qui fait foi.
- `uiux vatel/LOTS_DE_TACHES.md` : le découpage en lots de 20 à 45 minutes, avec les heures.
- `uiux vatel/PLAN_FINAL_HACKATHON.md` : la conduite de la journée, les trois comptes et les territoires.
- `uiux vatel/maquettes/` : les captures de la maquette, par plateforme.
- Dépôt GitHub : `https://github.com/jasonemmanue/Projet-de-restauration-vatel`.

Territoires, repris du plan final : `api/`, `site/`, `.github/`, `README.md` à la session API ; `app/` en
entier, `docs/marque/`, `docs/CHARTE.md` et la maquette à la session App. Jamais deux sessions dans le même
fichier.

## Ce que contient chaque étape

| Étape | Contenu |
| --- | --- |
| P00 | Cadrage : CLAUDE.md, cahier, modèle de données, contrat d'API, charte provisoire, plan, dépôt |
| P01 | Charte et logo repris de la maquette : palettes des deux modes, SVG et exports dans `docs/marque/` |
| A1 | fait | api / compte courant | api/ (app, alembic, recette, tests, Dockerfile, railway.json, .env.example, README), docker-compose.yml | ruff propre, 40 tests verts, migration appliquée sur base vide, image Docker lancée, recette « sante » locale 13/13 | Rien. Suite en A2 : `railway link` puis déploiement et recette « sante » en ligne |
| A2 | Déploiement de l'API sur Railway et recette « sante » en ligne |
| A3 | Comptes, mot de passe, vérification par code, jetons, rôles, sessions |
| A3b | Connexion par QR code, Google et Apple |
| A3c | Profil complet, avatars, assistance et signalements |
| A4 | Plats en trois services, prix du menu par profil, menus de la semaine |
| A5 | Réservations, porte-monnaie, ticket QR, service de l'agent, liaison parent |
| A6 | Paiements GeniusPay en mode test puis réel, liens de paiement |
| A7 | Notifications : appareils, envois ciblés, centre de notifications |
| A8 | Back office : tableau de bord, commandes du jour, stocks, rapports, utilisateurs |
| A9 | Appréciations modérées par l'admin, suggestions |
| A10 | Données de démo et remise à zéro |
| F1 | Fondations de l'application : thème des deux modes, navigation, réseau, traductions |
| F2 | Inscription, connexion et vérification |
| F2b | Écrans de connexion par QR code, Google et Apple |
| F2c | Écran de profil complet et paramètres |
| F3 | Espace convive |
| F4 | Espace parent |
| F5 | Back office en vue globale |
| F6 | Écran de l'agent |
| F7 | Notifications sur Android, iOS et web |
| F8 | Application web en ligne par la branche `web` |
| F9 | Branches de build : `android/apk`, `ios/build-check`, `ios/simulateur`, `ios/testflight` |
| M1 | Jalon jury : comptes et vérification livrée automatiquement, après A2 |
| M2 | Jalon jury : réservation, porte-monnaie et back office minimum, après A4 |
| M3 | Jalon jury : parcours complet du convive dans l'application, après F1 |
| M4 | Jalon jury : back office minimum, menus, commandes du jour, tableau de bord |
| M5 | Jalon de 12h30 : l'application complète en ligne, présentée au jury |
| S1 | Site public Next.js |
| S2 | Pages légales, paiement public, suppression de compte, mise en ligne |
| S3 | Mini vidéo d'accueil en HTML |
| E1 | La vérification par e-mail devient réelle, par l'API Gmail |
| T1 | Audit de sécurité et corrections |
| T2 | Tests, analyse et intégration continue |
| T3 | README et documentation finale |
| T4 | Préparation de la démonstration |

## Phase 1, l'application complète du jury, 8h30 à 12h30

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| P00 | fait | cadrage / compte 1 | CLAUDE.md, docs/, .gitignore, .env.example, README.md | Dépôt initialisé, cadrage écrit et commité | Rien, étape close |
| P01 | fait | cadrage / compte 1 | docs/CHARTE.md, docs/marque/, app/outils/marque.mjs | Palettes, contrastes, 9 SVG et 16 exports PNG produits | Rien, étape close. Les valeurs sont à reporter dans le thème Flutter en F1 |
| A1 | en cours | api / compte courant | api/app, api/alembic, api/tests | Structure, configuration, 26 modèles, migration 0001, /health, erreurs, middlewares ; ruff et 35 tests verts | Écrire api/recette (bloc « sante »), Dockerfile, railway.json, docker-compose.yml, README |
| A2 | fait | api / compte courant | Railway (service API, Postgres, variables, domaine), docs/CONTRAT_API.md, api/README.md | Déployé 314fc8b par la CLI, migration 0001 appliquée, recette « sante » en ligne 13/13 | Rien. Mettre à jour CORS_ORIGINS dans Railway quand l'URL web de l'application (F8) et celle du site (S2) seront connues |
| F1 | fait | app / compte 1 | app/ (lib/core, lib/features, lib/shared, l10n fr et en, assets, android, ios, web) | Projet créé, thème des deux modes, navigation par rôle, client API, socle hors ligne, icônes et écrans de lancement, Firebase branché, boutons Google, Apple et QR ; analyze propre, test vert, build web réussi | Rien. Suite en F2 : écrans d'inscription, de connexion et de vérification |
| M1 | bloqué | api / compte courant | api/app (auth, moi, admin_utilisateurs, services comptes), alembic 0002, api/recette/blocs/auth.py, docs/CONTRAT_API.md, docs/MODELE_DONNEES.md | 6a2f73d déployé, migration 0002 en ligne, recette « sante » 13/13 ; admin initial non créé : ADMIN_INITIAL_EMAIL de Railway n'est pas une adresse complète | L'exploitant corrige ADMIN_INITIAL_EMAIL dans Railway et pose RECETTE_* dans son terminal ; puis `railway restart`, recette « auth » en ligne, et suppression du compte d'essai `essai-…@recette.invalid` créé à la main |
| A4 | fait | api / compte courant | api/app (catalogue, menus), alembic 0005, recette/blocs/menus.py | Plats en trois services avec photo et allergènes, tarifs par profil, menus brouillon et publiés, copie de semaine, lecture convive avec prix, gel, portions et allergènes ; tests verts | Recette « menus » en ligne dès que l'admin initial existe |
| M2 | fait | api / compte courant | api/app (commandes, porte_monnaie, tableau_bord), api/demo/peupler.py, recette/blocs/mvp.py | API-08 et API-09 faits : commande par période, porte-monnaie, ajustement admin, commandes du jour, tableau de bord, jeu de démo idempotent avec les photos du volume ; recette « tous » locale 61/61 | En ligne, dès que l'admin initial existe : `railway ssh -s Projet-de-restauration-vatel -- python -m demo.peupler`, puis recettes auth, menus et mvp |
| M3 | à faire | | app/ | | Menu de la semaine, réservation en trois touchers, ticket QR, solde |
| M4 | à faire | | app/ | | Back office minimum : menus, commandes du jour, tableau de bord |
| M5 | à faire | | api/, app/ | | Vérifier l'application complète en ligne avant 12h30 |

## Phase 2, compléter l'API

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| A3 | à faire | | api/ | | Compléter comptes, mot de passe oublié, code de secours, sessions ouvertes |
| A3b | à faire | | api/ | | Connexion par QR code, Google et Apple |
| A3c | à faire | | api/ | | Profil complet, avatars, export des données, signalements |
| A5 | à faire | | api/ | | Ticket QR signé, scan de l'agent, file hors ligne, liaison parent |
| A6 | en cours | api / compte courant | api/app (geniuspay, paiements, liens_paiement, regles_frais), alembic 0007 et 0008 | API-12 et API-13 écrits : recharge, webhooks signés, mode réel protégé (mot de passe des actions, journal, refus sans clés), liens de paiement publics « Prénom I. », estimation des frais selon la grille (lignes arrondies puis additionnées) ; clés lues sous les noms Railway GENIUSPAY_API_KEY, GENIUSPAY_SECRET_KEY, GENIUSPAY_WEBHOOK_SECRET et LIVE_ | Vérifier en ligne : GET /admin/mode-paiement, une recharge test de 500 XOF, le webhook ; puis API-14 notifications |
| A7 | à faire | | api/ | | Appareils, notifications ciblées et centre de notifications |
| A8 | à faire | | api/ | | Stocks, rapports CSV et PDF, utilisateurs, journal des actions |
| A9 | à faire | | api/ | | Appréciations avec modération et réponse, suggestions |
| A10 | à faire | | api/ | | Jeu de démonstration complet et remise à zéro protégée |

## Phase 3, compléter l'application

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| F2 | à faire | | app/ | | Écrans d'inscription, de connexion et de vérification |
| F2b | à faire | | app/ | | Écrans de connexion par QR code, Google et Apple |
| F2c | à faire | | app/ | | Écran de profil complet et paramètres, repris de la maquette |
| F3 | à faire | | app/ | | Espace convive complet |
| F4 | à faire | | app/ | | Espace parent |
| F5 | à faire | | app/ | | Back office en vue globale |
| F6 | à faire | | app/ | | Écran de l'agent et scan hors ligne |
| F7 | à faire | | app/ | | Notifications sur les trois plateformes |
| F8 | à faire | | app/ | | Publier l'application web par la branche `web` |
| F9 | à faire | | app/ | | Déclencher les branches de build Android et iOS |

## Phase 4, le site, le réel et la recette

| Étape | État | Session et compte | Fichiers touchés | Dernière action | Prochaine action précise |
| --- | --- | --- | --- | --- | --- |
| S1 | en cours | app / compte 1 | site/ (app, components, public, tailwind, package.json) | Page d'accueil, badges Play, App Store et Web selon l'appareil, boutons Google et Apple à logo non déformé, codes QR, charte en jetons CSS | Finir l'installation npm, passer `npm run build`, puis S2 pour les pages légales |
| S2 | à faire | | site/ | | Pages légales, paiement public, suppression de compte, mise en ligne |
| S3 | à faire | | site/ | | Mini vidéo d'accueil en HTML |
| E1 | à faire | | api/ | | Basculer la vérification par e-mail en réel, par l'API Gmail |
| T1 | à faire | | api/, app/ | | Audit de sécurité et corrections |
| T2 | à faire | | api/, app/ | | Tests, analyse et intégration continue |
| T3 | à faire | | README.md, docs/ | | README et documentation finale |
| T4 | à faire | | app/ | | Préparer et répéter la démonstration |

## Repris de la session « UI UX FINAL »

Ce qu'elle laisse, déjà en place dans `uiux vatel/` : la maquette React finie et compilable pour les quatre
rôles, les captures par plateforme dans `maquettes/`, le cahier des charges, les lots de tâches, les prompts et
le plan final. Rien de tout cela n'est à refaire.

Ce qui reste à reprendre pendant le codage :

| Point | Où il se règle |
| --- | --- |
| Profil et paramètres complets ajoutés tard à la maquette (photo, informations, formule, statistiques, préférences, sécurité, appareils, suppression) | F2c côté application, A3 et A3c côté API |
| Moov remplacé par Stripe dans le dernier build de la maquette, alors que le cahier parle de Mobile Money | À trancher avant A6 : la liste des opérateurs de `paiements` suit la décision prise |
| La maquette n'est pas encore dans `docs/maquette/`, chemin que CLAUDE.md et tous les prompts citent | À copier sans `node_modules` ni `dist` par la session App, avant F1 |

## Décisions de l'exploitant, 21 novembre

| Décision | Conséquence à appliquer |
| --- | --- |
| Une commande engage : le convive paie ce qu'il a commandé, qu'il vienne manger ou non. Un repas non retiré n'est ni remboursé ni reporté. | Une réservation non servie à la fin du jour passe à `non_reclamee`, sans mouvement de crédit (M2, A5). |
| Plus de plats restants : tout est commandé à l'avance, la cuisine prépare ce qui est commandé. | Fait le 21/11 dans les documents : l'anti-gaspillage est retiré de `docs/CAHIER.md`, `docs/CONTRAT_API.md`, `docs/MODELE_DONNEES.md` et `docs/CHARTE.md`. Reste à ne pas le coder, et à ne pas créer ses colonnes en A4. La commande engage : l'état `non_reclamee` remplace la remise en vente. |
| Le gel se fait repas par repas, chez tous les concernés : chaque jour d'un lot se gèle à son propre moment, la semaine ne gèle pas d'un bloc. L'admin règle le jour (`gel_jours_avant_service`, 1 par défaut) et l'heure (`heure_gel_commandes`, 18:00 par défaut). | M2 calcule le gel par `date_service` ; `PATCH /reservations/{id}` ne refuse que les jours gelés. Paramètres posés par la migration 0003. |
| Le code de vérification sert à l'inscription et au retour après 5 jours sans ouvrir l'application : mot de passe puis code. La session se prolonge à chaque ouverture. | Fait en M1 : migration 0004 (`session_inactivite_jours`, usage `reconnexion`), `POST /auth/connexion` peut répondre `code_requis`, `POST /auth/connexion/confirmer`. |
| Photos et images de démo sur le volume Railway (`/app/medias`), servies par `GET /medias/...`. Les 15 images de `uiux vatel/Images repas` sont dans `api/demo/images` et copiées dans `demo/` du volume au démarrage, sans écraser. | Fait. La colonne `plats.photo` reste en base, vide et inutilisée : son retrait (DROP) attend l'accord de l'exploitant. |
| Voix de confirmation (réservation, paiement, et autres) si l'utilisateur active le son ; vibreur activable ; tout désactivable. Réglages par défaut tenus par l'admin. | Application : synthèse sur l'appareil (`flutter_tts`, gratuite ; synthèse du navigateur sur le web), sans appel réseau. API (A3c) : préférences `son`, `vibreur` dans `PUT /moi/preferences`, défauts dans `parametres` (`voix_active_defaut`, `vibreur_actif_defaut`), et texte de confirmation fr/en rendu par chaque route concernée. |

