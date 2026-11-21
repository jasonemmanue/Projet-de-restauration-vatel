# Site public de Cantine Vatel

Next.js (App Router, TypeScript, Tailwind). Présentation, téléchargement de l'application et pages légales.

```bash
npm install
cp .env.example .env.local   # puis remplir les trois liens
npm run dev
npm run build
```

## Ce que la page d'accueil adapte toute seule

| Appareil du visiteur | Téléchargement proposé | Connexion proposée |
| --- | --- | --- |
| Android, application web comprise | Google Play, Web / PC | Google, code QR |
| iPhone et iPad, application web comprise | App Store, Web / PC | Google, Apple, code QR |
| Ordinateur | Google Play, App Store, Web / PC, plus un code QR pour passer au téléphone | Google, Apple, code QR |

iPadOS se présente comme un Mac : il est reconnu par son écran tactile (`navigator.maxTouchPoints`).

## Règles de dessin

- Les couleurs viennent de `app/globals.css`, qui recopie `docs/CHARTE.md`. Aucune couleur ailleurs.
- Les badges de boutique ont une taille fixe (58 x 196) et leur logo vit dans une boîte carrée de 26 px en
  ajustement par contenu : aucun badge ne se déforme.
- Les boutons Google et Apple font 52 de haut, en pilule, logo dans une boîte de 22 px.
- Les codes QR restent noirs sur fond blanc dans les deux modes, comme le ticket de l'application.
- Aucune ombre : la profondeur vient des aplats et des filets.
