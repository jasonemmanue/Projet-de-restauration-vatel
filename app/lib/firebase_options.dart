// Role du fichier : les identifiants publics des applications Firebase du projet vatel-project.
// Ce ne sont pas des secrets : ils voyagent deja dans chaque application livree, et l acces est
// tenu par les regles de securite Firebase, pas par ces valeurs.
// Produit depuis android/app/google-services.json et ios/Runner/GoogleService-Info.plist.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Les options Firebase de chaque plateforme.
class OptionsFirebase {
  const OptionsFirebase._();

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

    static const FirebaseOptions android = FirebaseOptions(
      apiKey: 'AIzaSyDZGuuV4lpWn_mnLTE069OaYswTaVuQ4dg',
      appId: '1:814642268084:android:5311e2edc6b39eed5a14e1',
      messagingSenderId: '814642268084',
      projectId: 'vatel-project',
      storageBucket: 'vatel-project.firebasestorage.app',
    );

    static const FirebaseOptions ios = FirebaseOptions(
      apiKey: 'AIzaSyCwenWaBNXZ6TmHrpztN53bq_2UPa8qJXU',
      appId: '1:814642268084:ios:ae9fe8822c2740a15a14e1',
      messagingSenderId: '814642268084',
      projectId: 'vatel-project',
      storageBucket: 'vatel-project.firebasestorage.app',
      iosBundleId: 'com.vatel.cantine',
    );

    static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyBR6WTZTftsxaIxuQXIpi2m1LdrrVFnTRc',
      appId: '1:814642268084:web:da3c853f2c2e63075a14e1',
      messagingSenderId: '814642268084',
      projectId: 'vatel-project',
      authDomain: 'vatel-project.firebaseapp.com',
      storageBucket: 'vatel-project.firebasestorage.app',
      measurementId: 'G-L92CPFLT2Q',
    );
}
