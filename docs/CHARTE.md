# Charte

Tout ce qui suit est repris de `docs/maquette/src/shared/styles/tokens.css` et de
`docs/maquette/src/shared/components/Logo.tsx`. Rien n'y est inventé. Une session qui a besoin d'une couleur
ou d'un libellé absent de ce fichier le demande au lieu de le créer.

Les valeurs vivent dans le thème de l'application. Aucun écran n'écrit une couleur en dur.

## Palette, mode clair

| Rôle | Jeton | Valeur | Usage |
| --- | --- | --- | --- |
| accent | `--accent` | `#2f6bff` | boutons principaux, onglet actif, liens, aiguille de la marque |
| accent doux | `--accent-soft` | `#e8efff` | fonds de pastille, état sélectionné, surfaces d'accent |
| sur accent | `--accent-contrast` | `#ffffff` | texte et icônes posés sur l'accent |
| fond | `--paper`, `--bg` | `#f4f6fb` | fond général de l'écran |
| surface | `--surface`, `--bg-elevated` | `#ffffff` | cartes, feuilles du bas, barres, champs |
| muet | `--muted`, `--bg-muted` | `#eef1f8` | zones calmes, états vides, séparateurs pleins |
| filet | `--line`, `--ring` | `#e2e8f0` | traits de séparation, contours de carte |
| texte | `--ink`, `--text` | `#0f172a` | texte principal |
| texte secondaire | `--text-muted` | `#64748b` | légendes, dates, aides |
| texte adouci | `--ink-soft` | `#1e293b` | titres secondaires sur surface |
| succès | `--success` | `#0d9488` | réservation confirmée, scan accepté, paiement reçu |
| danger | `--danger` | `#ef4444` | échec de paiement, scan refusé, champ invalide |
| alerte | `--warn` | `#f59e0b` | solde bas, stock faible, heure limite proche |
| contraste | `--contrast` | `#0f172a` | surfaces toujours sombres : favoris, anti-gaspillage |
| sur contraste | `--on-contrast` | `#ffffff` | texte posé sur une surface de contraste |
| sur contraste atténué | `--on-contrast-muted` | `#93c5fd` | texte secondaire sur une surface de contraste |
| champ | `--field` | `#ffffff` | fond des champs de saisie |
| texte de champ | `--field-text` | `#0f172a` | texte saisi |
| accent profond | `--safran-deep` | `#1d4ed8` | état pressé de l'accent |

## Palette, mode sombre

Le mode sombre s'active par l'attribut `data-theme="dark"` sur le document.

| Rôle | Jeton | Valeur | Usage |
| --- | --- | --- | --- |
| accent | `--accent` | `#60a5fa` | identique au mode clair |
| accent doux | `--accent-soft` | `#1e293b` | identique au mode clair |
| sur accent | `--accent-contrast` | `#0f172a` | texte et icônes posés sur l'accent |
| fond | `--paper`, `--bg` | `#0b1220` | fond général de l'écran |
| surface | `--surface`, `--bg-elevated` | `#111827` | cartes, feuilles du bas, barres |
| muet | `--muted`, `--bg-muted` | `#1f2937` | zones calmes, états vides |
| filet | `--line`, `--ring` | `#334155` | traits de séparation |
| texte | `--ink`, `--text` | `#f8fafc` | texte principal |
| texte secondaire | `--text-muted` | `#94a3b8` | légendes, dates, aides |
| texte adouci | `--ink-soft` | `#e2e8f0` | titres secondaires sur surface |
| succès | `--success` | `#0d9488` | inchangé entre les deux modes |
| danger | `--danger` | `#ef4444` | inchangé entre les deux modes |
| alerte | `--warn` | `#f59e0b` | inchangé entre les deux modes |
| contraste | `--contrast` | `#020617` | surfaces toujours sombres |
| sur contraste | `--on-contrast` | `#f8fafc` | texte posé sur une surface de contraste |
| sur contraste atténué | `--on-contrast-muted` | `#93c5fd` | texte secondaire sur une surface de contraste |
| champ | `--field` | `#1e293b` | fond des champs de saisie |
| texte de champ | `--field-text` | `#f8fafc` | texte saisi |
| accent profond | `--safran-deep` | `#93c5fd` | état pressé de l'accent |

## Règles d'affichage

- Aucune ombre : `--shadow: none` et `--shadow-lg: none`. La profondeur vient des aplats et des filets.
- Rayons : 14 px pour le petit (`--radius-sm`), 22 px pour les cartes (`--radius`), 28 px pour le grand
  (`--radius-lg`). Boutons en pilule, hauteur 52 px.
- Typographie : Plus Jakarta Sans pour les titres et le texte, base 14 px. Titres en graisse 800, interlettrage
  -0,04em.
- Icônes Lucide uniquement, trait 1,75. Aucun emoji dans l'interface.
- Majuscule initiale seulement sur les pastilles et les catégories.
- Cartes de plat : photo à bord perdu en haut, contenu paddé en dessous.
- Mode sombre par attribut `data-theme="dark"` sur le document.
- Transitions ressort de 200 à 300 ms, courbe `cubic-bezier(0.22, 1, 0.36, 1)`, de la même famille partout.
- Animations coupées quand le système demande de les réduire.

