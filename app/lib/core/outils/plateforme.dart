// Role du fichier : savoir quels fournisseurs de connexion proposer, selon l appareil.
// Android, et le web ouvert sur Android, ne proposent que Google. Partout ailleurs, iPhone,
// iPad, et le web ouvert sur iPhone ou sur ordinateur, Google et Apple sont proposes tous les deux.

import 'package:flutter/foundation.dart';

/// Les fournisseurs de connexion possibles.
enum Fournisseur {
  /// Connexion avec un compte Google.
  google,

  /// Connexion avec un identifiant Apple.
  apple,
}

/// Decrit l appareil qui fait tourner l application.
class Plateforme {
  const Plateforme._();

  /// Vrai quand l application tourne dans un navigateur.
  static bool get estWeb => kIsWeb;

  /// Vrai sur Android, application installee ou application web.
  static bool get estAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Vrai sur iPhone et iPad, application installee ou application web.
  static bool get estApple =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  /// Vrai sur un ordinateur de bureau.
  static bool get estOrdinateur =>
      !estAndroid && (defaultTargetPlatform != TargetPlatform.iOS);

  /// Rend les fournisseurs a proposer sur cet appareil.
  static List<Fournisseur> get fournisseurs =>
      estAndroid ? <Fournisseur>[Fournisseur.google] : <Fournisseur>[Fournisseur.google, Fournisseur.apple];
}
