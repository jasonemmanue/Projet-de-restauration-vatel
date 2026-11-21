// Role du fichier : demarrer l application.
// Affichage bord a bord des le premier ecran, preferences locales chargees avant le premier rendu,
// Firebase demarre si sa configuration est la.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/outils/firebase_pret.dart';
import 'core/stockage/preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bord a bord : le contenu passe sous les barres systeme, qui restent transparentes.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
    ),
  );

  final SharedPreferences preferences = await SharedPreferences.getInstance();

  // Sans valeurs passees au build, on ne tente meme pas : le depot ne porte aucune cle.
  bool firebaseDemarre = OptionsFirebase.configurees;
  if (firebaseDemarre) {
    try {
      await Firebase.initializeApp(options: OptionsFirebase.courante);
    } on Object {
      // L application doit demarrer meme sans Firebase : les notifications attendront.
      firebaseDemarre = false;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        firebasePretProvider.overrideWithValue(firebaseDemarre),
      ],
      child: const Application(),
    ),
  );
}
