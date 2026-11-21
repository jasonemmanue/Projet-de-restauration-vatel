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

Publication sur GitHub : pousser l'état de `main` sur la branche `android/apk`
(`git push origin main:android/apk`). Le flux `.github/workflows/application.yml` construit l'APK et la
publie en Release `apk-<numéro>` ; la dernière se télécharge toujours à
https://github.com/jasonemmanue/Projet-de-restauration-vatel/releases/latest/download/cantine-vatel.apk

## Vérifier

```bash
curl https://projet-de-restauration-vatel-production.up.railway.app/health    # commit déployé
cd api && python -m recette --url https://projet-de-restauration-vatel-production.up.railway.app --bloc tous
```
