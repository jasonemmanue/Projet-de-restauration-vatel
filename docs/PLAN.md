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
| A1 | Fondations de l'API : structure, configuration, base, erreurs uniformes, santé avec commit, module de recette |
| A2 | Déploiement de l'API sur Railway et recette « sante » en ligne |
| A3 | Comptes, mot de passe, vérification par code, jetons, rôles, sessions |
| A3b | Connexion par QR code, Google et Apple |
| A3c | Profil complet, avatars, assistance et signalements |
| A4 | Plats, tarifs, menus, créneaux |
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
| A1 | à faire | | api/ | | Créer la structure FastAPI, la configuration, la migration initiale et `GET /sante` |
| A2 | à faire | | api/, railway | | Déployer sur Railway et passer la recette « sante » en ligne |
| F1 | à faire | | app/ | | Créer le projet Flutter, le thème des deux modes depuis docs/CHARTE.md et la navigation |
| M1 | à faire | | api/ | | Inscription, code de vérification en mode démo, connexion, rôles |
| A4 | à faire | | api/ | | Plats, tarifs, menus, créneaux et leurs routes |
| M2 | à faire | | api/ | | Réservation, porte-monnaie, commandes du jour, tableau de bord |
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
| A6 | à faire | | api/ | | GeniusPay en mode test, webhooks, puis mode réel protégé et liens de paiement |
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
| S1 | à faire | | site/ | | Créer le site public Next.js |
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
