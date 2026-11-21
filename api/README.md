# API de CANTINE VATEL

FastAPI, Python 3.12, SQLAlchemy 2 asynchrone, asyncpg, Alembic. Seule brique qui touche la base
PostgreSQL.

## Organisation

| Dossier | Rôle |
| --- | --- |
| `app/core` | configuration lue dans l'environnement, messages, erreurs, sécurité, limites de débit, journaux |
| `app/db` | base déclarative, moteur asynchrone, session par requête validée avant la réponse |
| `app/models` | les 26 tables de `docs/MODELE_DONNEES.md`, un fichier par sujet |
| `app/schemas`, `app/routes`, `app/services` | schémas Pydantic, routes HTTP, logique qui parle à la base |
| `alembic` | migrations ; le schéma initial est figé dans `alembic/schema_initial/*.sql` |
| `recette` | recette en ligne, un fichier par bloc dans `recette/blocs` |
| `tests` | tests pytest |

## Lancer en local

```bash
python -m venv .venv && .venv/Scripts/pip install -r requirements-dev.txt   # .venv/bin sous Linux et macOS
cp .env.example .env    # puis remplir les quatre variables obligatoires
alembic upgrade head
uvicorn app.main:creer_application_uvicorn --factory --reload
```

Ou, depuis la racine du dépôt, `docker compose up --build` (PostgreSQL et API, secrets lus dans `api/.env`).

## Contrôles

```bash
ruff check .
TEST_DATABASE_URL=postgresql://... pytest    # sans cette variable, les tests de base sont ignorés
```

## Recette

```bash
python -m recette --url https://<URL_API> --bloc sante            # ou --bloc tous
python -m recette --url https://<URL_API> --bloc sante --commit <sha attendu>
```

Les identifiants de l'admin de recette se tapent dans son propre terminal (`RECETTE_ADMIN_IDENTIFIANT`,
`RECETTE_ADMIN_MOT_DE_PASSE`, `RECETTE_MOT_DE_PASSE_ACTIONS`) et ne sont jamais affichés. Aucun SMS ni
paiement réel n'est déclenché.

## Règles propres à l'API

- Toute route qui touche la base prend `SessionBase` (`app/db/session.py`) : la validation se fait avant
  l'envoi de la réponse, l'annulation sur toute erreur.
- Toute erreur passe par `ErreurApi(code, statut)` et sort au format `{"code", "message"}` ; un nouveau code
  s'ajoute dans `app/core/messages.py`, en français et en anglais.
- Chaque connexion porte `lock_timeout`, `statement_timeout` et le fuseau UTC (`app/db/moteur.py`).
- Une requête SQL écrite à la main est paramétrée, et un paramètre qui sert à une date ou à un calcul est typé
  par `CAST(:param AS date)` ou `CAST(:param AS integer)`.
- Les colonnes lourdes (charge utile des webhooks, états avant et après du journal) sont différées : chargées
  seulement à la demande avec `undefer`.
- Toute évolution du schéma passe par une nouvelle migration ; le test `test_base_migree_conforme_aux_modeles`
  échoue si modèles et base divergent.
