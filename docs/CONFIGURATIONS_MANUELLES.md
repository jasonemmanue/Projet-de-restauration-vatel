# Configurations manuelles

<!-- Rôle : liste des tâches que l'exploitant fait lui-même dans un navigateur ou un compte
     développeur (Google Cloud, Firebase, Apple, GeniusPay, boutiques). Pour chacune : l'état,
     la procédure exacte, et les valeurs publiques récoltées. Aucun secret dans ce fichier :
     les secrets vont dans les variables Railway ou dans un fichier local ignoré par git. -->

Mis à jour le 21 novembre 2026.

| # | Tâche | État |
|---|-------|------|
| 1 | Connecter gcloud au projet Firebase | fait |
| 2 | Restreindre les trois clés API Firebase | en cours |
| 3 | Connexions Google et Apple + clients OAuth | à faire |
| 4 | Apple Developer (App ID, Services ID, clés .p8) | à faire |
| 5 | API Gmail (envoi réel des codes) | à faire |
| 6 | GeniusPay (clés, webhooks, taux de frais) | à faire |
| 7 | Fiches des boutiques (Play, App Store) | à faire |

Rappels permanents :
- Projet Google Cloud et Firebase : `vatel-project`, numéro `814642268084`, propriétaire
  `emmanudev2@gmail.com`.
- Identifiant de l'application : `com.vatel.cantine` (paquet Android et bundle iOS).
- Empreinte SHA-1 de débogage : `CA:8A:1F:20:6C:05:3D:5D:29:AE:7D:EF:BB:82:19:C9:AB:73:19:76`.
- API en ligne : `https://projet-de-restauration-vatel-production.up.railway.app`.

---

## 1. Connecter gcloud au projet Firebase — fait

Pourquoi : sans cette connexion, impossible de créer la clé de l'Admin SDK, donc pas de
notifications push.

