// Role du fichier : les notifications, poussees et dans l application.
// Rien ne demarre sans Firebase : sans ses valeurs au build, l ecran marche quand meme,
// il ne recoit simplement pas de notification poussee.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/donnees/chargeur.dart';
import '../../../core/hors_ligne/cache_local.dart';
import '../../../core/outils/firebase_pret.dart';
import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';
import '../../../core/securite/session.dart';

/// Une notification recue dans l application.
class NotificationRecue {
  /// Construit une notification.
  const NotificationRecue({
    required this.id,
    required this.titre,
    required this.corps,
    required this.recueLe,
    this.lue = false,
  });

  /// Relit une notification rendue par l API.
  factory NotificationRecue.depuisJson(Map<String, dynamic> json) => NotificationRecue(
        id: json['id'] as String? ?? '',
        titre: json['titre'] as String? ?? '',
        corps: json['corps'] as String? ?? '',
        recueLe: DateTime.tryParse(json['cree_le'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        lue: json['lue_le'] != null,
      );

  /// Identifiant.
  final String id;

  /// Titre affiche.
  final String titre;

  /// Corps du message.
  final String corps;

  /// Date de reception.
  final DateTime recueLe;

  /// Vrai quand elle a deja ete ouverte.
  final bool lue;
}

/// Branche les notifications poussees et lit celles de l application.
class ServiceNotifications {
  /// Construit le service.
  const ServiceNotifications(this._ref);

  final Ref _ref;

  /// Demande l autorisation, recupere le jeton et le declare au serveur.
  Future<void> brancher() async {
    if (!_ref.read(firebasePretProvider) || _ref.read(sessionProvider).value == null) {
      return;
    }
    try {
      final FirebaseMessaging messagerie = FirebaseMessaging.instance;
      await messagerie.requestPermission();
      final String? jeton = kIsWeb
          ? await messagerie.getToken(
              vapidKey: const String.fromEnvironment('FIREBASE_CLE_WEB_PUSH'),
            )
          : await messagerie.getToken();
      if (jeton == null || jeton.isEmpty) {
        return;
      }
      await _ref.read(clientApiProvider).envoyer(
        '/appareils',
        corps: <String, dynamic>{
          'jeton_fcm': jeton,
          'plateforme': kIsWeb
              ? 'web'
              : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
          'modele': defaultTargetPlatform.name,
        },
      );
    } on Object {
      // Une notification qui ne se branche pas ne doit jamais empecher l application de servir.
      return;
    }
  }

  /// Rend les notifications de l utilisateur.
  Future<List<NotificationRecue>> liste() async {
    try {
      final ResultatCharge charge = await _ref.read(chargeurProvider).charger(
            sujet: SujetCache.notifications,
            chemin: '/notifications',
          );
      final Object? brut = charge.donnees['elements'] ?? charge.donnees['notifications'];
      if (brut is! List) {
        return const <NotificationRecue>[];
      }
      return brut
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> n) =>
              NotificationRecue.depuisJson(n.cast<String, dynamic>()))
          .toList(growable: false);
    } on ErreurApi {
      return const <NotificationRecue>[];
    }
  }

  /// Marque une notification comme lue.
  Future<void> marquerLue(String id) async {
    try {
      await _ref.read(clientApiProvider).envoyer('/notifications/$id/lue');
    } on ErreurApi {
      return;
    }
  }
}

/// Le service des notifications.
final Provider<ServiceNotifications> serviceNotificationsProvider =
    Provider<ServiceNotifications>(ServiceNotifications.new);

/// Les notifications de l utilisateur.
final FutureProvider<List<NotificationRecue>> notificationsProvider =
    FutureProvider<List<NotificationRecue>>(
  (Ref ref) => ref.watch(serviceNotificationsProvider).liste(),
);
