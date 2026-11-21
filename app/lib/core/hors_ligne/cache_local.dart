// Role du fichier : garder sur l appareil la derniere version de chaque sujet, avec son heure.
// Tout ce qui a ete charge reste lisible sans reseau, sur Android, iPhone et web.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stockage/preferences.dart';

/// Les sujets gardes en cache, un par ecran qui doit rester lisible hors ligne.
enum SujetCache {
  /// Menu de la semaine.
  menu,

  /// Ticket QR du jour.
  ticket,

  /// Solde et derniers mouvements.
  solde,

  /// Profil et preferences.
  profil,

  /// Notifications recues.
  notifications,

  /// Liste du service de l agent.
  serviceAgent,

  /// Dernier tableau de bord charge.
  tableauBord,
}

/// Un contenu garde sur l appareil, avec l heure de sa derniere mise a jour.
class DonneesCachees {
  /// Construit un contenu cache.
  const DonneesCachees({required this.donnees, required this.majLe});

  /// Le contenu rendu par l API lors du dernier chargement reussi.
  final Map<String, dynamic> donnees;

  /// L heure a laquelle ce contenu a ete charge.
  final DateTime majLe;
}

/// Ecrit et relit les contenus gardes sur l appareil.
class CacheLocal {
  /// Construit le cache au dessus des preferences locales.
  const CacheLocal(this._preferences);

  final SharedPreferences _preferences;

  String _cle(SujetCache sujet) => '${ClesPreference.prefixeCache}${sujet.name}';

  /// Garde le contenu d un sujet avec l heure courante.
  Future<void> ecrire(SujetCache sujet, Map<String, dynamic> donnees) async {
    final String brut = jsonEncode(<String, dynamic>{
      'maj_le': DateTime.now().toUtc().toIso8601String(),
      'donnees': donnees,
    });
    await _preferences.setString(_cle(sujet), brut);
  }

  /// Rend le dernier contenu connu d un sujet, ou rien s il n y en a jamais eu.
  DonneesCachees? lire(SujetCache sujet) {
    final String? brut = _preferences.getString(_cle(sujet));
    if (brut == null || brut.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> enveloppe = jsonDecode(brut) as Map<String, dynamic>;
      return DonneesCachees(
        donnees: (enveloppe['donnees'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
        majLe: DateTime.parse(enveloppe['maj_le'] as String).toLocal(),
      );
    } on Object {
      // Un cache illisible n est pas une erreur : on fait comme s il etait vide.
      return null;
    }
  }

  /// Efface tous les sujets, par exemple a la deconnexion.
  Future<void> toutEffacer() async {
    for (final SujetCache sujet in SujetCache.values) {
      await _preferences.remove(_cle(sujet));
    }
  }
}

/// Le cache local de l application.
final Provider<CacheLocal> cacheLocalProvider =
    Provider<CacheLocal>((Ref ref) => CacheLocal(ref.watch(preferencesProvider)));
