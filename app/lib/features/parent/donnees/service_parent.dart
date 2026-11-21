// Role du fichier : la famille du parent. Enfants lies, leurs repas, leur solde, leur seuil.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';

/// Un enfant lie au parent.
class Enfant {
  /// Construit un enfant.
  const Enfant({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.soldeXof,
    this.statut = 'eleve',
    this.repasDuJour = '',
    this.seuilAlerteXof,
  });

  /// Relit un enfant rendu par l API.
  factory Enfant.depuisJson(Map<String, dynamic> json) => Enfant(
        id: json['id'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        soldeXof: json['solde_xof'] as int? ?? 0,
        statut: json['statut_convive'] as String? ?? 'eleve',
        repasDuJour: json['repas_du_jour'] as String? ?? '',
        seuilAlerteXof: json['seuil_alerte_solde'] as int?,
      );

  /// Identifiant de l enfant.
  final String id;

  /// Prenom.
  final String prenom;

  /// Nom.
  final String nom;

  /// Solde de son porte-monnaie.
  final int soldeXof;

  /// Profil tarifaire.
  final String statut;

  /// Ce qu il mange aujourd hui, en clair.
  final String repasDuJour;

  /// Seuil a partir duquel le parent est prevenu.
  final int? seuilAlerteXof;

  /// Vrai quand le solde est sous le seuil pose par le parent.
  bool get soldeBas => seuilAlerteXof != null && soldeXof <= seuilAlerteXof!;
}

/// Lit et change la famille du parent.
class ServiceParent {
  /// Construit le service.
  const ServiceParent(this._ref);

  final Ref _ref;

  /// Rend les enfants lies.
  Future<List<Enfant>> enfants() async {
    try {
      final Map<String, dynamic> reponse =
          await _ref.read(clientApiProvider).lire('/parent/enfants');
      final Object? brut = reponse['elements'] ?? reponse['enfants'];
      if (brut is! List) {
        return const <Enfant>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) => Enfant.depuisJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      return const <Enfant>[];
    }
  }

  /// Lie un enfant a partir de son code.
  Future<void> lier(String codeLiaison) async {
    await _ref.read(clientApiProvider).envoyer(
      '/parent/liaison',
      corps: <String, dynamic>{'code_liaison': codeLiaison.trim().toUpperCase()},
    );
  }

  /// Pose le seuil d alerte de solde bas d un enfant.
  Future<void> poserSeuil(String enfantId, int seuilXof) async {
    await _ref.read(clientApiProvider).envoyer(
      '/parent/enfants/$enfantId/seuil',
      corps: <String, dynamic>{'seuil_alerte_solde': seuilXof},
    );
  }
}

/// Le service de la famille.
final Provider<ServiceParent> serviceParentProvider = Provider<ServiceParent>(ServiceParent.new);

/// Les enfants lies au parent connecte.
final FutureProvider<List<Enfant>> enfantsProvider =
    FutureProvider<List<Enfant>>((Ref ref) => ref.watch(serviceParentProvider).enfants());
