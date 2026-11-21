// Role du fichier : produire tous les exports PNG de la marque dans docs/marque/exports/.
// Le rendu passe par Edge sans interface, deja installe sur le poste : aucune dependance a installer.
// Les SVG sources viennent de docs/marque/, eux memes produits par docs/marque/outils/svg_marque.py.
// L icone carree reprend l export de reference de la maquette (public/brand/mark.jpg) au lieu d en refaire un.
// Lancer : node app/outils/marque.mjs

import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync, rmSync, statSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const ICI = dirname(fileURLToPath(import.meta.url))
const RACINE = resolve(ICI, '..', '..')
const MARQUE = join(RACINE, 'docs', 'marque')
const EXPORTS = join(MARQUE, 'exports')
const TEMPORAIRE = join(EXPORTS, '.travail')

// Couleurs de fond, reprises de la charte. Aucune valeur inventee ici.
const FOND_CLAIR = '#f4f6fb'
const FOND_SOMBRE = '#0b1220'
const FOND_ACCENT_DOUX = '#e8efff'

/** Rend le chemin du navigateur sans interface, ou arrete avec un message clair. */
function navigateur() {
  const candidats = [
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    '/usr/bin/microsoft-edge',
    '/usr/bin/google-chrome',
  ]
  const trouve = candidats.find((c) => existsSync(c))
  if (!trouve) throw new Error('Aucun Edge ni Chrome trouve pour le rendu sans interface.')
  return trouve
}

/** Rend le premier chemin existant parmi plusieurs, ou arrete avec un message clair. */
function premierPresent(chemins, quoi) {
  const trouve = chemins.find((c) => existsSync(c))
  if (!trouve) throw new Error(`${quoi} introuvable. Cherche dans : ${chemins.join(', ')}`)
  return trouve
}

/** Rend le chemin de l export de reference de la maquette, ou null s il n est pas la. */
function referenceCarree() {
  const candidats = [
    join(RACINE, 'docs', 'maquette', 'public', 'brand', 'mark.jpg'),
    join(RACINE, 'uiux vatel', 'INTERFACE_SAKAM', 'public', 'brand', 'mark.jpg'),
  ]
  return candidats.find((c) => existsSync(c)) ?? null
}

/** Attend qu un fichier existe et que sa taille ne bouge plus, puis rend sa taille. */
function attendreFichier(chemin, secondes = 30) {
  const limite = Date.now() + secondes * 1000
  let derniere = -1
  while (Date.now() < limite) {
    if (existsSync(chemin)) {
      const taille = statSync(chemin).size
      if (taille > 0 && taille === derniere) return taille
      derniere = taille
    }
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 200)
  }
  throw new Error(`Rendu manque ou incomplet : ${chemin}`)
}

/** Capture une page HTML a la taille exacte demandee et ecrit le PNG. */
function capturer(html, largeur, hauteur, sortie) {
  const marque = `${Date.now()}-${Math.random().toString(16).slice(2)}`
  const page = join(TEMPORAIRE, `page-${marque}.html`)
  writeFileSync(page, html, 'utf8')
  // Un ancien fichier ferait croire a une capture reussie : on part toujours d une sortie vide.
  rmSync(sortie, { force: true })
  const arguments_ = [
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    // Un profil par capture : le verrou de l instance precedente ferait echouer la suivante.
    `--user-data-dir=${join(TEMPORAIRE, `profil-${marque}`)}`,
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    '--default-background-color=00000000',
    '--virtual-time-budget=4000',
    `--window-size=${largeur},${hauteur}`,
    `--screenshot=${sortie}`,
    pathToFileURL(page).href,
  ]
  execFileSync(navigateur(), arguments_, { stdio: 'ignore' })
  // Edge rend la main avant d avoir ecrit le fichier : on attend qu il apparaisse et se stabilise.
  attendreFichier(sortie)
  rmSync(page, { force: true })
  console.log(`ecrit ${sortie.replace(RACINE, '').replace(/^[\\/]/, '')}`)
}

/** Reduit un PNG deja rendu a une petite taille, par le script Python qui accompagne la marque. */
function reduire(source, cible, taille) {
  const script = join(MARQUE, 'outils', 'redimensionner.py')
  execFileSync('python', ['-I', script, source, cible, String(taille)], { stdio: 'ignore' })
  attendreFichier(cible, 10)
  console.log(`ecrit ${cible.replace(RACINE, '').replace(/^[\\/]/, '')}`)
}

/** Rend le HTML qui centre une image a une largeur donnee sur un fond donne. */
function pageImage(source, largeurImage, largeur, hauteur, fond) {
  const url = pathToFileURL(source).href
  return `<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;padding:0}
body{width:${largeur}px;height:${hauteur}px;display:flex;align-items:center;justify-content:center;
background:${fond ?? 'transparent'}}
img{width:${largeurImage}px;height:auto;display:block;image-rendering:auto}
</style><img src="${url}">`
}

/** Rend le HTML de l ecran de lancement : logo complet centre sur un aplat. */
function pageLancement(source, largeur, hauteur, fond) {
  const url = pathToFileURL(source).href
  return `<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;padding:0}
body{width:${largeur}px;height:${hauteur}px;display:flex;align-items:center;justify-content:center;
background:${fond}}
img{width:${Math.round(largeur * 0.62)}px;height:auto;display:block}
</style><img src="${url}">`
}

