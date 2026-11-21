// Role du fichier : lire le solde du porte-monnaie.
// Tant que A5 n a pas livré la route, le solde reste inconnu et l accueil montre un tiret :
// jamais un faux chiffre, jamais un zéro inventé.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/reseau/erreur_api.dart';
import '../../../core/securite/session.dart';

/// Lit le porte-monnaie du compte connecté.
class ServicePorteMonnaie {
  /// Construit le service.
  const ServicePorteMonnaie(this._ref);

  final Ref _ref;

  /// Rend le solde en XOF, ou rien quand il n est pas connu.
  Future<int?> solde() async {
    if (_ref.read(sessionProvider).value == null) {
      return null;
    }
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.solde,
            chemin: '/porte-monnaie',
          );
      final Object? valeur = charge.donnees['solde_xof'];
      return valeur is int ? valeur : null;
    } on ErreurApi {
      // Route absente ou réseau coupé sans cache : on ne devine pas un solde.
      return null;
    }
  }
}

/// Le service du porte-monnaie.
final Provider<ServicePorteMonnaie> servicePorteMonnaieProvider =
    Provider<ServicePorteMonnaie>(ServicePorteMonnaie.new);

/// Le solde courant, ou rien s il n est pas connu.
final FutureProvider<int?> soldeProvider =
    FutureProvider<int?>((Ref ref) => ref.watch(servicePorteMonnaieProvider).solde());
