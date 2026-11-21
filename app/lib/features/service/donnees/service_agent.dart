// Role du fichier : le service de l agent au comptoir.
// La liste du jour est téléchargée puis gardée : hors ligne, le scan est jugé dessus et part
// dans la file d envoi avec sa clé unique. Au retour du réseau, la file se vide toute seule.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/hors_ligne/etat_reseau.dart';
import '../../../core/hors_ligne/file_envoi.dart';
import '../../../core/reseau/cle_demande.dart';
import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';

/// Ce qu un scan peut donner.
enum ResultatScan {
  /// Ticket valable, repas servi.
  accepte,

  /// Ce ticket a déjà été scanné.
  dejaServi,

  /// Aucun ticket ne porte ce code.
  inconnu,

  /// Le ticket existe mais pour un autre jour.
  mauvaisJour,

  /// La commande a été annulée ou supprimée.
  annulee;

  /// Vrai quand le convive peut être servi.
  bool get estVert => this == ResultatScan.accepte;
}

/// Une entrée de la liste du service.
class TicketDuJour {
  /// Construit une entrée.
  const TicketDuJour({
    required this.code,
    required this.convive,
    required this.plats,
    required this.etat,
  });

  /// Relit une entrée rendue par l API.
  factory TicketDuJour.depuisJson(Map<String, dynamic> json) => TicketDuJour(
        code: json['code_ticket'] as String? ?? '',
        convive: json['convive'] as String? ?? '',
        plats: (json['plats'] as List<dynamic>? ?? <dynamic>[])
            .map((Object? p) => p is Map ? '${p['nom']}' : '$p')
            .toList(growable: false),
        etat: json['etat'] as String? ?? 'confirmee',
      );

  /// Contenu du QR.
  final String code;

  /// Nom du convive.
  final String convive;

  /// Ce qu il a commandé.
  final List<String> plats;

  /// État de la commande.
  final String etat;
}

/// Le service du comptoir.
class ServiceAgent {
  /// Construit le service.
  ServiceAgent(this._ref);

  final Ref _ref;

  /// Les codes déjà servis depuis l ouverture de l écran, pour juger hors ligne.
  final Set<String> _dejaServis = <String>{};

  /// Rend la liste du jour, du réseau ou du cache.
  Future<List<TicketDuJour>> listeDuJour() async {
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.serviceAgent,
            chemin: '/agent/service/jour',
          );
      final Object? brut = charge.donnees['elements'] ?? charge.donnees['tickets'];
      if (brut is! List) {
        return const <TicketDuJour>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> t) => TicketDuJour.depuisJson(t.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      return const <TicketDuJour>[];
    }
  }

  /// Juge un code sur la liste déjà téléchargée, sans réseau.
  ResultatScan jugerLocalement(String code, List<TicketDuJour> liste) {
    if (_dejaServis.contains(code)) {
      return ResultatScan.dejaServi;
    }
    final TicketDuJour? trouve =
        liste.where((TicketDuJour ticket) => ticket.code == code).firstOrNull;
    if (trouve == null) {
      return ResultatScan.inconnu;
    }
    if (trouve.etat == 'servie') {
      return ResultatScan.dejaServi;
    }
    if (trouve.etat == 'annulee' || trouve.etat == 'supprimee') {
      return ResultatScan.annulee;
    }
    return ResultatScan.accepte;
  }

  /// Scanne un ticket. En ligne, le serveur tranche. Hors ligne, la liste tranche et le scan part en file.
  Future<ResultatScan> scanner(String code, List<TicketDuJour> liste) async {
    final String cleUnique = CleDemande.nouvelle();
    final bool enLigne = _ref.read(etatReseauProvider);

    if (enLigne) {
      try {
        final Map<String, dynamic> reponse = await _ref.read(clientApiProvider).envoyer(
          '/agent/scan',
          cleGeste: cleUnique,
          corps: <String, dynamic>{
            'code_ticket': code,
            'scanne_le': DateTime.now().toUtc().toIso8601String(),
          },
        );
        final ResultatScan resultat = _depuisTexte(reponse['resultat'] as String?);
        if (resultat.estVert) {
          _dejaServis.add(code);
        }
        return resultat;
      } on ErreurApi catch (echec) {
        if (!echec.estReseau) {
          return _depuisCode(echec.code);
        }
        // Le réseau a lâché en cours de route : on bascule sur le jugement local.
      }
    }

    final ResultatScan local = jugerLocalement(code, liste);
    if (local.estVert) {
      _dejaServis.add(code);
      await _ref.read(fileEnvoiProvider.notifier).ajouter(
            ActionEnAttente(
              cleUnique: cleUnique,
              type: TypeAction.scan,
              chemin: '/agent/scan',
              corps: <String, dynamic>{
                'code_ticket': code,
                'scanne_le': DateTime.now().toUtc().toIso8601String(),
              },
              faiteLe: DateTime.now(),
            ),
          );
    }
    return local;
  }

  ResultatScan _depuisTexte(String? valeur) => switch (valeur) {
        'accepte' => ResultatScan.accepte,
        'deja_servi' => ResultatScan.dejaServi,
        'mauvais_jour' => ResultatScan.mauvaisJour,
        'annule' => ResultatScan.annulee,
        _ => ResultatScan.inconnu,
      };

  ResultatScan _depuisCode(String code) => switch (code) {
        'deja_servi' => ResultatScan.dejaServi,
        'mauvais_jour' => ResultatScan.mauvaisJour,
        'reservation_annulee' => ResultatScan.annulee,
        _ => ResultatScan.inconnu,
      };
}

/// Le service du comptoir.
final Provider<ServiceAgent> serviceAgentProvider = Provider<ServiceAgent>(ServiceAgent.new);

/// La liste du service du jour.
final FutureProvider<List<TicketDuJour>> listeDuJourProvider =
    FutureProvider<List<TicketDuJour>>((Ref ref) => ref.watch(serviceAgentProvider).listeDuJour());
