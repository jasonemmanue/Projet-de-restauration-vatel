# Marque Cantine Vatel

Tout ce dossier est produit à partir de la maquette, sans rien inventer : le symbole vient de
`shared/components/Logo.tsx` (assiette, encoche de créneau, aiguille), les couleurs de
`shared/styles/tokens.css`, et l'icône carrée reprend l'export de référence `public/brand/mark.jpg` de la
maquette au lieu d'en produire un autre.

Deux outils relançables, aucun paquet à installer :

```
python docs/marque/outils/svg_marque.py   # les SVG, nom converti en tracés
node app/outils/marque.mjs                # tous les PNG, rendus par Edge sans interface
python docs/marque/outils/contraste.py    # le tableau de contraste de docs/CHARTE.md
```

## Fichiers vectoriels

| Fichier | À quoi il sert | Où il est utilisé |
| --- | --- | --- |
| `symbole-clair.svg` | symbole seul, couleurs sur fond clair | en-tête de l'application en mode clair, favicon vectoriel |
| `symbole-sombre.svg` | symbole seul, couleurs sur fond sombre | en-tête de l'application en mode sombre |
| `logo-complet-clair.svg` | symbole, « Cantine Vatel » et la signature, sur fond clair | écran de lancement clair, site public, documents |
| `logo-complet-sombre.svg` | le même sur fond sombre | écran de lancement sombre, site en mode sombre |
| `logo-noir.svg` | logo complet en une seule couleur `#171717`, fond transparent | impression, fax de reçu, document noir et blanc |
| `logo-noir-symbole.svg` | symbole seul en `#171717` | tampon, filigrane sur document clair |
| `logo-blanc.svg` | logo complet en `#f5f5f4`, fond transparent | photo, aplat accent, fond sombre |
| `logo-blanc-symbole.svg` | symbole seul en `#f5f5f4` | barre colorée, bandeau |
| `symbole-silhouette.svg` | silhouette pleine, une seule couleur, formes épaissies | source des icônes de notification et du monochrome Android |

Les paires claire et sombre se lisent ainsi : `logo-noir` est la version pour fond clair, `logo-blanc` la
version pour fond sombre. Une version « noir sur fond sombre » n'existe pas, elle serait illisible.

## Exports PNG, dans `exports/`

| Fichier | Taille | Fond | Où il sert |
| --- | --- | --- | --- |
| `icone-1024.png` | 1024 | opaque blanc | icône de l'application, source des boutiques |
| `icone-512.png` | 512 | opaque | icône de l'application, usage général |
| `web-512.png` | 512 | opaque | manifeste web, icône 512 |
| `web-192.png` | 192 | opaque | manifeste web, icône 192 |
| `web-512-masquable.png` | 512 | `#f4f6fb` | manifeste web, icône masquable, symbole dans les 60 % centraux |
| `apple-touch-icon-180.png` | 180 | opaque | écran d'accueil iOS depuis le navigateur |
| `favicon-48.png`, `favicon-32.png`, `favicon-16.png` | 48, 32, 16 | opaque | onglet du site et du back office |
| `android-premier-plan-1024.png` | 1024 | transparent | icône adaptative Android, couche avant, symbole dans les 66 % centraux |
| `android-fond-1024.png` | 1024 | `#f4f6fb` | icône adaptative Android, couche de fond |
| `android-monochrome-1024.png` | 1024 | transparent | icône adaptative Android, couche monochrome du thème dynamique |
| `icone-notification-96.png` | 96 | transparent | petite icône de notification Android, silhouette blanche |
| `lancement-clair.png` | 1080 x 1920 | `#f4f6fb` | écran de lancement, mode clair |
| `lancement-sombre.png` | 1080 x 1920 | `#0b1220` | écran de lancement, mode sombre |
| `play-store-1024x500.png` | 1024 x 500 | `#e8efff` | bandeau de la fiche Play Store |

## Polices

`polices/` contient les trois graisses de Plus Jakarta Sans utilisées par la maquette (600, 700, 800) et sa
licence, `LICENCE-Plus-Jakarta-Sans.txt` : SIL Open Font License 1.1, libre d'usage et de redistribution.
Les SVG n'ont pas besoin de la police installée : le nom et la signature y sont des tracés, convertis par
`svg_marque.py` avec fontTools. La police reste là pour l'application, le site et une éventuelle reprise des
tracés.

Aucune autre image ni police n'entre ici sans licence libre.

## Ce que le script ne fait pas

- Il ne produit pas de `.ico` : les navigateurs visés lisent les PNG déclarés dans le manifeste.
- Il ne touche jamais la maquette. Celle-ci se lit, ne se modifie pas et ne se compile pas.
- Il ne redessine pas l'icône carrée tant que `mark.jpg` est présent dans la maquette. Si ce fichier
  disparaît, le script rend l'icône depuis `symbole-clair.svg` et le dit à la fin de son exécution.
