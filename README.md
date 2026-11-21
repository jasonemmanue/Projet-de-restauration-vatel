# CANTINE VATEL

Gestion de cantine scolaire et d'entreprise en Côte d'Ivoire. Chaque convive a un porte-monnaie électronique
rechargé par Mobile Money, commande ses repas à l'avance pour un jour, une semaine ou un mois, et présente un
ticket QR au comptoir. Les parents rechargent et suivent les repas de leurs enfants. L'administrateur planifie
les menus, voit les commandes du jour, gère les stocks et lit son tableau de bord.

## En ligne

| Brique | Adresse |
| --- | --- |
| Application web (convive, parent, agent) | https://app-web-production-34865097.up.railway.app |
| Back office (administrateur) | https://back-office-production-f9e362fb.up.railway.app |
| Site public | https://site-web-production-dc1229af.up.railway.app |
| API | https://projet-de-restauration-vatel-production.up.railway.app (`GET /health`) |
| APK Android | https://github.com/jasonemmanue/Projet-de-restauration-vatel/releases/latest/download/cantine-vatel.apk |

Le back office est la même application Flutter, construite pour s'ouvrir sur la connexion : un compte
administrateur y arrive sur le tableau de bord. Les droits sont contrôlés par l'API à chaque appel, quelle que
soit l'adresse utilisée.

## Le problème et la réponse

| Problème de la cantine | Réponse de Cantine Vatel |
| --- | --- |
| Files d'attente aux heures de pointe | Repas commandé et payé à l'avance, un scan de ticket QR au comptoir, sans créneau imposé |
| Gaspillage faute de planification | La cuisine prépare ce qui est commandé : chaque repas se gèle la veille de son service |
| Régimes et allergies | Allergies saisies par le convive ou son parent, plats signalés dans le menu |
| Menus et tarifs opaques | Menu de la semaine publié, prix du jour selon le profil (élève, étudiant, employé, autre) |
| Gestion manuelle | Back office : menus, commandes du jour, stocks, rapports CSV et PDF, journal des actions |

## Fonctionnalités

Minimum demandé, toutes livrées : inscription et connexion avec code de vérification, menu de la semaine,
réservation en trois touchers, solde et historique ; côté administrateur, création et modification des
menus, commandes du jour, tableau de bord.

En plus : notation des plats avec modération, suggestions, français et anglais, application Android, iOS et
web, recharge Mobile Money par GeniusPay (Orange, MTN, Moov, Wave) en mode test ou réel, lien de paiement à
envoyer à un proche, notifications poussées (FCM), mode hors ligne (menu, ticket et solde lisibles, scans de
l'agent mis en file d'envoi), espace parent avec alerte de solde bas, stocks et rapports.

## Architecture

```
app/   Flutter (Android, iOS, web, back office)  ─┐
site/  Next.js, export statique                   ├─> api/  FastAPI ──> PostgreSQL
                                                  ┘        GeniusPay, FCM, Gmail
```

- Le serveur décide de tout : prix, solde, gel des commandes, droits. Le client affiche ce que l'API rend.
- Montants en entiers XOF ; le solde n'existe que par la somme de ses mouvements.
- Sécurité : identité lue dans le jeton, propriétaire vérifié sur chaque route, SQL paramétré, CORS en
  liste exacte, aucun secret dans le dépôt (variables d'environnement, `.env.example` sans valeurs).

Détails : [docs/CAHIER.md](docs/CAHIER.md), [docs/CONTRAT_API.md](docs/CONTRAT_API.md),
[docs/MODELE_DONNEES.md](docs/MODELE_DONNEES.md), [docs/CHARTE.md](docs/CHARTE.md),
[docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md).

## Comptes de démonstration et administrateur

- Administrateur initial : adresse et mot de passe dans les variables `ADMIN_INITIAL_EMAIL` et
  `ADMIN_INITIAL_MOT_DE_PASSE` du service `API` sur Railway (`railway variables --service API`).
- Jeu de démonstration (admin, élève, employé, menus, plats avec photos) : `railway ssh -s API -- python -m
  demo.peupler`. Les mots de passe des comptes créés s'affichent une seule fois dans le terminal.

## Lancer en local

API (Python 3.12) :

```bash
cd api
python -m venv .venv && .venv/Scripts/pip install -r requirements-dev.txt
cp .env.example .env          # remplir les variables obligatoires
alembic upgrade head
uvicorn app.main:creer_application_uvicorn --factory --reload
python -m demo.peupler        # jeu de démonstration, affiche les comptes créés
```

Ou `docker compose up --build` depuis la racine (PostgreSQL et API).

Application (Flutter 3.38.4) :

```bash
cd app
flutter pub get
flutter run --dart-define=API_URL=http://localhost:8000/api/v1
```

Compiler l'APK sur son poste (Android SDK et Java 17 ou plus), en visant l'API en ligne :

```bash
cd app
flutter build apk --release --dart-define=API_URL=https://projet-de-restauration-vatel-production.up.railway.app/api/v1
# résultat : app/build/app/outputs/flutter-apk/app-release.apk
```

Compiler l'application web : `flutter build web --release --dart-define=API_URL=...` (résultat dans
`app/build/web`). Ajouter `--dart-define=ENTREE=/connexion` pour la version back office.

Site (Node 20) :

```bash
cd site
npm ci
npm run dev
```

## Contrôles

| Dossier | Commandes |
| --- | --- |
| `api` | `ruff check .`, `pytest`, `python -m recette --url https://<URL_API> --bloc tous` |
| `app` | `flutter analyze`, `flutter test` |
| `site` | `npm run lint`, `npx tsc --noEmit`, `npm run build` |

## Dossiers

- `api/` : API FastAPI, migrations Alembic, recette en ligne, jeu de démonstration
- `app/` : application Flutter, Android, iOS, web et back office
- `site/` : site public Next.js
- `docs/` : cahier, modèle de données, contrat d'API, charte, déploiement, plan et audit
