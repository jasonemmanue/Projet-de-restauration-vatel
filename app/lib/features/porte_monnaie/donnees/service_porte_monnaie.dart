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

  /// Rend les mouvements connus, ou une liste vide.
  Future<List<Mouvement>> mouvements() async {
    if (_ref.read(sessionProvider).value == null) {
      return const <Mouvement>[];
    }
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.solde,
            chemin: '/porte-monnaie/mouvements',
          );
      final Object? brut = charge.donnees['elements'] ?? charge.donnees['mouvements'];
      if (brut is! List) {
        return const <Mouvement>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) => Mouvement.depuisJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      return const <Mouvement>[];
    }
  }
}

/// Le service du porte-monnaie.
final Provider<ServicePorteMonnaie> servicePorteMonnaieProvider =
    Provider<ServicePorteMonnaie>(ServicePorteMonnaie.new);

/// Un mouvement du porte-monnaie.
class Mouvement {
  /// Construit un mouvement.
  const Mouvement({
    required this.sens,
    required this.montantXof,
    required this.motif,
    required this.date,
  });

  /// Relit un mouvement rendu par l API.
  factory Mouvement.depuisJson(Map<String, dynamic> json) => Mouvement(
        sens: json['sens'] as String? ?? 'debit',
        montantXof: json['montant_xof'] as int? ?? 0,
        motif: json['motif'] as String? ?? '',
        date: DateTime.tryParse(json['cree_le'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );

  /// `credit` ou `debit`.
  final String sens;

  /// Montant en XOF, toujours positif.
  final int montantXof;

  /// Motif du mouvement.
  final String motif;

  /// Date du mouvement.
  final DateTime date;
}

/// Les mouvements du porte-monnaie, les plus récents d abord.
final FutureProvider<List<Mouvement>> mouvementsProvider =
    FutureProvider<List<Mouvement>>((Ref ref) => ref.watch(servicePorteMonnaieProvider).mouvements());

/// Le solde courant, ou rien s il n est pas connu.
final FutureProvider<int?> soldeProvider =
    FutureProvider<int?>((Ref ref) => ref.watch(servicePorteMonnaieProvider).solde());
