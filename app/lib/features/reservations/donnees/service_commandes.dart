// Role du fichier : commander des repas et relire ses commandes.
// Le serveur décide de tout : prix, solde, gel, refus. L application n annonce que ce qu il a dit.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/reseau/cle_demande.dart';
import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';
import '../../menus/donnees/modeles_menu.dart';

/// Les portées de commande proposées par le serveur.
enum Portee {
  /// Un seul jour.
  jour,

  /// La semaine entière.
  semaine,

  /// Le mois entier.
  mois;

  /// Nom attendu par l API.
  String get pourApi => name;
}

/// Un plat choisi, avec sa quantité.
class ChoixPlat {
  /// Construit un choix.
  const ChoixPlat({required this.plat, this.quantite = 1});

  /// Le plat retenu.
  final Plat plat;

  /// Nombre de parts.
  final int quantite;

  /// Rend le corps attendu par l API.
  Map<String, dynamic> versJson() => <String, dynamic>{
        'plat_id': plat.id,
        'quantite': quantite,
      };
}

/// Les plats choisis pour un jour.
class ChoixJour {
  /// Construit le choix d un jour.
  const ChoixJour({required this.date, required this.plats});

  /// Jour de service.
  final DateTime date;

  /// Les plats retenus ce jour-là.
  final List<ChoixPlat> plats;

  /// Rend le corps attendu par l API.
  Map<String, dynamic> versJson() => <String, dynamic>{
        'date_service': date.toIso8601String().split('T').first,
        'plats': plats.map((ChoixPlat c) => c.versJson()).toList(growable: false),
      };
}

/// Ce que l application montre avant de confirmer.
class Recapitulatif {
  /// Construit un récapitulatif.
  const Recapitulatif({
    required this.jours,
    required this.totalXof,
    required this.soldeAvant,
    required this.soldeApres,
  });

  /// Nombre de jours commandés.
  final int jours;

  /// Total à débiter, menus et suppléments compris.
  final int totalXof;

  /// Solde connu avant la commande, ou rien.
  final int? soldeAvant;

  /// Solde attendu après, ou rien quand le solde est inconnu.
  final int? soldeApres;

  /// Vrai quand le solde connu ne couvre pas la commande.
  bool get soldeInsuffisant => soldeApres != null && soldeApres! < 0;
}

/// Une commande déjà passée.
class Commande {
  /// Construit une commande.
  const Commande({
    required this.id,
    required this.date,
    required this.totalXof,
    required this.etat,
    required this.codeTicket,
    this.plats = const <String>[],
    this.gelee = false,
  });

  /// Relit une commande rendue par l API.
  factory Commande.depuisJson(Map<String, dynamic> json) => Commande(
        id: json['id'] as String? ?? '',
        date: DateTime.parse(json['date_service'] as String),
        totalXof: json['total_xof'] as int? ?? 0,
        etat: json['etat'] as String? ?? 'confirmee',
        codeTicket: json['code_ticket'] as String? ?? '',
        plats: (json['plats'] as List<dynamic>? ?? <dynamic>[])
            .map((Object? p) => p is Map ? '${p['nom']}' : '$p')
            .toList(growable: false),
        gelee: json['gelee'] as bool? ?? false,
      );

  /// Identifiant de la commande.
  final String id;

  /// Jour de service.
  final DateTime date;

  /// Montant débité.
  final int totalXof;

  /// `confirmee`, `servie`, `annulee`, `supprimee` ou `non_reclamee`.
  final String etat;

  /// Contenu du QR.
  final String codeTicket;

  /// Noms des plats commandés.
  final List<String> plats;

  /// Vrai quand la veille du service est passée : plus de modification.
  final bool gelee;

  /// Vrai quand le jour de service n est pas encore passé.
  bool get aVenir => !date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
}

/// Commande des repas et relit les commandes du convive.
class ServiceCommandes {
  /// Construit le service.
  const ServiceCommandes(this._ref);

  final Ref _ref;

  /// Envoie la commande. Rend le lot créé, ou lève l erreur de l API telle quelle.
  Future<Map<String, dynamic>> commander({
    required Portee portee,
    required DateTime debut,
    required List<ChoixJour> jours,
    String? preuvePin,
  }) {
    return _ref.read(clientApiProvider).envoyer(
          '/reservations',
          cleGeste: CleDemande.nouvelle(),
          preuvePin: preuvePin,
          corps: <String, dynamic>{
            'portee': portee.pourApi,
            'debut': debut.toIso8601String().split('T').first,
            'jours': jours.map((ChoixJour j) => j.versJson()).toList(growable: false),
          },
        );
  }

  /// Rend les commandes du convive, les plus proches d abord.
  Future<List<Commande>> mesCommandes() async {
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.ticket,
            chemin: '/reservations',
          );
      final Object? brut = charge.donnees['elements'] ?? charge.donnees['reservations'];
      if (brut is! List) {
        return const <Commande>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> c) => Commande.depuisJson(c.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      // Route absente tant que A5 n est pas livrée : on ne montre rien plutôt qu une erreur.
      return const <Commande>[];
    }
  }

  /// Annule un jour. Après le gel, le serveur supprime sans rembourser.
  Future<Map<String, dynamic>> annuler(String commandeId) {
    return _ref.read(clientApiProvider).envoyer(
          '/reservations/$commandeId/annuler',
          cleGeste: CleDemande.nouvelle(),
        );
  }
}

/// Le service des commandes.
final Provider<ServiceCommandes> serviceCommandesProvider =
    Provider<ServiceCommandes>(ServiceCommandes.new);

/// Les commandes du convive.
final FutureProvider<List<Commande>> mesCommandesProvider =
    FutureProvider<List<Commande>>((Ref ref) => ref.watch(serviceCommandesProvider).mesCommandes());
