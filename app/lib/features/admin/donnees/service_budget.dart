// Role du fichier : le cahier de caisse de la cantine, entrées et sorties.
// Les paiements et leurs frais s inscrivent tout seuls côté serveur ; l admin ajoute le reste.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';

/// Une ligne du budget.
class LigneBudget {
  /// Construit une ligne.
  const LigneBudget({
    required this.id,
    required this.date,
    required this.sens,
    required this.montantXof,
    required this.categorie,
    required this.libelle,
    this.automatique = false,
  });

  /// Relit une ligne rendue par l API.
  factory LigneBudget.depuisJson(Map<String, dynamic> json) => LigneBudget(
        id: json['id'] as String? ?? '',
        date: DateTime.parse(json['date_operation'] as String),
        sens: json['sens'] as String? ?? 'sortie',
        montantXof: json['montant_xof'] as int? ?? 0,
        categorie: json['categorie'] as String? ?? 'autre',
        libelle: json['libelle'] as String? ?? '',
        automatique: (json['origine'] as String? ?? 'manuelle') == 'automatique',
      );

  /// Identifiant de la ligne.
  final String id;

  /// Jour de l'opération.
  final DateTime date;

  /// `entree` ou `sortie`.
  final String sens;

  /// Montant en XOF, toujours positif.
  final int montantXof;

  /// Catégorie de l'opération.
  final String categorie;

  /// Ce que c'est, en clair.
  final String libelle;

  /// Vrai quand la ligne vient d un paiement ou d un frais, donc non modifiable.
  final bool automatique;
}

/// Les chiffres du budget sur une période.
class ResumeBudget {
  /// Construit un résumé.
  const ResumeBudget({
    required this.soldeGlobalXof,
    required this.entreesXof,
    required this.sortiesXof,
    required this.soldeMoisXof,
    required this.entreesMoisXof,
    required this.sortiesMoisXof,
    required this.lignes,
    required this.parMois,
    required this.sortiesParCategorie,
  });

  /// Relit le résumé rendu par l API.
  factory ResumeBudget.depuisJson(Map<String, dynamic> json) => ResumeBudget(
        soldeGlobalXof: json['solde_global_xof'] as int? ?? 0,
        entreesXof: json['entrees_xof'] as int? ?? 0,
        sortiesXof: json['sorties_xof'] as int? ?? 0,
        soldeMoisXof: json['solde_mois_xof'] as int? ?? 0,
        entreesMoisXof: json['entrees_mois_xof'] as int? ?? 0,
        sortiesMoisXof: json['sorties_mois_xof'] as int? ?? 0,
        lignes: (json['lignes'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> l) => LigneBudget.depuisJson(l.cast<String, dynamic>()))
            .toList(growable: false),
        parMois: (json['par_mois'] as List<dynamic>? ?? <dynamic>[])
            .map((Object? e) => e is num ? e.toInt() : 0)
            .toList(growable: false),
        sortiesParCategorie: (json['sorties_par_categorie'] as Map<dynamic, dynamic>? ??
                <dynamic, dynamic>{})
            .map((Object? cle, Object? valeur) =>
                MapEntry<String, int>('$cle', valeur is num ? valeur.toInt() : 0)),
      );

  /// Solde depuis le début.
  final int soldeGlobalXof;

  /// Total des entrées de la période.
  final int entreesXof;

  /// Total des sorties de la période.
  final int sortiesXof;

  /// Solde du mois en cours.
  final int soldeMoisXof;

  /// Entrées du mois en cours.
  final int entreesMoisXof;

  /// Sorties du mois en cours.
  final int sortiesMoisXof;

  /// Les lignes de la période.
  final List<LigneBudget> lignes;

  /// Le solde mois par mois, pour la courbe.
  final List<int> parMois;

  /// Les sorties réparties par catégorie.
  final Map<String, int> sortiesParCategorie;

  /// Vrai quand l API n a encore rien à dire.
  bool get estVide => lignes.isEmpty && soldeGlobalXof == 0;

  /// Un résumé vide, montré tant que la route n existe pas.
  static const ResumeBudget vide = ResumeBudget(
    soldeGlobalXof: 0,
    entreesXof: 0,
    sortiesXof: 0,
    soldeMoisXof: 0,
    entreesMoisXof: 0,
    sortiesMoisXof: 0,
    lignes: <LigneBudget>[],
    parMois: <int>[],
    sortiesParCategorie: <String, int>{},
  );
}

/// Lit et écrit le budget.
class ServiceBudget {
  /// Construit le service.
  const ServiceBudget(this._ref);

  final Ref _ref;

  /// Rend les chiffres du budget.
  Future<ResumeBudget> resume() async {
    try {
      final Map<String, dynamic> reponse =
          await _ref.read(clientApiProvider).lire('/admin/budget');
      return ResumeBudget.depuisJson(reponse);
    } on ErreurApi {
      return ResumeBudget.vide;
    }
  }

  /// Rend le calendrier d un mois : une case par jour.
  Future<Map<int, int>> calendrier(DateTime mois) async {
    try {
      final Map<String, dynamic> reponse = await _ref.read(clientApiProvider).lire(
        '/admin/budget/calendrier',
        parametres: <String, dynamic>{
          'mois': '${mois.year}-${mois.month.toString().padLeft(2, '0')}',
        },
      );
      final Object? jours = reponse['jours'];
      if (jours is! List) {
        return <int, int>{};
      }
      final Map<int, int> parJour = <int, int>{};
      for (final Object? jour in jours) {
        if (jour is Map) {
          final int numero = jour['jour'] as int? ?? 0;
          parJour[numero] = jour['solde_xof'] as int? ?? 0;
        }
      }
      return parJour;
    } on ErreurApi {
      return <int, int>{};
    }
  }

  /// Ajoute une ligne saisie à la main.
  Future<void> ajouter({
    required DateTime date,
    required String sens,
    required int montantXof,
    required String categorie,
    required String libelle,
  }) async {
    await _ref.read(clientApiProvider).envoyer(
      '/admin/budget',
      corps: <String, dynamic>{
        'date_operation': date.toIso8601String().split('T').first,
        'sens': sens,
        'montant_xof': montantXof,
        'categorie': categorie,
        'libelle': libelle,
      },
    );
  }
}

/// Le service du budget.
final Provider<ServiceBudget> serviceBudgetProvider = Provider<ServiceBudget>(ServiceBudget.new);

/// Les chiffres du budget.
final FutureProvider<ResumeBudget> budgetProvider =
    FutureProvider<ResumeBudget>((Ref ref) => ref.watch(serviceBudgetProvider).resume());

/// Le calendrier du mois en cours.
final FutureProvider<Map<int, int>> calendrierBudgetProvider =
    FutureProvider<Map<int, int>>((Ref ref) => ref.watch(serviceBudgetProvider).calendrier(DateTime.now()));