/** Rend le HTML de la banniere Play Store : logo a gauche, aplat accent doux. */
function pageBanniere(source, largeur, hauteur, fond) {
  const url = pathToFileURL(source).href
  return `<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;padding:0}
body{width:${largeur}px;height:${hauteur}px;display:flex;align-items:center;justify-content:center;
background:${fond}}
img{width:${Math.round(largeur * 0.58)}px;height:auto;display:block}
</style><img src="${url}">`
}

function main() {
  mkdirSync(TEMPORAIRE, { recursive: true })

  const symboleClair = premierPresent([join(MARQUE, 'symbole-clair.svg')], 'symbole-clair.svg')
  const silhouette = premierPresent([join(MARQUE, 'symbole-silhouette.svg')], 'symbole-silhouette.svg')
  const completClair = premierPresent([join(MARQUE, 'logo-complet-clair.svg')], 'logo-complet-clair.svg')
  const completSombre = premierPresent([join(MARQUE, 'logo-complet-sombre.svg')], 'logo-complet-sombre.svg')
  const reference = referenceCarree()

  // Icone carree : on reprend l export de reference de la maquette quand il est la.
  const sourceCarree = reference ?? symboleClair
  const fondCarre = reference ? '#ffffff' : FOND_CLAIR
  const grandes = [
    [1024, 'icone-1024.png'],
    [512, 'icone-512.png'],
    [512, 'web-512.png'],
    [192, 'web-192.png'],
  ]
  for (const [taille, nom] of grandes) {
    capturer(pageImage(sourceCarree, taille, taille, taille, fondCarre), taille, taille, join(EXPORTS, nom))
  }
  // Le navigateur sans interface refuse les fenetres de moins de 192 pixels :
  // tout ce qui est plus petit est rendu en grand puis reduit.
  reduire(join(EXPORTS, 'icone-512.png'), join(EXPORTS, 'apple-touch-icon-180.png'), 180)
  for (const taille of [48, 32, 16]) {
    reduire(join(EXPORTS, 'icone-512.png'), join(EXPORTS, `favicon-${taille}.png`), taille)
  }

  // Icone web masquable : le symbole tient dans les 60 pour cent centraux, fond plein.
  capturer(
    pageImage(symboleClair, Math.round(512 * 0.6), 512, 512, FOND_CLAIR),
    512,
    512,
    join(EXPORTS, 'web-512-masquable.png'),
  )

  // Icone adaptative Android : premier plan transparent, symbole dans les 66 pour cent centraux.
  capturer(
    pageImage(symboleClair, Math.round(1024 * 0.66), 1024, 1024, null),
    1024,
    1024,
    join(EXPORTS, 'android-premier-plan-1024.png'),
  )
  capturer(
    `<!doctype html><meta charset="utf-8"><style>html,body{margin:0}body{width:1024px;height:1024px;background:${FOND_CLAIR}}</style>`,
    1024,
    1024,
    join(EXPORTS, 'android-fond-1024.png'),
  )
  capturer(
    pageImage(silhouette, Math.round(1024 * 0.66), 1024, 1024, null),
    1024,
    1024,
    join(EXPORTS, 'android-monochrome-1024.png'),
  )

  // Symboles sur fond transparent : ils servent d ecran de lancement natif, en clair et en sombre.
  capturer(
    pageImage(symboleClair, 660, 1024, 1024, null),
    1024,
    1024,
    join(EXPORTS, 'symbole-transparent-clair-1024.png'),
  )
  capturer(
    pageImage(join(MARQUE, 'symbole-sombre.svg'), 660, 1024, 1024, null),
    1024,
    1024,
    join(EXPORTS, 'symbole-transparent-sombre-1024.png'),
  )

  // Logos des fournisseurs de connexion et des boutiques, sur fond transparent.
  // Ils sont rendus carres et a taille fixe : un bouton ne les deforme jamais.
  const boutons = join(MARQUE, 'boutons')
  for (const [fichier, sortie, largeur] of [
    ['google-g.svg', 'google-g-96.png', 96],
    ['apple.svg', 'apple-96.png', 96],
    ['play.svg', 'play-96.png', 86],
  ]) {
    capturer(
      pageImage(join(boutons, fichier), largeur, 96, 96, null),
      96,
      96,
      join(EXPORTS, sortie),
    )
  }

  // Icone de notification : silhouette blanche sur fond transparent, rendue en 512 puis reduite en 96.
  const notificationGrande = join(TEMPORAIRE, 'notification-512.png')
  capturer(pageImage(silhouette, 384, 512, 512, null), 512, 512, notificationGrande)
  reduire(notificationGrande, join(EXPORTS, 'icone-notification-96.png'), 96)

  // Ecrans de lancement et banniere de boutique.
  capturer(pageLancement(completClair, 1080, 1920, FOND_CLAIR), 1080, 1920, join(EXPORTS, 'lancement-clair.png'))
  capturer(
    pageLancement(completSombre, 1080, 1920, FOND_SOMBRE),
    1080,
    1920,
    join(EXPORTS, 'lancement-sombre.png'),
  )
  capturer(
    pageBanniere(completClair, 1024, 500, FOND_ACCENT_DOUX),
    1024,
    500,
    join(EXPORTS, 'play-store-1024x500.png'),
  )

  // Un Edge qui finit de se fermer garde parfois son profil : le menage n est pas bloquant.
  try {
    rmSync(TEMPORAIRE, { recursive: true, force: true })
  } catch {
    console.log('dossier de travail laisse en place, un navigateur le tient encore')
  }
  console.log(reference ? 'termine, icone carree reprise de la maquette' : 'termine, icone carree rendue du SVG')
}

main()
