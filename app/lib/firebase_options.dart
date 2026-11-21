// Role du fichier : les identifiants des applications Firebase du projet vatel-project.
// Le depot est public : aucune valeur n est ecrite ici. Tout arrive par --dart-define au build,
// depuis app/firebase.defines, qui n est pas versionne. Sans ces valeurs, l application tourne
// normalement : seules les notifications poussees manquent.
//
// Pour construire avec Firebase :
//   flutter run --dart-define-from-file=firebase.defines --dart-define=API_URL=...
// Pour reconstruire le fichier de valeurs : python outils/options_firebase.py

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Les options Firebase de chaque plateforme, lues a la compilation.
class OptionsFirebase {
  const OptionsFirebase._();

  /// Identifiant du projet Firebase, commun aux trois plateformes.
  static const String projet = String.fromEnvironment('FIREBASE_PROJET');

  /// Numero du projet, qui sert aussi d expediteur de notifications.
  static const String expediteur = String.fromEnvironment('FIREBASE_EXPEDITEUR');

  /// Depot de fichiers du projet.
  static const String stockage = String.fromEnvironment('FIREBASE_STOCKAGE');

  /// Vrai quand les valeurs ont ete passees au build.
  static bool get configurees => projet.isNotEmpty && expediteur.isNotEmpty;

  /// Rend les options de la plateforme courante.
  static FirebaseOptions get courante {
    if (kIsWeb) {
      return web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ => web,
    };
  }

  /// Options de l application Android.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_CLE_ANDROID'),
    appId: String.fromEnvironment('FIREBASE_APP_ANDROID'),
    messagingSenderId: expediteur,
    projectId: projet,
    storageBucket: stockage,
  );

  /// Options de l application iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_CLE_IOS'),
    appId: String.fromEnvironment('FIREBASE_APP_IOS'),
    messagingSenderId: expediteur,
    projectId: projet,
    storageBucket: stockage,
    iosBundleId: String.fromEnvironment('FIREBASE_BUNDLE_IOS'),
  );

  /// Options de l application web.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_CLE_WEB'),
    appId: String.fromEnvironment('FIREBASE_APP_WEB'),
    messagingSenderId: expediteur,
    projectId: projet,
    authDomain: String.fromEnvironment('FIREBASE_DOMAINE_AUTH'),
    storageBucket: stockage,
    measurementId: String.fromEnvironment('FIREBASE_MESURE_WEB'),
  );
}
