// Role du fichier : l application elle meme, thème, langue et routeur.
// La taille de texte de base suit le type d ecran, et respecte le reglage d accessibilite
// du telephone dans des bornes raisonnables.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/responsive/type_ecran.dart';
import 'core/routes/routes.dart';
import 'core/theme/mode_theme.dart';
import 'core/theme/theme.dart';
import 'l10n/traductions.dart';
import 'shared/widgets/porte_ouverture.dart';

/// L application Cantine Vatel.
class Application extends ConsumerWidget {
  /// Construit l application.
  const Application({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final ThemeMode mode = ref.watch(modeThemeProvider);
    final Locale? langue = ref.watch(langueProvider);

    return MaterialApp.router(
      title: 'Cantine Vatel',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routeurProvider),
      theme: construireTheme(sombre: false),
      darkTheme: construireTheme(sombre: true),
      themeMode: mode,
      locale: langue,
      localizationsDelegates: Traductions.localizationsDelegates,
      supportedLocales: Traductions.supportedLocales,
      builder: (BuildContext contexte, Widget? enfant) {
        final MediaQueryData donnees = MediaQuery.of(contexte);
        final TypeEcran type = TypeEcran.selonLargeur(donnees.size.width);
        // Le texte grandit un peu sur tablette et sur ordinateur, comme le dit la charte.
        final double facteurEcran = switch (type) {
          TypeEcran.telephone => 1,
          TypeEcran.tablette => 15 / 14,
          TypeEcran.ordinateur => 16 / 14,
        };
        final double reglageSysteme = (donnees.textScaler.scale(14) / 14)
            .clamp(Mesures.echelleTexteMin, Mesures.echelleTexteMax);
        return MediaQuery(
          data: donnees.copyWith(
            textScaler: TextScaler.linear(reglageSysteme * facteurEcran),
          ),
          child: PorteOuverture(enfant: enfant ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
