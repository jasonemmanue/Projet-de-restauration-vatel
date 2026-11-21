# Déploiement

Tout tourne dans le projet Railway « HACKATON VATEL », environnement `production`.

| Service | Source | Construction | Adresse |
| --- | --- | --- | --- |
| `API` | `api/` | `api/Dockerfile` | https://projet-de-restauration-vatel-production.up.railway.app |
| `Postgres` | base gérée | | interne |
| `app-web` | `app/` | `app/Dockerfile` (Flutter 3.38.4 puis nginx) | https://app-web-production-34865097.up.railway.app |
| `back-office` | `app/` | `app/Dockerfile`, variable `ENTREE=/connexion` | https://back-office-production-f9e362fb.up.railway.app |
| `site-web` | `site/` | `site/Dockerfile` (export Next.js puis nginx) | https://site-web-production-dc1229af.up.railway.app |

## Variables

| Service | Variable | Rôle |
| --- | --- | --- |
| `app-web`, `back-office` | `FIREBASE_DEFINES` | JSON des valeurs Firebase web (clés publiques du client web), passé à `--dart-define-from-file` |
| `back-office` | `ENTREE` | `/connexion` : premier écran du back office. Seul un chemin public est accepté |
| `app-web`, `back-office` | `API_URL`, `SITE_URL` | facultatives, valeurs par défaut dans `app/Dockerfile` |
| `site-web` | `NEXT_PUBLIC_LIEN_APPLICATION` | facultative, adresse de l'application web, par défaut celle de `app-web` |
| `API` | `CORS_ORIGINS` | contient les trois adresses ci-dessus, en liste exacte |

## Redéployer

Depuis la racine du dépôt, CLI Railway liée au projet :

```bash
railway up app  --path-as-root --service app-web     --detach
railway up app  --path-as-root --service back-office --detach
railway up site --path-as-root --service site-web    --detach
```

`app/.railwayignore` et `site/.railwayignore` laissent sur le poste les résultats de build, les dossiers
natifs et `firebase.defines`.

## APK Android

Construit sur le poste, visant l'API en ligne :

```bash
cd app
flutter build apk --release \
  --dart-define=API_URL=https://projet-de-restauration-vatel-production.up.railway.app/api/v1 \
  --dart-define=SITE_URL=https://site-web-production-dc1229af.up.railway.app \
  --dart-define-from-file=firebase.defines
```

Le fichier `app/build/app/outputs/flutter-apk/app-release.apk` est copié dans `site/public/cantine-vatel.apk`
(ignoré par git, `*.apk`), puis le site est redéployé avec `--no-gitignore` pour qu'il parte :
il se télécharge alors depuis https://site-web-production-dc1229af.up.railway.app/cantine-vatel.apk.
La construction GitHub Actions (`.github/workflows/application.yml`) produit la même APK en artefact.

## Vérifier

```bash
curl https://projet-de-restauration-vatel-production.up.railway.app/health    # commit déployé
cd api && python -m recette --url https://projet-de-restauration-vatel-production.up.railway.app --bloc tous
```
