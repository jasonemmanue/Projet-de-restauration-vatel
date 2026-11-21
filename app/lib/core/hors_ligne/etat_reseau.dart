// Role du fichier : savoir si l application peut vraiment parler a l API.
// Hors ligne reel = pas de reseau OU API injoignable. Le controle dure 4 secondes au plus et
// son resultat vaut 10 secondes. Le minuteur de 20 secondes ne tourne qu en etat hors ligne,
// le temps de detecter le retour : en marche normale, aucun appel reseau periodique.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../outils/vol_unique.dart';
import '../reseau/client_api.dart';
import 'file_envoi.dart';

/// Tient l etat du reseau et declenche l envoi de la file au retour.
class EtatReseauNotifier extends Notifier<bool> {
  final VolUnique _vols = VolUnique();
  DateTime? _dernierControle;
  bool _dernierResultat = true;
  Timer? _minuteur;
  AppLifecycleListener? _cycleDeVie;

  @override
  bool build() {
    _cycleDeVie = AppLifecycleListener(
      // Au retour au premier plan, on recontrole tout de suite.
      onResume: () => unawaited(verifier(force: true)),
    );
    ref.onDispose(() {
      _minuteur?.cancel();
      _cycleDeVie?.dispose();
    });
    return true;
  }

  /// Controle que l API repond. Le resultat precedent vaut 10 secondes.
  Future<bool> verifier({bool force = false}) async {
    final DateTime? dernier = _dernierControle;
    if (!force && dernier != null && DateTime.now().difference(dernier).inSeconds < 10) {
      return _dernierResultat;
    }
    final bool joignable = await _vols.executer<bool>(
      'sante',
      () => ref.read(clientApiProvider).sante(),
    );
    _dernierControle = DateTime.now();
    _dernierResultat = joignable;
    _appliquer(joignable);
    return joignable;
  }

  /// Signale un echec reseau constate par une requete, sans relancer de controle.
  void signalerEchecReseau() {
    _dernierControle = DateTime.now();
    _dernierResultat = false;
    _appliquer(false);
  }

  void _appliquer(bool enLigne) {
    final bool etaitHorsLigne = !state;
    state = enLigne;
    if (enLigne) {
      _minuteur?.cancel();
      _minuteur = null;
      if (etaitHorsLigne) {
        // Retour du reseau : la file part toute seule, une action a la fois.
        unawaited(ref.read(fileEnvoiProvider.notifier).vider());
      }
      return;
    }
    _minuteur ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(verifier(force: true)),
    );
  }
}

/// Vrai tant que l API est joignable.
final NotifierProvider<EtatReseauNotifier, bool> etatReseauProvider =
    NotifierProvider<EtatReseauNotifier, bool>(EtatReseauNotifier.new);
