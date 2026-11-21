# Charte, version provisoire

Ce fichier est volontairement incomplet. Il fixe seulement les tailles de texte et la liste des rôles de
couleur. Les valeurs de couleur sont décidées à l'étape P01, à partir du logo et de
`docs/maquette/src/shared/styles/tokens.css`. Aucune session ne remplit une valeur ici avant P01, et aucune
session n'invente une couleur qui ne figure pas dans la maquette.

## Tailles de texte par type d'écran

Trois tailles d'écran, mesurées sur la largeur disponible : téléphone sous 600 px, tablette de 600 à 1024 px,
ordinateur au-delà de 1024 px. Les valeurs sont en points logiques.

| Rôle du texte | Téléphone | Tablette | Ordinateur |
| --- | --- | --- | --- |
| Titre d'écran | 24 | 28 | 32 |
| Titre de section | 20 | 22 | 24 |
| Sous-titre | 17 | 18 | 20 |
| Corps | 15 | 16 | 16 |
| Corps secondaire | 13 | 14 | 14 |
| Libellé de bouton | 15 | 16 | 16 |
| Libellé d'onglet | 12 | 13 | 13 |
| Mention légale | 11 | 12 | 12 |
| Montant mis en avant | 28 | 32 | 36 |

Règles d'application :
- Aucun texte n'est coupé par des points de suspension. Si la place manque, la taille baisse d'un cran ou le
  texte passe à la ligne.
- Un montant ne descend jamais sous la taille du corps.
- Ces tailles suivent le réglage de taille de police du système, sans casser la mise en page.

## Rôles de couleur

Chaque rôle existe en mode clair et en mode sombre. Les valeurs arrivent en P01. Aucun écran n'écrit une
couleur en dur : tout passe par le thème.

| Rôle | À quoi il sert |
| --- | --- |
| fond | fond général de l'écran |
| surface | cartes, feuilles du bas, champs, barres |
| texte | texte principal sur fond et sur surface |
| texte secondaire | légendes, aides, dates, états neutres |
| accent | identité de la marque, boutons principaux, onglet actif, liens |
| succès | réservation confirmée, scan accepté, paiement reçu |
| alerte | solde bas, stock faible, heure limite proche |
| erreur | échec de paiement, scan refusé, champ invalide |

Le ticket QR fait exception : il reste noir sur fond blanc dans les deux modes, pour rester lisible par tous
les lecteurs.
