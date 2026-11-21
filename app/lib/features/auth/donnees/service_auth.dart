// Role du fichier : les appels d authentification, calques sur le contrat de l API deployee.
// Aucun ecran n appelle le client reseau directement : tout passe par ce service.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reseau/client_api.dart';
import '../../../core/securite/session.dart';

/// Le canal par lequel un identifiant est vérifié.
enum CanalIdentifiant {
  /// Numéro de téléphone, code à 6 chiffres.
  telephone,

  /// Adresse e-mail, code de 5 caractères.
  email;

  /// Nombre de cases du code pour ce canal.
  int get longueurCode => this == CanalIdentifiant.telephone ? 6 : 5;

  /// Nom attendu par l API.
  String get pourApi => name;
}

/// Ce que l API rend après une demande de code.
class CodeEnvoye {
  /// Construit la réponse d un envoi de code.
  const CodeEnvoye({required this.modeLivraison, required this.expireLe, this.codeDemo});

  /// Relit la réponse de l API.
  factory CodeEnvoye.depuisJson(Map<String, dynamic> json) => CodeEnvoye(
        modeLivraison: json['mode_livraison'] as String? ?? 'demo',
        expireLe: DateTime.tryParse(json['expire_le'] as String? ?? '')?.toLocal(),
        codeDemo: json['code_demo'] as String?,
      );

  /// `demo` ou `reel`.
  final String modeLivraison;

  /// Fin de validité du code.
  final DateTime? expireLe;

  /// Le code en clair, seulement en mode démo.
  final String? codeDemo;

  /// Vrai quand l API a rendu le code, donc que l écran peut le remplir seul.
  bool get estDemo => modeLivraison == 'demo' && (codeDemo ?? '').isNotEmpty;
}

/// Ce que l API rend après une inscription.
class ResultatInscription {
  /// Construit le résultat d une inscription.
  const ResultatInscription({required this.etat, required this.canal, this.session});

  /// `a_verifier` tant que l identifiant n est pas confirmé.
  final String etat;

  /// Canal à vérifier, `telephone` ou `email`.
  final String canal;

  /// La session, quand l API en ouvre une tout de suite.
  final Session? session;

  /// Vrai quand l écran du code doit s ouvrir.
  bool get aVerifier => etat == 'a_verifier';
}

/// Les appels d authentification de l application.
class ServiceAuth {
  /// Construit le service au dessus du client réseau.
  const ServiceAuth(this._ref);

  final Ref _ref;

  ClientApi get _client => _ref.read(clientApiProvider);

  Map<String, dynamic> get _appareil => <String, dynamic>{
        'nom': kIsWeb ? 'Navigateur' : defaultTargetPlatform.name,
        'plateforme': kIsWeb
            ? 'web'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
      };

  /// Crée un compte. L API rend `a_verifier` tant que l identifiant n est pas confirmé.
  Future<ResultatInscription> inscrire({
    required CanalIdentifiant canal,
    required String identifiant,
    required String motDePasse,
    required String prenom,
    required String nom,
    required String role,
    String? statutConvive,
  }) async {
    final Map<String, dynamic> reponse = await _client.envoyer(
      '/auth/inscription',
      corps: <String, dynamic>{
        'type': canal.pourApi,
        'identifiant': identifiant,
        'mot_de_passe': motDePasse,
        'prenom': prenom,
        'nom': nom,
        'role': role,
        'statut_convive': ?statutConvive,
        'conditions_acceptees': true,
        'appareil': _appareil,
      },
    );
    return ResultatInscription(
      etat: reponse['etat'] as String? ?? 'a_verifier',
      canal: reponse['canal'] as String? ?? canal.pourApi,
      session: _sessionDepuis(reponse),
    );
  }

