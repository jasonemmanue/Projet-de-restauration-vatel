// Role du fichier : la seule forme d erreur que l application manipule.
// L API repond toujours {"code": "...", "message": "..."} : le message est montre tel quel,
// jamais le texte brut d une exception.

import 'package:dio/dio.dart';

/// Une erreur venue de l API, ou du reseau quand l API est injoignable.
class ErreurApi implements Exception {
  /// Construit une erreur a partir d un code et d un message deja lisibles.
  const ErreurApi({required this.code, required this.message, this.statut});

  /// Construit l erreur correspondant a un echec de Dio.
  factory ErreurApi.depuisDio(DioException echec) {
    final Response<dynamic>? reponse = echec.response;
    final dynamic corps = reponse?.data;
    if (corps is Map && corps['code'] is String && corps['message'] is String) {
      return ErreurApi(
        code: corps['code'] as String,
        message: corps['message'] as String,
        statut: reponse?.statusCode,
      );
    }
    // Pas de corps exploitable : c est un probleme de reseau ou de serveur.
    return ErreurApi(
      code: reponse == null ? codeReseau : codeServeur,
      message: '',
      statut: reponse?.statusCode,
    );
  }

  /// Code technique, stable, sur lequel le code decide.
  final String code;

  /// Message deja redige par l API. Vide quand l API n a pas repondu.
  final String message;

  /// Code HTTP, quand il y en a un.
  final int? statut;

  /// Code pose quand l API est injoignable.
  static const String codeReseau = 'reseau';

  /// Code pose quand le serveur repond sans corps exploitable.
  static const String codeServeur = 'erreur_serveur';

  /// Code pose quand la session ne peut plus etre rafraichie.
  static const String codeSessionExpiree = 'session_expiree';

  /// Vrai si l erreur vient d une absence de reseau.
  bool get estReseau => code == codeReseau;

  /// Vrai si la session est a refaire.
  bool get estSessionExpiree => code == codeSessionExpiree || statut == 401;

  @override
  String toString() => 'ErreurApi($code, $statut)';
}
