// Role du fichier : vérifier l écran du code dans ses deux modes.
// En mode démo, l API renvoie le code et les cases doivent être remplies seules.
// En mode réel, les cases restent vides et le rappel des indésirables s affiche.

import 'package:cantine_vatel/core/stockage/preferences.dart';
import 'package:cantine_vatel/core/theme/theme.dart';
import 'package:cantine_vatel/features/auth/donnees/service_auth.dart';
import 'package:cantine_vatel/features/auth/ecran_code.dart';
import 'package:cantine_vatel/l10n/traductions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _application(ArgumentsCode arguments) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(preferences)],
    child: MaterialApp(
      theme: construireTheme(sombre: false),
      locale: const Locale('fr'),
      localizationsDelegates: Traductions.localizationsDelegates,
      supportedLocales: Traductions.supportedLocales,
      home: EcranCode(arguments: arguments),
    ),
  );
}

void main() {
  testWidgets('En mode demo, les cases sont remplies seules', (WidgetTester testeur) async {
    await testeur.pumpWidget(
      await _application(
        const ArgumentsCode(
          identifiant: '+2250700000000',
          canal: CanalIdentifiant.telephone,
          premierEnvoi: CodeEnvoye(modeLivraison: 'demo', expireLe: null, codeDemo: '123456'),
        ),
      ),
    );
    await testeur.pump();

    for (final String chiffre in <String>['1', '2', '3', '4', '5', '6']) {
      expect(find.text(chiffre), findsOneWidget);
    }
    expect(find.text('Mode démo : code rempli automatiquement'), findsOneWidget);

    // On démonte l écran pour que son compte à rebours ne survive pas au test.
    await testeur.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('En mode reel, les cases restent vides', (WidgetTester testeur) async {
    await testeur.pumpWidget(
      await _application(
        const ArgumentsCode(
          identifiant: 'convive@vatel.ci',
          canal: CanalIdentifiant.email,
          premierEnvoi: CodeEnvoye(modeLivraison: 'reel', expireLe: null),
        ),
      ),
    );
    await testeur.pump();

    final Iterable<TextField> cases = testeur.widgetList<TextField>(find.byType(TextField));
    expect(cases.length, 5);
    for (final TextField uneCase in cases) {
      expect(uneCase.controller?.text ?? '', isEmpty);
    }
    expect(find.textContaining('indésirables'), findsOneWidget);

    await testeur.pumpWidget(const SizedBox.shrink());
  });
}
