// Role du fichier : acces unique aux preferences locales, posees au demarrage de l application.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les preferences locales, remplacees au demarrage par l instance reelle.
final Provider<SharedPreferences> preferencesProvider = Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError(
    'preferencesProvider doit etre remplace au demarrage de l application.',
  ),
);

/// Les cles de preference connues de l application.
class ClesPreference {
  const ClesPreference._();

  /// Mode d affichage choisi : systeme, clair ou sombre.
  static const String modeTheme = 'mode_theme';

  /// Langue choisie : fr, en, ou vide pour suivre le systeme.
  static const String langue = 'langue';

  /// Prefixe des caches de donnees, un par sujet.
  static const String prefixeCache = 'cache_';

  /// File des actions faites hors ligne.
  static const String fileEnvoi = 'file_envoi';
}
