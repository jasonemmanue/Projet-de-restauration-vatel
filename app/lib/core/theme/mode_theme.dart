// Role du fichier : le mode d affichage choisi par l utilisateur, garde sur l appareil.
// Trois choix : systeme par defaut, clair ou sombre. Le changement s applique sans redemarrage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stockage/preferences.dart';

/// Tient le mode d affichage et l ecrit sur l appareil a chaque changement.
class ModeThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final SharedPreferences preferences = ref.watch(preferencesProvider);
    return _depuisTexte(preferences.getString(ClesPreference.modeTheme));
  }

  /// Change le mode d affichage et le garde pour les prochaines ouvertures.
  Future<void> choisir(ThemeMode mode) async {
    state = mode;
    final SharedPreferences preferences = ref.read(preferencesProvider);
    await preferences.setString(ClesPreference.modeTheme, mode.name);
  }

  static ThemeMode _depuisTexte(String? valeur) => switch (valeur) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

/// Le mode d affichage en cours.
final NotifierProvider<ModeThemeNotifier, ThemeMode> modeThemeProvider =
    NotifierProvider<ModeThemeNotifier, ThemeMode>(ModeThemeNotifier.new);

/// Tient la langue choisie, ou rien pour suivre le systeme.
class LangueNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final SharedPreferences preferences = ref.watch(preferencesProvider);
    final String? code = preferences.getString(ClesPreference.langue);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  /// Change la langue, ou revient au reglage du systeme avec une valeur vide.
  Future<void> choisir(Locale? langue) async {
    state = langue;
    final SharedPreferences preferences = ref.read(preferencesProvider);
    await preferences.setString(ClesPreference.langue, langue?.languageCode ?? '');
  }
}

/// La langue en cours, ou rien si l application suit le systeme.
final NotifierProvider<LangueNotifier, Locale?> langueProvider =
    NotifierProvider<LangueNotifier, Locale?>(LangueNotifier.new);
