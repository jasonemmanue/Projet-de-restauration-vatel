// Role du fichier : charger le menu de la semaine.
// L API d abord, le cache de l appareil ensuite, et le jeu de démonstration en dernier recours
// tant que GET /menus/semaine n est pas en ligne.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/reseau/erreur_api.dart';
import '../../../core/securite/session.dart';
import 'jeu_demo.dart';
import 'modeles_menu.dart';

/// Charge les menus pour l application.
class ServiceMenus {
  /// Construit le service.
  const ServiceMenus(this._ref);

  final Ref _ref;

  /// Rend la semaine demandée, ou la semaine courante.
  Future<SemaineMenu> semaine({DateTime? du}) async {
    final DateTime debut = du ?? DateTime.now();
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.menu,
            chemin: '/menus/semaine',
            parametres: <String, dynamic>{
              'du': debut.toIso8601String().split('T').first,
            },
          );
      final SemaineMenu semaine = _depuisJson(charge);
      if (semaine.jours.isEmpty) {
        return _demo();
      }
      return semaine;
    } on ErreurApi {
      // Route absente tant que A4 n est pas livrée, ou réseau coupé sans cache :
      // on montre la semaine de démonstration plutôt qu un écran vide.
      return _demo();
    }
  }

  SemaineMenu _depuisJson(ResultatCharge charge) {
    final Object? brut = charge.donnees['jours'] ?? charge.donnees['elements'];
    final List<MenuDuJour> jours = brut is List
        ? brut
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> j) => MenuDuJour.depuisJson(j.cast<String, dynamic>()))
            .toList(growable: false)
        : const <MenuDuJour>[];
    return SemaineMenu(jours: jours, depuisCache: charge.depuisCache, majLe: charge.majLe);
  }

  SemaineMenu _demo() => semaineDemo(prixXof: prixDuProfil);

  /// Rend le prix du repas pour le profil du compte connecté.
  int get prixDuProfil {
    final Session? session = _ref.read(sessionProvider).value;
    final String profil = session?.statutConvive ?? 'eleve';
    return prixDemoParProfil[profil] ?? 1500;
  }
}

/// Le service des menus.
final Provider<ServiceMenus> serviceMenusProvider = Provider<ServiceMenus>(ServiceMenus.new);

/// La semaine en cours, chargée une fois par ouverture d onglet.
final FutureProvider<SemaineMenu> semaineProvider = FutureProvider<SemaineMenu>(
  (Ref ref) => ref.watch(serviceMenusProvider).semaine(),
);

/// Les allergènes déclarés par le convive, posés par F2c plus tard.
final Provider<List<String>> allergiesProvider = Provider<List<String>>((Ref ref) => const <String>[]);
