// Role du fichier : les chiffres du back office, commandes du jour et tableau de bord.
// L API d abord. Tant que A8 n a pas livré ses routes, les écrans montrent un état vide
// plutôt qu un chiffre inventé : un tableau de bord faux est pire que pas de tableau de bord.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';

/// Ce qu il faut préparer pour un plat, un jour donné.
class LigneCuisine {
  /// Construit une ligne de cuisine.
  const LigneCuisine({
    required this.plat,
    required this.service,
    required this.parts,
    this.servies = 0,
  });

  /// Relit une ligne rendue par l API.
  factory LigneCuisine.depuisJson(Map<String, dynamic> json) => LigneCuisine(
        plat: json['plat'] as String? ?? json['nom'] as String? ?? '',
        service: json['service'] as String? ?? '',
        parts: json['parts'] as int? ?? 0,
        servies: json['servies'] as int? ?? 0,
      );

  /// Nom du plat.
  final String plat;

  /// Service auquel il appartient.
  final String service;

  /// Nombre de parts commandées.
  final int parts;

  /// Nombre de parts déjà servies.
  final int servies;
}

/// Les chiffres du tableau de bord.
class ChiffresBord {
  /// Construit les chiffres.
  const ChiffresBord({
    required this.repasServis,
    required this.nonReclames,
    required this.recettesBrutesXof,
    required this.fraisXof,
    required this.netXof,
    required this.parJour,
    required this.platsFavoris,
  });

  /// Relit les chiffres rendus par l API.
  factory ChiffresBord.depuisJson(Map<String, dynamic> json) => ChiffresBord(
        repasServis: json['repas_servis'] as int? ?? 0,
        nonReclames: json['non_reclames'] as int? ?? 0,
        recettesBrutesXof: json['recettes_brutes_xof'] as int? ?? 0,
        fraisXof: json['frais_xof'] as int? ?? 0,
        netXof: json['net_xof'] as int? ?? 0,
        parJour: (json['par_jour'] as List<dynamic>? ?? <dynamic>[])
            .map((Object? e) => e is num ? e.toInt() : 0)
            .toList(growable: false),
        platsFavoris: (json['plats_favoris'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> p) => LigneCuisine.depuisJson(p.cast<String, dynamic>()))
            .toList(growable: false),
      );

  /// Repas servis sur la période.
  final int repasServis;

  /// Repas commandés mais jamais retirés.
  final int nonReclames;

  /// Recettes encaissées, avant frais.
  final int recettesBrutesXof;

  /// Frais GeniusPay supportés par la cantine.
  final int fraisXof;

  /// Net attendu après retrait.
  final int netXof;

  /// Repas servis, jour par jour, sur sept jours.
  final List<int> parJour;

  /// Les plats les plus commandés.
  final List<LigneCuisine> platsFavoris;

  /// Vrai quand l API n a encore rien à dire.
  bool get estVide => repasServis == 0 && recettesBrutesXof == 0 && parJour.isEmpty;
}

/// Lit les chiffres du back office.
class ServiceBord {
  /// Construit le service.
  const ServiceBord(this._ref);

  final Ref _ref;

  /// Rend ce qu il faut préparer aujourd hui.
  Future<List<LigneCuisine>> commandesDuJour({DateTime? date}) async {
    final DateTime jour = date ?? DateTime.now();
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.serviceAgent,
            chemin: '/admin/commandes-jour',
            parametres: <String, dynamic>{'date': jour.toIso8601String().split('T').first},
          );
      final Object? brut = charge.donnees['lignes'] ?? charge.donnees['elements'];
      if (brut is! List) {
        return const <LigneCuisine>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> l) => LigneCuisine.depuisJson(l.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      return const <LigneCuisine>[];
    }
  }

  /// Rend les chiffres de la période, sept derniers jours par défaut.
  Future<ChiffresBord> tableauBord() async {
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.tableauBord,
            chemin: '/admin/tableau-bord',
          );
      return ChiffresBord.depuisJson(charge.donnees);
    } on ErreurApi {
      return const ChiffresBord(
        repasServis: 0,
        nonReclames: 0,
        recettesBrutesXof: 0,
        fraisXof: 0,
        netXof: 0,
        parJour: <int>[],
        platsFavoris: <LigneCuisine>[],
      );
    }
  }

  /// Ajuste le solde d un convive. Le mot de passe des actions est exigé par le serveur.
  Future<void> ajusterSolde({
    required String utilisateurId,
    required String sens,
    required int montantXof,
    required String motif,
    required String motDePasseActions,
  }) async {
    await _ref.read(clientApiProvider).envoyer(
          '/admin/utilisateurs/$utilisateurId/ajustement',
          corps: <String, dynamic>{
            'sens': sens,
            'montant_xof': montantXof,
            'motif': motif,
            'mot_de_passe_actions': motDePasseActions,
          },
        );
  }
}

/// Le service des chiffres du back office.
final Provider<ServiceBord> serviceBordProvider = Provider<ServiceBord>(ServiceBord.new);

/// Les commandes du jour.
final FutureProvider<List<LigneCuisine>> commandesDuJourProvider =
    FutureProvider<List<LigneCuisine>>((Ref ref) => ref.watch(serviceBordProvider).commandesDuJour());

/// Les chiffres du tableau de bord.
final FutureProvider<ChiffresBord> chiffresBordProvider =
    FutureProvider<ChiffresBord>((Ref ref) => ref.watch(serviceBordProvider).tableauBord());
