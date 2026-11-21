// Role du fichier : verifier que l application demarre et montre l ecran de bienvenue.

import 'package:cantine_vatel/app.dart';
import 'package:cantine_vatel/core/stockage/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('L application demarre sur l ecran de bienvenue', (WidgetTester testeur) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await testeur.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const Application(),
      ),
    );
    await testeur.pump(const Duration(seconds: 1));

    expect(find.text('Cantine Vatel'), findsWidgets);
  });
}
