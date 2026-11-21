# CANTINE VATEL

Gestion de cantine scolaire et d'entreprise en Côte d'Ivoire. Monnaie XOF, indicatif +225.
Chaque convive a un porte-monnaie et réserve ses repas avant l'heure limite, sur un créneau de passage, pour
un jour, une semaine ou un mois. Un repas tient en trois services, entrée, résistance et sortie, tous au choix : au moins un, et il paie ce
qu'il a choisi. Il reçoit un
ticket QR par jour, que l'agent scanne une fois au comptoir. Les parents rechargent par Mobile Money (GeniusPay) ou envoient un
lien de paiement à un proche. L'admin planifie les menus, suit les commandes du jour, les stocks et un tableau
de bord.

Lis ce fichier en entier avant toute action. Il prime sur tes habitudes.

## Rôles
- convive : menu de la semaine, réservation, ticket QR, solde et historique, notes, suggestions, allergies.
  Statut du compte : `eleve`, `etudiant`, `employe` ou `autre`. Tout convive peut recharger son propre
  porte-monnaie, élève compris : mêmes opérateurs, mêmes montants, même webhook GeniusPay, même écriture au
  porte-monnaie. Un parent lié peut en plus recharger celui de ses enfants, et n importe qui peut se faire
  payer par un proche avec un lien de paiement. Le statut sert au tarif et aux statistiques, jamais à
  interdire un paiement.
- parent : lié à un ou plusieurs enfants par un code de liaison. Recharge, lien de paiement, suivi des repas,
  seuil d'alerte de solde bas, allergies de l'enfant.
- agent : scan des tickets et service en cours. Rien d'autre.
- admin : back office complet (plats, tarifs par profil, menus, créneaux, commandes du jour, stocks, rapports
  CSV et PDF, utilisateurs, paiements et mode test ou réel, liens de paiement, notifications ciblées, réglages,
  journal des actions, remise à zéro des données de démo).

## Architecture
- Le serveur décide de tout : prix, solde, heure limite, droits, disponibilité. Le client affiche ce que l'API
  lui donne et ne recalcule jamais un montant.
- Seule l'API touche la base. Ni l'application ni le site n'ouvrent de connexion PostgreSQL.
- Tout réglage modifiable passe par la table `parametres` et le back office. Aucune valeur métier en dur.
- Montants en entiers XOF. Jamais de flottant pour de l'argent.
- Heures en UTC en base et dans les échanges. Abidjan est à UTC, l'affichage ne convertit pas.
- Le solde n'existe que par la somme de ses mouvements. Aucune colonne de solde modifiable à la main.
- Pas de Redis : une seule instance d'API, verrous par PostgreSQL (`SELECT ... FOR UPDATE`, avis consultatifs).

## Sécurité (le dépôt est public)
- Identité lue dans le jeton, jamais dans le corps ni dans l'URL.
- Propriétaire vérifié sur chaque route : un convive n'atteint que ses données, un parent que celles de ses
  enfants liés.
- Rôles vérifiés côté serveur à chaque appel. Refus par défaut : une route sans règle explicite refuse.
- SQL paramétré uniquement. Aucune concaténation de chaîne dans une requête.
- Messages d'erreur génériques, sans détail technique ni existence de compte révélée.
- CORS en liste exacte d'origines. Jamais `*`.
- Aucun secret dans le dépôt ni dans l'application livrée : tout en variable d'environnement, déclarée sans
  valeur dans `.env.example`.
- Mot de passe, code PIN, secret biométrique et codes de vérification stockés hachés.

## Qualité
- Chaque fichier commence par un commentaire qui dit son rôle.
- Chaque fonction publique a une docstring en français.
- Les commentaires expliquent le pourquoi, pas le comment.
- Noms clairs en français, y compris tables, colonnes et routes.
- Les règles métier vivent dans des fonctions pures testées.
- 300 lignes au plus par fichier. Au-delà, on découpe.
- Aucun texte d'interface en dur hors des fichiers de traduction (fr et en).
- Aucun texte coupé par des points de suspension : on adapte la taille ou on passe à la ligne.

## Affichage
- Chaque écran existe en mode clair et en mode sombre.
- Toutes les couleurs passent par le thème. Jamais de couleur en dur dans un écran.
- Le ticket QR reste noir sur fond blanc dans les deux modes.
- Affichage bord à bord, avec respect des zones sûres sur Android et iPhone.

