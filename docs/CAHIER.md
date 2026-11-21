# CANTINE VATEL, le projet en une page

## Le problème
Les cantines scolaires et d'entreprise en Côte d'Ivoire vivent au comptant et au papier : files d'attente à
l'heure du service, repas préparés en trop ou en trop peu, régimes et allergies connus de personne, menus et
tarifs annoncés de bouche à oreille, caisse tenue à la main. Les parents ne savent ni ce que mange leur enfant
ni ce qu'il reste sur son compte.

## La réponse
Chaque convive a un porte-monnaie électronique. Il choisit ses plats dans le menu de la semaine, un par
service (entrée, résistance, sortie), et commande avant l'heure limite du jour. Il n'y a ni heure ni créneau
à choisir : il vient manger quand il veut ce jour-là.
Les trois services sont au choix : il peut ne prendre que la résistance, mais le menu est vendu comme un
tout, donc il paie le prix du jour dans les deux cas.
Il réserve pour la période qu'il veut : un jour, une semaine entière, ou un mois. Le paiement part en une
fois, et il reçoit un ticket QR par jour. La cuisine connaît donc à l'avance le nombre de parts de chaque
plat, service par service. Au comptoir, l'agent scanne le
ticket : le repas est servi, la réservation est consommée, le stock baisse. Les parents rechargent le compte
par Mobile Money ou envoient un lien de paiement à un proche. L'administration planifie les menus, voit les
commandes du jour avant de cuisiner, suit les stocks et lit ses chiffres sur un tableau de bord.

## Les quatre rôles
| Rôle | Ce qu'il fait |
| --- | --- |
| convive | menu de la semaine, réservation, ticket QR, solde et historique, notes des plats, suggestions, allergies |
| parent | liaison à ses enfants par code, recharge, lien de paiement, suivi des repas, seuil d'alerte de solde bas |
| agent | scan des tickets, service en cours. Rien d'autre |
| admin | plats, tarifs, menus, commandes, stocks, frais GeniusPay, rapports, utilisateurs, paiements, réglages, journal |

Le compte d'un convive porte un statut : `eleve`, `etudiant`, `employe` ou `autre`. Tout le monde peut payer
pour soi, élève compris, par le même mécanisme Mobile Money : mêmes montants, mêmes opérateurs, même webhook
GeniusPay, même écriture au porte-monnaie. Un parent lié peut en plus recharger le compte de ses enfants.
Un employé, un étudiant ou un compte « autre » n a besoin d aucune liaison. Et depuis n importe quel écran
d'argent, un convive peut créer un lien de paiement pour se faire payer par un proche. Le statut sert au
tarif et aux statistiques, jamais à interdire un paiement.

## Le flux

Commande, paiement, livraison, sortie de stock. Dans cet ordre, sans exception : rien n'est préparé qui n'ait
été commandé et payé, et le stock ne bouge qu'au moment où le plat est remis au convive.

La commande se gèle la veille du service à 18 h 00 (`heure_gel_commandes`), parce que la cuisine achète sur
cette base. Avant le gel, le convive modifie ou annule et il est remboursé. Après, il ne peut plus que
supprimer sa commande, et il n'est pas remboursé : les achats sont faits.

La commande engage le convive. Sa part est achetée, préparée et mise de côté à son nom : qu'il vienne ou
non, elle est à lui et elle reste payée. Il n'y a donc pas de restes à brader en fin de service, et la
cuisine ne prépare que ce qui a été commandé. Les repas non réclamés sont comptés au tableau de bord, pour
que la cantine sache ce qu'elle a préparé pour rien.

Les frais de GeniusPay sont supportés par la cantine. Le convive est crédité de ce qu'il a payé, la cantine
reçoit moins : des frais sont retenus à l'encaissement, et encore au retrait. Le tableau de bord montre les
trois chiffres côte à côte, recettes brutes, frais supportés, net attendu, pour que les prix soient fixés en
connaissance de cause.

## Rythme de la semaine

Le menu de toute la semaine est préparé et publié le jeudi pour la semaine suivante. L'administration
travaille donc par semaine entière, pas jour par jour : duplication d'une semaine, publication groupée,
et les convives voient la semaine à venir dès qu'elle est publiée. Le jour de publication est un réglage
du back office (`jour_publication_menu`), au cas où la cantine change d'habitude.

## Minimum exigé par le jury
- Inscription et connexion par numéro ou e-mail et mot de passe.
- Vérification de l'identifiant juste après l'inscription : code à 6 chiffres pour un numéro, code de 5
  caractères majuscules et chiffres pour un e-mail, généré et contrôlé par l'API, rempli automatiquement en
  mode démo, e-mail réel en fin de journée.
- Menu de la semaine.
- Réservation d'un repas.
- Solde et historique.
- Côté admin : création et modification des menus, commandes du jour, tableau de bord avec statistiques.

## Bonus retenus, dans l'ordre
Notation des plats, suggestions personnalisées, français et anglais, Mobile Money, notifications push Android
iOS et web, mode hors ligne (ticket QR, scan de l'agent avec synchronisation au retour, menu, solde,
appréciations en attente, back office en lecture), connexion avec Google, connexion avec Apple, connexion d'un ordinateur ou
d'une tablette par QR code scanné avec le téléphone déjà connecté.

## Pile technique
- `api/` : FastAPI, Python 3.12, SQLAlchemy 2 asynchrone, asyncpg, Alembic, Pydantic 2, pytest, ruff.
- `app/` : Flutter 3.38 pour Android, iOS et web. Riverpod, GoRouter, Dio. Le back office est un espace de
  cette même application, réservé au rôle admin.
- `site/` : Next.js (App Router, TypeScript, Tailwind), responsive, site public et pages légales.
- PostgreSQL et hébergement Railway. Notifications par Firebase Cloud Messaging. Paiement GeniusPay.
- Codes de vérification générés et contrôlés par l'API pour les deux canaux. Livraison réglée par canal :
  `demo` (le code revient dans la réponse et l'application le remplit) ou `reel` (e-mail envoyé par l'API
  Gmail, jamais SMTP, que Railway bloque). Le téléphone reste en démo pendant le hackathon.
- Pas de Redis : une seule instance d'API, verrous par PostgreSQL.

## Règles qui ne bougent pas
Le serveur décide de tout. Seule l'API touche la base. Montants en entiers XOF, heures en UTC. Tout réglage
passe par la table `parametres` et le back office. Le solde n'existe que par ses mouvements. Le dépôt est
public, donc aucun secret n'y entre.

## Journée
8h à 18h. Les maquettes arrivent à 8h20 dans `docs/maquette/` et servent de référence unique. Le suivi des
étapes vit dans `docs/PLAN.md`, le journal des recettes dans `docs/AUDIT_TACHES_ET_TESTS.md`. L'application
complète est présentée au jury à 12h30, les suppléments ensuite.
