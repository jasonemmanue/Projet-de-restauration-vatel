# Application Flutter de Cantine Vatel

Android, iOS et web, back office compris. Identifiant `com.vatel.cantine`, nom affiché « Cantine Vatel ».

## Lancer

```bash
flutter pub get
flutter run --dart-define=API_URL=https://<URL_API>/api/v1
```

Sans `--dart-define`, l'application vise `http://localhost:8000/api/v1`.

## Contrôles

```bash
flutter analyze    # doit finir sur « No issues found »
flutter test
flutter build web --dart-define=API_URL=https://<URL_API>/api/v1
```

## Firebase

Projet `vatel-project` (compte `emmanudev2@gmail.com`). Les trois applications sont déjà créées :

| Plateforme | App ID |
| --- | --- |
| Android | `1:814642268084:android:5311e2edc6b39eed5a14e1` |
| iOS | `1:814642268084:ios:ae9fe8822c2740a15a14e1` |
| Web | `1:814642268084:web:da3c853f2c2e63075a14e1` |

Aucune clé n'est versionnée : le dépôt est public, et GitHub signale toute clé Google qui y entre.
`lib/firebase_options.dart` ne contient que des `String.fromEnvironment` ; les valeurs vivent dans
`app/firebase.defines`, qui est ignoré par git. Sur une autre machine :

```bash
firebase login:use emmanudev2@gmail.com
firebase apps:sdkconfig ANDROID 1:814642268084:android:5311e2edc6b39eed5a14e1 --project vatel-project --out android/app/google-services.json
firebase apps:sdkconfig IOS 1:814642268084:ios:ae9fe8822c2740a15a14e1 --project vatel-project --out ios/Runner/GoogleService-Info.plist
python outils/options_firebase.py   # fabrique firebase.defines
firebase apps:sdkconfig WEB 1:814642268084:web:da3c853f2c2e63075a14e1 --project vatel-project
# recopier les trois valeurs web dans firebase.defines
```

Puis construire avec les valeurs :

```bash
flutter run --dart-define-from-file=firebase.defines --dart-define=API_URL=https://<URL_API>/api/v1
```

Firebase ne démarre que si les valeurs ont été passées au build, et son échec n'empêche jamais l'application
de tourner : sans lui, seules les notifications poussées manquent.

## Marque

Les icônes, les écrans de lancement et les logos des boutons viennent de `docs/marque/exports/`, copiés dans
`assets/marque/`. Les regénérer :

```bash
python ../docs/marque/outils/svg_marque.py   # les SVG
node outils/marque.mjs                       # tous les PNG
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Règles propres à l'application

- Toute couleur passe par le thème (`lib/core/theme`), jamais écrite dans un écran.
- Tout texte affiché passe par `lib/l10n/app_fr.arb` et `app_en.arb`, puis `flutter gen-l10n`.
- Aucun texte coupé : `TexteAdapte` réduit un texte d'une ligne au lieu de l'abréger. `TextOverflow.ellipsis`
  est interdit.
- Les boutons Google, Apple et code QR passent par `BoutonFournisseur` : le logo vit dans une boîte carrée de
  22 px en ajustement par contenu, il ne se déforme jamais.
- Les fournisseurs proposés suivent l'appareil (`lib/core/outils/plateforme.dart`) : Android ne voit que
  Google, iPhone, iPad et ordinateur voient Google et Apple. Le code QR est proposé partout.
- Aucune action d'argent hors ligne. Les scans et les appréciations faits hors ligne passent par la file
  d'envoi (`lib/core/hors_ligne/file_envoi.dart`).