## Navigation
- Barre en bas de 4 onglets au plus par rôle, libellés toujours visibles.
- Chaque onglet garde sa pile et sa position de défilement (`StatefulShellRoute` de GoRouter).
- Toucher l'onglet actif remonte en haut.
- Tout élément touchable mesure 48 x 48 au moins et réagit tout de suite.
- Boutons principaux en bas, à portée du pouce. Feuilles du bas plutôt que boîtes de dialogue.
- Retour haptique léger à l'onglet, à la réservation et au scan réussi ou refusé. Jamais sur le web.
- Transitions de 200 à 300 ms, de la même famille partout.
- Retour par glissement sur iPhone, retour prédictif sur Android.
- Animations coupées quand le système demande de les réduire.
- Réserver tient en trois touchers depuis l'accueil.

## Hors ligne
- Tout ce qui a été chargé reste lisible sans réseau, avec l'heure de mise à jour affichée.
- Aucune action d'argent hors ligne (réserver, recharger, payer) : bouton grisé avec la raison.
- Les scans de l'agent et les appréciations faits hors ligne vont dans une file d'envoi, chacun avec une clé
  unique, envoyés un par un au retour du réseau.

## Design
La charte, le logo, les parcours et les libellés des quatre rôles sont déjà décidés. Ils arrivent dans
`docs/maquette/` : une maquette React cliquable, qui sert de référence et que personne ne modifie ni ne
compile. Aucune session n'invente une couleur, un libellé ou un écran qui n'y figure pas.
- couleurs : `docs/maquette/src/shared/styles/tokens.css`
- logo : `docs/maquette/src/shared/components/Logo.tsx`
- écrans : `docs/maquette/src/apps/<role>/main.tsx`

## Pièges connus, à ne jamais reproduire
- Aucun appel réseau dans un minuteur périodique.
- Effets externes (notification, e-mail) seulement après la validation de la transaction.
- Aucun appel lent (e-mail, PDF, IA) pendant une requête : travail de fond.
- Un index se crée par une migration.
- Numéro de facture = plus grand numéro plus un, jamais un comptage.
- Aucune valeur NULL qui voudrait dire « tout ».
- Jamais de DROP ni de DELETE sans condition.
- Vérifier une écriture en la relisant.
- Messages d'erreur de l'API montrés tels quels, jamais le texte brut d'une exception.

## Dossiers
Chaque session ne modifie que son dossier : `api/`, `app/` ou `site/`.
Exceptions : `docs/PLAN.md`, `docs/AUDIT_TACHES_ET_TESTS.md` (ajout de sections au bas seulement) et, si c'est
indispensable et signalé dans le compte rendu, `docs/CONTRAT_API.md`.

## Commits
- Petits commits fréquents, message en français à l'impératif.
- `git add` limité au dossier de la session. Jamais de `git add -A`.
- Aucune mention de co-auteur ni de signature d'outil dans le message.
- On développe sur `main`. Les branches `web`, `android/apk`, `ios/build-check`, `ios/simulateur` et
  `ios/testflight` ne servent qu'à déclencher une construction : on y pousse l'état de `main`, on n'y écrit
  jamais de code.

## Reprise
Plusieurs comptes Claude travaillent sur ce projet et un compte peut être coupé à tout moment. Rien
d'important ne reste seulement dans la conversation : toute décision va dans `docs/`. Au moins toutes les 20 à
30 minutes, et à chaque sous-partie terminée, la session met à jour sa ligne de `docs/PLAN.md` (état, fichiers
touchés, dernière action, prochaine action précise), fait un commit de son dossier et pousse, même si l'étape
n'est pas finie, à condition que le code compile.

## Fin de tâche
a) Contrôles du dossier sans erreur : `api` donne `ruff check .` et `pytest` ; `app` donne `flutter analyze` et
   `flutter test` ; `site` donne `npm run lint`, `npx tsc --noEmit` et `npm run build`.
b) Relecture de chaque fichier modifié.
c) Mise à jour de `docs/PLAN.md`.
d) Commit du seul dossier de la session, puis `git push`.
e) Recette : une fois le déploiement fini, vérifier que la version en ligne est la nouvelle (`GET /health`
   donne le commit déployé), puis lancer `python -m recette --url https://<URL_API> --bloc <bloc>` depuis
   `api/` et recopier son total. Une croix se corrige avant de passer à la suite. Les sessions App et Site
   lancent la recette des routes qu'elles utilisent.
f) Ajout d'une section au bas de `docs/AUDIT_TACHES_ET_TESTS.md` avec cinq rubriques : Fait (trois lignes au
   plus) ; Vérifié par Claude (tests automatiques et total de la recette en ligne) ; À tester par vous (3 à 6
   gestes numérotés, chacun avec l'appareil, le mode clair ou sombre et le résultat attendu) ; Résultat (laissé
   vide) ; Reste à faire. Commit et push de ce fichier avec le dossier.
g) Compte rendu en quatre points : ce qui est fait et comment c'est vérifié, ce qui n'a pas pu être vérifié, ce
   que l'exploitant doit tester sur téléphone, ce qui a été remarqué hors périmètre.