Procédure (PowerShell, dans n'importe quel dossier) :
1. `gcloud auth login` — un navigateur s'ouvre, choisir **emmanudev2@gmail.com**, accepter.
2. `gcloud config set project vatel-project`
3. `gcloud config list` — vérifier `account = emmanudev2@gmail.com` et `project = vatel-project`.
4. `gcloud iam service-accounts list --project vatel-project`

À reporter : la ligne du compte de service `firebase-adminsdk-...@vatel-project.iam.gserviceaccount.com`
(c'est une adresse publique, pas un secret).

Valeurs récoltées :
- Compte de service Admin SDK : `firebase-adminsdk-fbsvc@vatel-project.iam.gserviceaccount.com`
- Compte gcloud actif : `emmanudev2@gmail.com`, projet `vatel-project` (c'était `prepaxia-project` avant)
- Suite : la session API a généré la clé de ce compte de service et l'a posée dans Railway
  (`FIREBASE_COMPTE_SERVICE` en base64, `FIREBASE_PROJET_ID`, `FCM_ACTIF`). Le JSON reste hors dépôt.
  Rien de plus à faire sur cette tâche.

---

## 2. Restreindre les trois clés API Firebase — en cours

Pourquoi : ces trois clés ne sont pas des mots de passe. Elles identifient le projet et sont
livrées dans l'application Android, dans l'application iOS et dans le code de la page web :
n'importe qui peut les lire. Elles ont été commitées ce matin puis retirées, mais elles restent
dans l'historique d'un dépôt public — les retirer de l'historique ne changerait rien, puisqu'elles
partent de toute façon dans chaque application installée. Ce qui protège, c'est la restriction :
une clé bridée au paquet `com.vatel.cantine` et à l'empreinte SHA-1 ne fonctionne que depuis notre
application ; une clé bridée aux domaines du site ne fonctionne que depuis nos pages. Sans
restriction, un tiers peut appeler nos quotas Firebase avec notre clé et nous faire facturer.

Procédure :
1. Ouvrir `https://console.cloud.google.com/apis/credentials?project=vatel-project`.
2. Section **Clés API** : trois clés créées par Firebase (Android, iOS, Navigateur).
3. Clé Android : ouvrir, **Restrictions liées aux applications** → *Applications Android* →
   *Ajouter un élément* → nom du paquet `com.vatel.cantine`, empreinte SHA-1 ci-dessus. Enregistrer.
4. Clé iOS : **Applications iOS** → *Ajouter un élément* → identifiant de bundle
   `com.vatel.cantine`. Enregistrer.
5. Clé Navigateur : **Sites web** → ajouter l'adresse du site, celle de l'application web, et
   `http://localhost:3000` plus `http://localhost:8080` pour le développement. Enregistrer.
6. Sur chaque clé, **Restrictions relatives aux API** → *Restreindre la clé* → cocher au minimum
   Identity Toolkit API, Token Service API, Firebase Installations API, FCM Registration API,
   Cloud Firestore API. Enregistrer.

À reporter : « clés restreintes » plus la liste des domaines mis sur la clé web.

Valeurs récoltées :
- Domaines autorisés (clé web) : _(à remplir)_

---

## 3. Connexions Google et Apple + clients OAuth — à faire

Procédure, côté Firebase d'abord :
1. Ouvrir `https://console.firebase.google.com/project/vatel-project/authentication/providers`.
2. **Google** → activer, courriel d'assistance `emmanudev2@gmail.com`, enregistrer.
3. **Apple** → activer (les champs Services ID et clé viennent de la tâche 4 ; laisser vide si
   pas de compte Apple payant).
4. Onglet **Settings** → *Authorized domains* → ajouter le domaine du site et celui de
   l'application web.

Puis côté Google Cloud, `https://console.cloud.google.com/apis/credentials?project=vatel-project` :
5. **Créer des identifiants** → *ID client OAuth* → type **Application Web** : origines autorisées
   l'adresse de l'application web plus `http://localhost:3000`, URI de redirection
   `https://vatel-project.firebaseapp.com/__/auth/handler`.
6. **Créer des identifiants** → *ID client OAuth* → type **Android** : paquet `com.vatel.cantine`,
   empreinte SHA-1 ci-dessus.
7. **Créer des identifiants** → *ID client OAuth* → type **iOS** : bundle `com.vatel.cantine`.

À reporter : les trois identifiants de client, qui finissent par `.apps.googleusercontent.com`
(publics, ils figurent déjà dans les fichiers de configuration livrés avec l'application).

Valeurs récoltées :
- Client Web : _(à remplir)_
- Client Android : _(à remplir)_
- Client iOS : _(à remplir)_

---

## 4. Apple Developer — à faire

Ne concerne que l'exploitant s'il a un compte Apple Developer payant (99 USD par an). Sans ce
compte, pas de build iOS signé ni de notification push iOS : **iOS se limitera à la version web**,
qui fonctionne dans Safari sur iPhone, connexion Google comprise.

Procédure, avec un compte payant :
1. `https://developer.apple.com/account/resources/identifiers/list` → **+** → *App IDs* → *App* →
   description « Cantine Vatel », Bundle ID explicite `com.vatel.cantine`, cocher
   **Sign in with Apple** et **Push Notifications**. Enregistrer.
2. Même page → **+** → *Services IDs* → description « Cantine Vatel Web », identifiant
   `com.vatel.cantine.web`. Puis l'ouvrir, cocher Sign in with Apple, configurer le domaine du
   site et l'URL de retour `https://vatel-project.firebaseapp.com/__/auth/handler`.
3. `https://developer.apple.com/account/resources/authkeys/list` → **+** → cocher
   *Sign in with Apple* → télécharger le `.p8` (téléchargeable une seule fois).
4. Même page → **+** → cocher *Apple Push Notifications service (APNs)* → télécharger le second `.p8`.
5. `https://console.firebase.google.com/project/vatel-project/settings/cloudmessaging` → section
   Apple → déposer la clé APNs `.p8`, avec son Key ID et le Team ID.

Où ranger les fichiers : les deux `.p8` restent **hors du dépôt**, dans
`C:\Users\hp\secrets-vatel\`. Ne jamais les ajouter à git.

À reporter : « compte Apple payant oui/non », le Team ID, les deux Key ID (publics). Jamais le
contenu des `.p8`.

Valeurs récoltées :
- Compte Apple payant : _(à remplir)_
- Team ID : _(à remplir)_
- Key ID Sign in with Apple : _(à remplir)_
- Key ID APNs : _(à remplir)_
- Services ID : _(à remplir)_

---

## 5. API Gmail — à faire

Pourquoi : en fin de journée, le code de vérification à 5 caractères doit partir par un vrai
courriel, pas rester en mode démo.

Procédure :
1. `https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=vatel-project` →
   **Activer**.
2. `https://console.cloud.google.com/auth/overview?project=vatel-project` → écran de consentement
   OAuth, type *Externe*, nom « Cantine Vatel », courriel d'assistance, enregistrer.
3. Onglet **Audience** → *Utilisateurs de test* → ajouter l'adresse expéditrice choisie.
4. `https://console.cloud.google.com/apis/credentials?project=vatel-project` → **Créer des
   identifiants** → *ID client OAuth* → type **Application de bureau**, nom « Cantine Vatel envoi ».
5. Télécharger le JSON du client dans `C:\Users\hp\secrets-vatel\gmail-client.json` (hors dépôt).
6. Obtenir le jeton de rafraîchissement avec le script fourni par la session API
   (`python -m outils.jeton_gmail`), qui ouvre le navigateur et demande l'autorisation de
   l'adresse expéditrice.
7. Poser les quatre variables dans Railway, projet « HACKATON VATEL », service
   « Projet-de-restauration-vatel », onglet **Variables** :
   `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, `GMAIL_EXPEDITEUR`.

À reporter : « 4 variables Gmail posées dans Railway » et l'adresse expéditrice. Jamais les valeurs
du client secret ni du jeton.

Valeurs récoltées :
- Adresse expéditrice : _(à remplir)_

---

## 6. GeniusPay — à faire

À récupérer dans le tableau de bord marchand GeniusPay :
1. La clé marchand de **test**.
2. La clé marchand **réelle**.
3. Le **secret de signature des webhooks**.
4. Déclarer les deux adresses de webhook :
   - `https://projet-de-restauration-vatel-production.up.railway.app/api/v1/paiements/webhook/test`
   - `https://projet-de-restauration-vatel-production.up.railway.app/api/v1/paiements/webhook/reel`
5. Les trois taux de frais, en clair, tels que le contrat les fixe : pourcentage à l'encaissement,
   part fixe en XOF par transaction, pourcentage au retrait. L'application doit afficher ce que la
   cantine supporte vraiment, donc ces trois nombres se règlent dans la table `parametres` par le
   back office, jamais en dur.
6. Les clés vont dans Railway (`GENIUSPAY_CLE_TEST`, `GENIUSPAY_CLE_REELLE`,
   `GENIUSPAY_SECRET_WEBHOOK`), jamais dans le dépôt ni dans la conversation.

À reporter : « clés posées dans Railway », « webhooks déclarés », et les trois taux de frais.

Valeurs récoltées :
- Pourcentage à l'encaissement : _(à remplir)_
- Part fixe par transaction (XOF) : _(à remplir)_
- Pourcentage au retrait : _(à remplir)_

---

## 7. Fiches des boutiques — à faire

Seulement si le temps le permet. Les visuels sont prêts dans `docs/marque/exports/`.
1. `https://play.google.com/console` → créer l'application, nom « Cantine Vatel », français
   (Côte d'Ivoire) par défaut.
2. Description courte (80 caractères) et longue (4000), à écrire ensemble.
3. Icône 512 × 512, bannière 1024 × 500, 2 à 8 captures par format.
4. Questionnaire de contenu, public cible, politique de confidentialité (page du site).
5. `https://appstoreconnect.apple.com` → même chose, seulement avec un compte Apple payant.

Valeurs récoltées :
- Nom retenu dans les boutiques : _(à remplir)_