## Tailles de texte par type d'écran

Téléphone sous 600 px, tablette de 600 à 1024 px, ordinateur au-delà. Valeurs en points logiques, base 14 px.

| Rôle du texte | Téléphone | Tablette | Ordinateur |
| --- | --- | --- | --- |
| Titre d'écran | 24 | 28 | 32 |
| Titre de section | 20 | 22 | 24 |
| Sous-titre | 17 | 18 | 20 |
| Corps | 14 | 15 | 16 |
| Corps secondaire | 13 | 14 | 14 |
| Libellé de bouton | 15 | 16 | 16 |
| Libellé d'onglet | 12 | 13 | 13 |
| Mention légale | 11 | 12 | 12 |
| Montant mis en avant | 28 | 32 | 36 |

Aucun texte n'est coupé par des points de suspension : si la place manque, la taille baisse d'un cran ou le
texte passe à la ligne.

## Contraste

Mesuré par `docs/marque/outils/contraste.py` (formule WCAG 2.1, seuil 4,5 pour 1 pour le texte courant).
Relancer après toute retouche de palette.

| Mode | Texte | Fond | Rapport | Verdict |
| --- | --- | --- | --- | --- |
| clair | texte | fond | 16,51 | ok |
| clair | texte | surface | 17,85 | ok |
| clair | texte | muet | 15,79 | ok |
| clair | texte | accent doux | 15,49 | ok |
| clair | texte secondaire | fond | 4,40 | sous 4,5 |
| clair | texte secondaire | surface | 4,76 | ok |
| clair | accent | fond | 4,16 | sous 4,5 |
| clair | accent | surface | 4,50 | limite |
| clair | sur accent | accent | 4,50 | limite |
| clair | sur contraste | contraste | 17,85 | ok |
| clair | sur contraste atténué | contraste | 9,90 | ok |
| clair | texte de champ | champ | 17,85 | ok |
| clair | succès | surface | 3,74 | sous 4,5 |
| clair | danger | surface | 3,76 | sous 4,5 |
| clair | alerte | surface | 2,15 | sous 4,5 |
| clair | filet | surface | 1,23 | séparateur, hors texte |
| sombre | texte | fond | 17,89 | ok |
| sombre | texte | surface | 16,96 | ok |
| sombre | texte | muet | 14,03 | ok |
| sombre | texte | accent doux | 13,98 | ok |
| sombre | texte secondaire | fond | 7,30 | ok |
| sombre | texte secondaire | surface | 6,92 | ok |
| sombre | accent | fond | 7,36 | ok |
| sombre | accent | surface | 6,98 | ok |
| sombre | sur accent | accent | 7,02 | ok |
| sombre | sur contraste | contraste | 19,28 | ok |
| sombre | sur contraste atténué | contraste | 11,19 | ok |
| sombre | texte de champ | champ | 13,98 | ok |
| sombre | succès | surface | 4,74 | ok |
| sombre | danger | surface | 4,71 | ok |
| sombre | alerte | surface | 8,26 | ok |
| sombre | filet | surface | 1,71 | séparateur, hors texte |

### Paires signalées, sans modification

Le mode sombre passe partout. Les paires suivantes sont sous 4,5 pour 1 en mode clair. Elles sont signalées
telles quelles, sans retouche de palette : la décision revient à l'exploitant.

1. texte secondaire sur fond, 4,40. Juste sous le seuil. Acceptable en grande taille (18 px ou 14 px en gras),
   insuffisant pour une légende de 13 px posée sur le fond général.
2. accent sur fond, 4,16, et accent sur surface, 4,50 tout juste. Un lien bleu en texte courant sur le fond
   général est sous le seuil.
3. sur accent, 4,50 tout juste : le blanc sur le bouton accent tient le seuil au chiffre près, sans marge.
4. succès 3,74, danger 3,76 et alerte 2,15 sur surface : ces trois couleurs ne doivent pas porter de texte
   courant en mode clair. Elles conviennent en aplat (pastille colorée avec texte foncé) ou en icône
   accompagnée d'un libellé en couleur texte.
5. filet sur surface, 1,23 en clair et 1,71 en sombre : c'est un séparateur décoratif, pas un contour de
   composant interactif. Si un filet devient le seul contour d'un champ ou d'un bouton, il lui faut 3 pour 1.

## Marque

Fichiers dans `docs/marque/`, décrits dans `docs/marque/LISEZMOI.md`. Le symbole est l'assiette, l'encoche de
créneau et l'aiguille. Couleurs propres à la marque, reprises de `Logo.tsx` et distinctes des jetons
d'interface :

| Ton | Trait | Accent | Remplissage |
| --- | --- | --- | --- |
| sur fond clair | `#171717` | `#2557d6` | `#ffffff` |
| sur fond sombre | `#f5f5f4` | `#6b93ff` | `#1c1c1c` |

Nom « Cantine Vatel » en Plus Jakarta Sans graisse 700, interlettrage -0,045em. Signature
« Créneau · Repas · QR » en graisse 600, interlettrage 0,08em, en majuscules.
