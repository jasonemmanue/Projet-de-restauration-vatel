# Configurations manuelles

<!-- Rôle : liste des tâches que l'exploitant fait lui-même dans un navigateur ou un compte
     développeur (Google Cloud, Firebase, Apple, GeniusPay, boutiques). Pour chacune : l'état,
     la procédure exacte, et les valeurs publiques récoltées. Aucun secret dans ce fichier :
     les secrets vont dans les variables Railway ou dans un fichier local ignoré par git. -->

Mis à jour le 21 novembre 2026.

| # | Tâche | État |
|---|-------|------|
| 1 | Connecter gcloud au projet Firebase | fait |
| 2 | Restreindre les trois clés API Firebase | fait |
| 3 | Clients OAuth Google (hors Firebase Auth) | fait |
| 4 | Apple Developer (App ID, Services ID, clés .p8) | à faire, compte payant confirmé |
| 5 | API Gmail (envoi réel des codes) | fait |
| 6 | GeniusPay (clés, webhooks, taux de frais) | fait |
| 7 | Fiches des boutiques (Play, App Store) | écarté pour aujourd'hui |
| 8 | Clé web push FCM (notifications sur le site) | fait |
| 9 | Compte développeur Google Play (25 USD, une fois) | écarté pour aujourd'hui |
| 11 | Codemagic, construction iOS vers TestFlight | en cours |

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

## 2. Restreindre les trois clés API Firebase — fait

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

Posé le 21/11 en ligne de commande avec l'accord de l'exploitant, plus rapide que la console :
```
gcloud services api-keys update <uid> --project vatel-project   --allowed-application=sha1_fingerprint=<SHA1>,package_name=com.vatel.cantine   # Android
gcloud services api-keys update <uid> --project vatel-project   --allowed-bundle-ids=com.vatel.cantine                                          # iOS
gcloud services api-keys update <uid> --project vatel-project   --allowed-referrers="<liste des domaines>"                                      # Navigateur
```
Vérification : `gcloud services api-keys list --project vatel-project` montre les trois
restrictions appliquées.

Valeurs récoltées :
- Identifiants des clés (publics) : Android `391263db-a232-46cf-8c4f-3a637486f380`,
  iOS `74e45620-4111-45fa-9ce0-b1b15f249512`, Navigateur `de38b51a-79a6-4615-8ed1-11ae7cb35783`.
  Lien direct vers une clé :
  `https://console.cloud.google.com/apis/credentials/key/<uid>?project=vatel-project`
- Clé Android : paquet `com.vatel.cantine` + empreinte SHA-1 de débogage.
- Clé iOS : bundle `com.vatel.cantine`.
- Domaines autorisés (clé web) :
  `https://projet-de-restauration-vatel-production.up.railway.app/*`,
  `https://vatel-project.firebaseapp.com/*`, `https://vatel-project.web.app/*`,
  `http://localhost:3000/*`, `http://localhost:8080/*`.
  À compléter avec le vrai domaine du site Next.js dès qu'il existe.
- Restrictions relatives aux API : volontairement laissées ouvertes pour ne pas casser
  l'application en pleine journée. À resserrer en fin de hackathon.

---

## 3. Clients OAuth Google — fait

Décision du 21/11 : **l'authentification ne passe pas par Firebase Authentication.** Le client
obtient un jeton d'identité Google, l'envoie à notre API (`POST /auth/google`, champ
`jeton_google`), et c'est l'API qui le vérifie auprès de Google puis délivre nos propres jetons.
Firebase ne sert plus qu'aux notifications push. Il n'y a donc rien à activer dans Firebase
Authentication ; tout se passe dans Google Cloud, écran de consentement puis clients OAuth.

