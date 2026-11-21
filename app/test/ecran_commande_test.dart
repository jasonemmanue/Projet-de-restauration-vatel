// Role du fichier : vérifier la commande, réussie et refusée.
// Le service réseau est remplacé : ces tests portent sur l écran, pas sur l API.

import 'package:cantine_vatel/core/reseau/erreur_api.dart';
import 'package:cantine_vatel/core/stockage/preferences.dart';
import 'package:cantine_vatel/core/theme/theme.dart';
import 'package:cantine_vatel/features/menus/donnees/jeu_demo.dart';
import 'package:cantine_vatel/features/menus/donnees/modeles_menu.dart';
import 'package:cantine_vatel/features/menus/donnees/service_menus.dart';
import 'package:cantine_vatel/features/porte_monnaie/donnees/service_porte_monnaie.dart';
import 'package:cantine_vatel/features/reservations/donnees/service_commandes.dart';
import 'package:cantine_vatel/features/reservations/ecran_commande.dart';
import 'package:cantine_vatel/l10n/traductions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ServiceFaux extends ServiceCommandes {
  const _ServiceFaux(super.ref, {this.echec});

  final ErreurApi? echec;

  @override
  Future<Map<String, dynamic>> commander({
    required Portee portee,
    required DateTime debut,
    required List<ChoixJour> jours,
    String? preuvePin,
  }) async {
    final ErreurApi? refus = echec;
    if (refus != null) {
      throw refus;
    }
    return <String, dynamic>{'id': 'lot-test'};
  }
}

Future<Widget> _application({required int solde, ErreurApi? echec}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      semaineProvider.overrideWith((Ref ref) async => semaineDemo(prixXof: 1500)),
      soldeProvider.overrideWith((Ref ref) async => solde),
      serviceCommandesProvider.overrideWith((Ref ref) => _ServiceFaux(ref, echec: echec)),
    ],
    child: MaterialApp(
      theme: construireTheme(sombre: false),
      locale: const Locale('fr'),
      localizationsDelegates: Traductions.localizationsDelegates,
      supportedLocales: Traductions.supportedLocales,
      home: const EcranCommande(),
    ),
  );
}

String _premierPlat() {
  final SemaineMenu semaine = semaineDemo();
  return semaine.jours.first.plats.first.nom;
}

/// Déclenche le bouton de confirmation. Il doit être actif : sinon le test échoue ici.
Future<void> _confirmer(WidgetTester testeur) async {
  final FilledButton bouton = testeur.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Confirmer la commande'),
  );
  expect(bouton.onPressed, isNotNull);
  bouton.onPressed!();
  await testeur.pumpAndSettle();
}

void main() {
  testWidgets('Une commande acceptee est annoncee', (WidgetTester testeur) async {
    await testeur.pumpWidget(await _application(solde: 5000));
    await testeur.pumpAndSettle();

    await testeur.tap(find.text(_premierPlat()));
    await testeur.pumpAndSettle();
    await _confirmer(testeur);

    expect(find.text('Commande enregistrée'), findsOneWidget);
  });

  testWidgets('Un refus de l API est montre tel quel', (WidgetTester testeur) async {
    await testeur.pumpWidget(
      await _application(
        solde: 5000,
        echec: const ErreurApi(
          code: 'solde_insuffisant',
          message: 'Le solde ne couvre pas ce repas.',
        ),
      ),
    );
    await testeur.pumpAndSettle();

    await testeur.tap(find.text(_premierPlat()));
    await testeur.pumpAndSettle();
    await _confirmer(testeur);

    expect(find.text('Le solde ne couvre pas ce repas.'), findsOneWidget);
  });
}
