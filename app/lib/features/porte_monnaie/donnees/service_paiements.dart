// Role du fichier : recharger le porte-monnaie et faire payer par un proche.
// L application n encaisse rien : elle ouvre la page de GeniusPay et revient demander au
// serveur ce qui s est passe. Le solde ne bouge que quand le serveur le dit.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reseau/cle_demande.dart';
import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';

/// Les operateurs Mobile Money acceptes.
enum Operateur {
  /// Orange Money.
  orange,

  /// MTN Mobile Money.
  mtn,

  /// Moov Money.
  moov,

  /// Wave.
  wave;

  /// Nom affiche.
  String get libelle => switch (this) {
        Operateur.orange => 'Orange Money',
        Operateur.mtn => 'MTN Money',
        Operateur.moov => 'Moov Money',
        Operateur.wave => 'Wave',
      };
}

/// Ce que l API rend quand une recharge est lancee.
class RechargeLancee {
  /// Construit le resultat d une recharge lancee.
  const RechargeLancee({required this.paiementId, required this.urlRedirection, required this.mode});

  /// Relit la reponse de l API.
  factory RechargeLancee.depuisJson(Map<String, dynamic> json) => RechargeLancee(
        paiementId: json['paiement_id'] as String? ?? json['id'] as String? ?? '',
        urlRedirection: json['url_redirection'] as String? ?? '',
        mode: json['mode'] as String? ?? 'test',
      );

  /// Identifiant du paiement, a redemander au retour.
  final String paiementId;

  /// Page de paiement a ouvrir.
  final String urlRedirection;

  /// `test` ou `reel`.
  final String mode;

  /// Vrai quand la cantine est encore en mode test.
  bool get estTest => mode == 'test';
}

/// Un lien de paiement, a envoyer a un proche.
class LienPaiement {
  /// Construit un lien.
  const LienPaiement({required this.id, required this.url, required this.montantXof});

  /// Relit la reponse de l API.
  factory LienPaiement.depuisJson(Map<String, dynamic> json) => LienPaiement(
        id: json['id'] as String? ?? '',
        url: json['url_publique'] as String? ?? '',
        montantXof: json['montant_xof'] as int? ?? 0,
      );

  /// Identifiant du lien.
  final String id;

  /// Adresse publique a partager.
  final String url;

  /// Montant demande, zero si libre.
  final int montantXof;
}

/// Lance les recharges et les liens de paiement.
class ServicePaiements {
  /// Construit le service.
  const ServicePaiements(this._ref);

  final Ref _ref;

  /// Lance une recharge et rend la page a ouvrir.
  Future<RechargeLancee> recharger({
    required int montantXof,
    required Operateur operateur,
    required String telephonePayeur,
    String? beneficiaireId,
  }) async {
    final Map<String, dynamic> reponse = await _ref.read(clientApiProvider).envoyer(
      '/paiements/recharge',
      cleGeste: CleDemande.nouvelle(),
      corps: <String, dynamic>{
        'montant_xof': montantXof,
        'operateur': operateur.name,
        'telephone_payeur': telephonePayeur,
        'beneficiaire_id': ?beneficiaireId,
      },
    );
    return RechargeLancee.depuisJson(reponse);
  }

  /// Redemande au serveur ou en est un paiement.
  Future<String> etatPaiement(String paiementId) async {
    try {
      final Map<String, dynamic> reponse =
          await _ref.read(clientApiProvider).lire('/paiements/$paiementId');
      return reponse['etat'] as String? ?? 'en_attente';
    } on ErreurApi {
      return 'inconnu';
    }
  }

  /// Cree un lien de paiement a envoyer a un proche.
  Future<LienPaiement> creerLien({
    required int montantXof,
    required String message,
    String? beneficiaireId,
  }) async {
    final Map<String, dynamic> reponse = await _ref.read(clientApiProvider).envoyer(
      '/liens-paiement',
      cleGeste: CleDemande.nouvelle(),
      corps: <String, dynamic>{
        'montant_xof': montantXof,
        'message': message,
        'beneficiaire_id': ?beneficiaireId,
        'expire_dans_heures': 48,
      },
    );
    return LienPaiement.depuisJson(reponse);
  }
}

/// Le service des paiements.
final Provider<ServicePaiements> servicePaiementsProvider =
    Provider<ServicePaiements>(ServicePaiements.new);