Il faut trois clients, parce que Google exige un client par plateforme, et les trois identifiants
sont publics (ils sont livrés dans l'application).

Procédure :
1. `https://console.cloud.google.com/auth/overview?project=vatel-project` → *Commencer* :
   nom « Cantine Vatel », courriel d'assistance `emmanudev2@gmail.com`, audience **Externe**,
   coordonnées, accepter. Écran de consentement créé.
2. Onglet **Données d'accès** (Data access) → ajouter les portées `openid`, `.../auth/userinfo.email`,
   `.../auth/userinfo.profile`. Rien de plus : ce sont des portées non sensibles, aucune
   vérification Google à subir.
3. `https://console.cloud.google.com/auth/clients?project=vatel-project` → *Créer un client* →
   **Application Web**, nom « Cantine Vatel Web ». Origines JavaScript autorisées : l'adresse du
   site, `http://localhost:3000`, `http://localhost:8080`. URI de redirection : seulement si le
   site fait l'échange côté serveur.
4. *Créer un client* → **Android**, nom « Cantine Vatel Android », paquet `com.vatel.cantine`,
   empreinte SHA-1 de débogage. À refaire plus tard avec l'empreinte de publication.
5. *Créer un client* → **iOS**, nom « Cantine Vatel iOS », bundle `com.vatel.cantine`.
6. Recopier les trois identifiants, qui finissent par `.apps.googleusercontent.com`.

Pour la session API : les trois identifiants doivent être acceptés comme audiences valides à la
vérification du jeton, et c'est **l'identifiant du client Web** que l'application Flutter passe en
`serverClientId` à `google_sign_in` sur Android. Variables Railway attendues :
`GOOGLE_CLIENT_ID_WEB`, `GOOGLE_CLIENT_ID_ANDROID`, `GOOGLE_CLIENT_ID_IOS`. Le secret du client
Web (`GOOGLE_CLIENT_SECRET`) n'est nécessaire que si le site échange un code côté serveur : il va
dans Railway, jamais dans le dépôt.

Deux projets Google Cloud, et c'est voulu :
- `cantine-vatel`, numéro **457382581913** : écran de consentement et clients OAuth, donc toute
  l'authentification Google, et l'API Gmail de la tâche 5.
- `vatel-project`, numéro **814642268084** : Firebase, donc les notifications push et les trois
  clés API bridées à la tâche 2.
Rien à unifier : notre API vérifie le jeton par son audience, elle ne demande pas que le client
OAuth et Firebase soient dans le même projet. La seule contrainte, respectée ici, est que le
client Android et le client Web servant de `serverClientId` vivent dans le même projet.

Valeurs récoltées, créées le 21/11 dans `cantine-vatel` (identifiants publics) :
- Client Web : `457382581913-u97oj133odtlq9qd92dlvi12pkigmtlo.apps.googleusercontent.com`
- Client Android : `457382581913-lj1ploqk6f98scr0872jp22o47tm3t4i.apps.googleusercontent.com`
- Client iOS : `457382581913-kenhhok1h0jk1svp6q35647ltrk2q1jh.apps.googleusercontent.com`
- Origines du client Web : `http://localhost:3000` et `http://localhost:8080` pour l'instant.
  L'adresse publique du site reste à ajouter dès que la session Site l'aura donnée, sinon la
  connexion Google échouera depuis le site en ligne avec une erreur `origin_mismatch`.

---

## 4. Apple Developer — à faire, compte payant confirmé le 21/11

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
- Compte Apple payant : **oui**, confirmé par l'exploitant le 21/11. iOS n'est donc pas limité
  au web : build signé et notifications push possibles.
- Team ID : `LD4W7KA5YG`, donné par l'exploitant le 21/11. Nécessaire à la signature du build iOS
  et au dépôt de la clé APNs dans Firebase.
- Key ID Sign in with Apple : _(à remplir)_
- Key ID APNs : `7WB3QA78GD`. Clé créée à l'origine pour Prepaxia, mais elle porte bien le service
  APNs, et une clé APNs vaut pour toute l'équipe Apple et non pour une application : elle couvre
  donc `com.vatel.cantine`. Aucune clé à créer. **Ne jamais la révoquer** tant que Prepaxia
  tourne, les notifications des deux applications s'arrêteraient ensemble. Le fichier `.p8` reste
  chez l'exploitant, hors dépôt.
- Rappel : la clé autorise l'équipe, l'App ID autorise l'application. La case **Push
  Notifications** doit être cochée et enregistrée sur l'App ID `com.vatel.cantine`.
- Dépôt dans Firebase : console uniquement. Ni la CLI Firebase ni l'API publique de gestion ne
  permettent de téléverser une clé APNs ou de générer la clé web push. Une clé APNs vaut pour toute l'équipe, pas pour une application : celle créée
  pour Prepaxia couvre donc aussi `com.vatel.cantine`, à condition d'être dans la même équipe.
  Apple n'autorise que deux clés APNs par équipe, autant ne pas en gâcher une. Si la clé s'avère
  être « Sign in with Apple » ou « App Store Connect API », en créer une vraie.
  Fichier rangé hors dépôt par l'exploitant.
- Services ID : _(à remplir)_

---

## 5. API Gmail — fait

Pourquoi : en fin de journée, le code de vérification à 5 caractères doit partir par un vrai
courriel, pas rester en mode démo.

Procédure :
1. `https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=cantine-vatel` →
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

Piège rencontré le 21/11, à retenir pour toutes les pages Google Cloud : le navigateur était
connecté avec `emmanuelsakam@gmail.com`, qui n'a aucun droit sur ces projets, d'où un refus de
permission qui proposait de demander un rôle à un administrateur. Il ne fallait accorder aucun
rôle, seulement changer de compte. Ajouter `&authuser=emmanudev2@gmail.com` à l'adresse force le
bon compte pour l'onglet.

Utilisateur de test ajouté le 21/11.

Valeurs récoltées :
- Adresse expéditrice : _(à remplir)_

---

## 6. GeniusPay — fait

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

Fait le 21/11 : les six variables sont dans Railway, trois par mode, sous les noms que GeniusPay
emploie lui-même. Noms réels à utiliser côté API, à ne pas renommer :
- mode test : `GENIUSPAY_API_KEY`, `GENIUSPAY_SECRET_KEY`, `GENIUSPAY_WEBHOOK_SECRET`
- mode réel : `GENIUSPAY_LIVE_API_KEY`, `GENIUSPAY_LIVE_SECRET_KEY`, `GENIUSPAY_LIVE_WEBHOOK_SECRET`

Le secret de signature du webhook est donc bien distinct de la clé secrète d'appel, et il y en a un
par mode. La vérification doit utiliser celui du mode de la route appelée :
`GENIUSPAY_WEBHOOK_SECRET` sur `/webhook/test`, `GENIUSPAY_LIVE_WEBHOOK_SECRET` sur
`/webhook/reel`. Un webhook qui ne se vérifie qu'avec le secret de l'autre mode se refuse.

Webhooks : **les deux adresses sont en ligne et vérifiées le 21/11**. Un POST non signé sur
chacune renvoie `401 {"code":"signature_invalide"}`, ce qui est le bon comportement : la route
existe et elle refuse un appel non signé. Elles peuvent donc être déclarées dans GeniusPay.
Côté API la route est `/api/v1/paiements/webhook/{mode}`, `mode` valant `test` ou `reel`.

### Grille de frais, donnée par l'exploitant le 21/11

Reprise de Prepaxia, où elle tourne déjà en réel. Ces valeurs vont dans la table `parametres`,
jamais en dur, et alimentent l'écran admin des frais et le tableau de bord.

| Poste | Valeur |
|-------|--------|
| GeniusPay, encaissement | 100 XOF fixe + 1,0 % |
| Retrait | 1,0 % |
| Passerelle wave | 1,5 % |
| Passerelle orange_money | 3,5 % |
| Passerelle mtn_money | 3,5 % |
| Passerelle stripe | 5 % |
| Passerelle lien_tiers | 5 % |

Exemple à vérifier en recette, recharge de 500 XOF par Wave : passerelle 8 XOF, GeniusPay 105 XOF,
retrait 4 XOF, frais 117 XOF, net 383 XOF.

Arrondi, à trancher par la session API : sur Prepaxia le même exemple affiche 116 de frais et 384
de net, parce que le total est arrondi une seule fois (7,5 + 105 + 3,875 = 116,375) alors que
chaque ligne est arrondie à part. Résultat, les colonnes du tableau ne s'additionnent pas. Pour la
cantine : **arrondir chaque ligne à l'entier XOF, puis faire le total par somme des lignes
arrondies**, de sorte que ce qui est affiché s'additionne toujours.

Webhooks déclarés par l'exploitant le 21/11. Reste à faire une recharge de bout en bout en mode
test pour prouver la chaîne : si le solde se crédite, le webhook est bien reçu, signé et traité ;
s'il reste « en attente », regarder les journaux Railway (chercher `webhook`) et l'historique des
appels sortants dans le tableau de bord GeniusPay.

À reporter : les numéros de test par opérateur, s'ils en fournissent.

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

---

## 8. Clé web push FCM — fait

Sans cette clé, les notifications ne marchent pas sur la version web, même si tout le reste est
posé. Deux minutes.
1. Ouvrir `https://console.firebase.google.com/project/vatel-project/settings/cloudmessaging`.
2. Section **Configuration Web** → *Certificats web push* → **Générer une paire de clés**.
3. Copier la clé publique affichée (c'est une valeur publique, elle part dans le JavaScript).
4. La poser dans Railway sous `FCM_CLE_WEB_PUSH`, et me la recopier pour le fichier.

Valeurs récoltées :
- Clé publique web push :
  `BKQM2sJU-5EnYOfMuvBwCtuJjU3syQSDc8KEGyak6A4GxZpjSeSKr6ik2eSVOFhOIGYaM7eTDHbtDs1KJZn3K-g`
  Posée dans Railway sous `FCM_CLE_WEB_PUSH`. Valeur publique, elle part dans le JavaScript.

---

## 9. Compte développeur Google Play — à faire

Nécessaire seulement pour publier l'application dans le Play Store, pas pour l'installer en APK
ni pour la version web. 25 USD une seule fois, validation du compte de quelques heures à 48 h :
à lancer tôt si la publication est visée aujourd'hui.
1. `https://play.google.com/console/signup` avec le compte Google choisi pour la publication.
2. Type de compte : *Organisation* si la cantine a un numéro d'entreprise, sinon *Particulier*.
3. Payer les 25 USD, puis fournir les pièces d'identité demandées.
4. Me dire « compte Play créé » ou « compte Play en attente de validation ».

Valeurs récoltées :
- Compte Play utilisé : _(à remplir)_
- État de la validation : _(à remplir)_

---

## 10. Variables posées dans Railway le 21/11 — noms à respecter

Service Railway : **`api`** (et non « Projet-de-restauration-vatel »), projet HACKATON VATEL,
environnement production. Toutes posées en ligne de commande avec l'accord de l'exploitant.

| Variable | Nature |
|----------|--------|
| `GMAIL_CLIENT_ID` | publique |
| `GMAIL_CLIENT_SECRET` | secrète |
| `GMAIL_REFRESH_TOKEN` | secrète, expire dans 7 jours tant que l'écran de consentement reste en mode Test |
| `GMAIL_EXPEDITEUR` | `emmanudev2@gmail.com` |
| `GOOGLE_CLIENT_ID_WEB` | publique, audience du jeton et `serverClientId` Android |
| `GOOGLE_CLIENT_ID_ANDROID` | publique |
| `GOOGLE_CLIENT_ID_IOS` | publique |
| `APPLE_CLIENT_ID` | `com.vatel.cantine`, audience du jeton d'identité Apple |
| `APPLE_TEAM_ID` | `LD4W7KA5YG` |
| `FCM_CLE_WEB_PUSH` | publique |
| `GENIUSPAY_API_KEY`, `GENIUSPAY_SECRET_KEY`, `GENIUSPAY_WEBHOOK_SECRET` | mode test |
| `GENIUSPAY_LIVE_API_KEY`, `GENIUSPAY_LIVE_SECRET_KEY`, `GENIUSPAY_LIVE_WEBHOOK_SECRET` | mode réel |
| `FIREBASE_COMPTE_SERVICE`, `FIREBASE_PROJET_ID`, `FCM_ACTIF` | posées par la session API |

Pas encore posées, faute d'URL du site : `APPLE_SERVICES_ID`, `APPLE_KEY_ID`,
`APPLE_CLE_PRIVEE`. Elles ne servent qu'au bouton Apple **sur le web**. Dans l'application iOS,
le bouton Apple fonctionne avec `APPLE_CLIENT_ID` seul, l'API vérifiant le jeton d'identité
auprès des clés publiques d'Apple.

---

## 11. Codemagic, construction iOS vers TestFlight — en cours

Construit sur macOS dans le nuage, donc pas de Mac nécessaire. Exige le compte Apple payant,
confirmé.

Préalables Apple :
1. App ID `com.vatel.cantine` enregistré, avec Push Notifications et Sign in with Apple.
2. Fiche de l'application créée dans App Store Connect (`https://appstoreconnect.apple.com/apps`),
   sans quoi TestFlight refuse le téléversement.
3. Clé **App Store Connect API** (`https://appstoreconnect.apple.com/access/integrations/api`),
   accès **App Manager** au minimum. Relever l'Issuer ID et le Key ID, télécharger le `.p8` une
   seule fois, hors dépôt. Comme les clés APNs, elle vaut pour toute l'équipe : celle de Prepaxia
   est réutilisable.

Codemagic :
4. Inscription par GitHub, autoriser le dépôt, ajouter l'application en type **Flutter App**.
5. **Project path = `app/`**. Le projet Flutter est dans un sous-dossier ; sans ce réglage le
   build échoue en ne trouvant pas `pubspec.yaml`.
6. Integrations → Apple Developer Portal → Issuer ID, Key ID, `.p8`.
7. iOS code signing **Automatic**, bundle `com.vatel.cantine`, type App Store.
8. Publish → App Store Connect → TestFlight activé, soumission App Store décochée.
9. Déclencheur sur la branche **`ios/testflight`**, conformément à la convention du projet : on y
   pousse l'état de `main`, on n'y écrit jamais de code.

Pièges : numéro de build déjà utilisé (activer l'incrément automatique ou monter `version:` dans
`app/pubspec.yaml`) ; échec de signature presque toujours dû à une clé API en accès *Developer* au
lieu d'*App Manager* ; traitement TestFlight de 5 à 15 minutes après le téléversement ; question
de conformité export au premier build, à laquelle on répond non, l'application n'utilisant que du
HTTPS standard.

L'éditeur de workflow graphique suffit : aucun `codemagic.yaml` n'est nécessaire.

Valeurs récoltées :
- Issuer ID App Store Connect : _(à remplir)_
- Key ID de la clé Codemagic : _(à remplir)_
