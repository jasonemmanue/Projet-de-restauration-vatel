// Role du fichier : charger un sujet depuis l API, le garder en cache, et retomber sur le cache
// quand le reseau manque. Deux ecrans qui demandent le meme sujet au meme moment ne declenchent
// qu un seul appel et recoivent la meme reponse.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hors_ligne/cache_local.dart';
import '../hors_ligne/etat_reseau.dart';
import '../outils/vol_unique.dart';
import '../reseau/client_api.dart';
import '../reseau/erreur_api.dart';

/// Le resultat d un chargement : le contenu, et s il vient du cache.
class ResultatCharge {
  /// Construit un resultat de chargement.
  const ResultatCharge({required this.donnees, required this.majLe, required this.depuisCache});

  /// Le contenu a afficher.
  final Map<String, dynamic> donnees;

  /// L heure de la derniere mise a jour reussie.
  final DateTime majLe;

  /// Vrai quand le contenu vient de l appareil et non du reseau.
  final bool depuisCache;
}

/// Charge les sujets de l application, avec cache et vol unique.
class Chargeur {
  /// Construit le chargeur.
  Chargeur(this._ref);

  final Ref _ref;
  final VolUnique _vols = VolUnique();

  /// Charge un sujet. Sans reseau, rend la derniere version connue si elle existe.
  Future<ResultatCharge> charger({
    required SujetCache sujet,
    required String chemin,
    Map<String, dynamic>? parametres,
  }) {
    return _vols.executer<ResultatCharge>(sujet.name, () async {
      final CacheLocal cache = _ref.read(cacheLocalProvider);
      try {
        final Map<String, dynamic> donnees =
            await _ref.read(clientApiProvider).lire(chemin, parametres: parametres);
        await cache.ecrire(sujet, donnees);
        return ResultatCharge(
          donnees: donnees,
          majLe: DateTime.now(),
          depuisCache: false,
        );
      } on ErreurApi catch (echec) {
        if (!echec.estReseau) {
          rethrow;
        }
        _ref.read(etatReseauProvider.notifier).signalerEchecReseau();
        final DonneesCachees? garde = cache.lire(sujet);
        if (garde == null) {
          rethrow;
        }
        return ResultatCharge(
          donnees: garde.donnees,
          majLe: garde.majLe,
          depuisCache: true,
        );
      }
    });
  }

  /// Rend tout de suite la derniere version connue, sans appeler le reseau.
  ResultatCharge? versionGardee(SujetCache sujet) {
    final DonneesCachees? garde = _ref.read(cacheLocalProvider).lire(sujet);
    if (garde == null) {
      return null;
    }
    return ResultatCharge(donnees: garde.donnees, majLe: garde.majLe, depuisCache: true);
  }
}

/// Le chargeur de sujets de l application.
final Provider<Chargeur> chargeurProvider = Provider<Chargeur>(Chargeur.new);
