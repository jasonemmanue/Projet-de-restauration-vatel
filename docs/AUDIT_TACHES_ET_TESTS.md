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

