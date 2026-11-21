// Role du fichier : plein ecran sur Android et iPhone, par le mode immersif du systeme.

import 'package:flutter/services.dart';

/// Entre et sort du plein ecran sur un appareil.
class PleinEcran {
  const PleinEcran._();

  static bool _actif = false;

  /// Vrai quand l application est en plein ecran.
  static bool get actif => _actif;

  /// Passe en plein ecran immersif.
  static Future<void> entrer() async {
    _actif = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Revient a l affichage bord a bord habituel.
  static Future<void> quitter() async {
    _actif = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Entre ou sort, selon l etat courant.
  static Future<void> basculer() => _actif ? quitter() : entrer();
}
