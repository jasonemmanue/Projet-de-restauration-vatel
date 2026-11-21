# Jalon de 12h30 : l'application complète, en ligne

Ce qui est montrable au jury à 12h30, où ça se trouve, et comment le vérifier en deux minutes.

## Où c'est

| Brique | Adresse |
| --- | --- |
| API | `https://projet-de-restauration-vatel-production.up.railway.app` |
| Santé de l'API | `https://projet-de-restauration-vatel-production.up.railway.app/health` |
| Application web | `https://vatel-project.web.app` |
| APK Android | Release GitHub du dépôt, fichier `cantine-vatel.apk` |
| Dépôt | `https://github.com/jasonemmanue/Projet-de-restauration-vatel` |

## Les sept fonctionnalités minimum

| # | Exigence du jury | Où | Comment la vérifier |
| --- | --- | --- | --- |
| 1 | Inscription par numéro ou e-mail | Écran de bienvenue, bouton « Continuer avec mon numéro ou mon e-mail » | Créer un compte par numéro : bascule Numéro, 10 chiffres après +225, prénom, nom, profil, mot de passe, conditions |
| 2 | Vérification de l'identifiant | Écran du code, ouvert tout seul après l'inscription | 6 cases pour un numéro, 5 pour un e-mail. En mode démo, elles se remplissent seules et la pastille le dit |
| 3 | Connexion | Écran de connexion | Se déconnecter depuis l'onglet Compte, puis se reconnecter |
| 4 | Menu de la semaine | Onglet Menu | Choisir un jour dans la bande du haut : les plats apparaissent par service, avec le prix du jour |
| 5 | Réservation d'un repas | Onglet Menu, bouton Commander | Choisir la portée, cocher un plat par service, vérifier le total et le solde après, confirmer |
| 6 | Solde et historique | Onglet Compte, puis Porte-monnaie | Le solde et la liste des mouvements |
| 7 | Back office : menus, commandes du jour, tableau de bord | Espace admin, onglets Menus, Cuisine, Tableau de bord | Créer le menu de demain, y poser des plats, publier. Les commandes du jour et les chiffres sont en face |

## Ce qui est vrai et ce qui ne l'est pas

À dire au jury sans détour, c'est plus solide que de laisser découvrir :

- L'API est en ligne et porte les comptes, la vérification par code et la connexion. Le reste de ses routes
  arrive dans la journée.
- Les écrans du menu, de la commande et du back office tournent sur un jeu de démonstration tant que les
  routes correspondantes ne sont pas livrées. Ils basculent seuls dès qu'elles répondent, sans changer une
  ligne d'écran.
- Le solde affiche un tiret plutôt qu'un zéro : aucun chiffre inventé n'est montré.
- Les paiements sont en mode test. Les trois taux de frais GeniusPay sont à zéro tant que le contrat
  marchand n'est pas renseigné, donc le net affiché vaut le brut.

## Les commandes à lancer, depuis le dossier du dépôt

Publier l'application web :

```powershell
cd "C:\Users\hp\StudioProjects\CANTINE VATEL\app"
flutter build web --release --dart-define=API_URL=https://projet-de-restauration-vatel-production.up.railway.app/api/v1 --dart-define-from-file=firebase.defines
cd ..
firebase deploy --only hosting --project vatel-project
```

Pousser l'état de `main` sur les branches de construction, qui ne portent jamais de code à elles :

```powershell
git push origin main:web --force
```

```powershell
git push origin main:android/apk --force
```

Construire l'APK :

```powershell
cd "C:\Users\hp\StudioProjects\CANTINE VATEL\app"
flutter build apk --release --dart-define=API_URL=https://projet-de-restauration-vatel-production.up.railway.app/api/v1 --dart-define-from-file=firebase.defines
```

Le fichier sort dans `app\build\app\outputs\flutter-apk\app-release.apk`. Pour la Release GitHub, ouvrir
`https://github.com/jasonemmanue/Projet-de-restauration-vatel/releases/new`, marquer le tag `jalon-12h30`,
glisser l'APK, publier.