  /// Ouvre une session avec un identifiant et un mot de passe.
  Future<Session?> connecter({required String identifiant, required String motDePasse}) async {
    final Map<String, dynamic> reponse = await _client.envoyer(
      '/auth/connexion',
      corps: <String, dynamic>{
        'identifiant': identifiant,
        'mot_de_passe': motDePasse,
        'appareil': _appareil,
      },
    );
    return _sessionDepuis(reponse);
  }

  /// Demande l envoi d un code de vérification.
  Future<CodeEnvoye> envoyerCode({
    required String identifiant,
    required CanalIdentifiant canal,
    String usage = 'verification_compte',
  }) async {
    final Map<String, dynamic> reponse = await _client.envoyer(
      '/auth/verification/envoyer',
      corps: <String, dynamic>{
        'identifiant': identifiant,
        'canal': canal.pourApi,
        'usage': usage,
      },
    );
    return CodeEnvoye.depuisJson(reponse);
  }

  /// Confirme un code reçu. Rend la session quand l API en ouvre une.
  Future<Session?> confirmerCode({
    required String identifiant,
    required CanalIdentifiant canal,
    required String code,
    String usage = 'verification_compte',
  }) async {
    final Map<String, dynamic> reponse = await _client.envoyer(
      '/auth/verification/confirmer',
      corps: <String, dynamic>{
        'identifiant': identifiant,
        'canal': canal.pourApi,
        'code': code,
        'usage': usage,
      },
    );
    return _sessionDepuis(reponse);
  }

  /// Demande un code de réinitialisation du mot de passe.
  Future<CodeEnvoye> motDePasseOublie({
    required String identifiant,
    required CanalIdentifiant canal,
  }) async {
    final Map<String, dynamic> reponse = await _client.envoyer(
      '/auth/mot-de-passe/oublie',
      corps: <String, dynamic>{'identifiant': identifiant, 'canal': canal.pourApi},
    );
    return CodeEnvoye.depuisJson(reponse);
  }

  /// Pose un nouveau mot de passe avec le code reçu.
  Future<void> reinitialiserMotDePasse({
    required String identifiant,
    required CanalIdentifiant canal,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    await _client.envoyer(
      '/auth/mot-de-passe/reinitialiser',
      corps: <String, dynamic>{
        'identifiant': identifiant,
        'canal': canal.pourApi,
        'code': code,
        'nouveau_mot_de_passe': nouveauMotDePasse,
      },
    );
  }

  /// Ferme la session côté serveur, puis côté appareil.
  Future<void> deconnecter() async {
    final Session? ouverte = _ref.read(sessionProvider).value;
    if (ouverte != null && ouverte.jetonRafraichissement.isNotEmpty) {
      try {
        await _client.envoyer(
          '/auth/deconnexion',
          corps: <String, dynamic>{'jeton_rafraichissement': ouverte.jetonRafraichissement},
        );
      } on Object {
        // Le serveur n a pas pu être prévenu : la session locale part quand même.
      }
    }
    await _ref.read(sessionProvider.notifier).fermer();
  }

  Session? _sessionDepuis(Map<String, dynamic> reponse) {
    final String jeton = reponse['jeton'] as String? ?? '';
    if (jeton.isEmpty) {
      return null;
    }
    final Object? brut = reponse['utilisateur'];
    final Map<String, dynamic> utilisateur =
        brut is Map ? brut.cast<String, dynamic>() : <String, dynamic>{};
    return Session(
      jetonAcces: jeton,
      jetonRafraichissement: reponse['jeton_rafraichissement'] as String? ?? '',
      role: Role.depuisTexte(utilisateur['role'] as String?),
      utilisateurId: utilisateur['id'] as String? ?? reponse['utilisateur_id'] as String? ?? '',
      nomComplet: utilisateur['nom_complet'] as String? ?? '',
      statutConvive: utilisateur['statut_convive'] as String?,
    );
  }
}

/// Le service d authentification de l application.
final Provider<ServiceAuth> serviceAuthProvider = Provider<ServiceAuth>(ServiceAuth.new);
