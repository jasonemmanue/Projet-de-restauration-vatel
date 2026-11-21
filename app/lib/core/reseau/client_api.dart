// Role du fichier : le seul point de sortie reseau de l application.
// Il ajoute le jeton, rafraichit en vol unique, pose la cle de geste et traduit tout echec
// en ErreurApi. Aucun ecran n appelle Dio directement.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../outils/vol_unique.dart';
import '../securite/session.dart';
import 'cle_demande.dart';
import 'erreur_api.dart';

/// Adresse de l API, posee a la compilation par --dart-define=API_URL.
const String adresseApi = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Le client reseau de l application.
class ClientApi {
  /// Construit le client et installe ses intercepteurs.
  ClientApi(this._ref) {
    dio = Dio(
      BaseOptions(
        baseUrl: adresseApi,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: <String, String>{'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _avantEnvoi,
        onError: _surEchec,
      ),
    );
  }

  final Ref _ref;
  final VolUnique _vols = VolUnique();

  /// Le client Dio configure.
  late final Dio dio;

  /// Cle de vol unique du rafraichissement : deux requetes expirees n en lancent qu un.
  static const String _cleRafraichissement = 'rafraichir';

  /// Marqueur pose sur une requete deja rejouee, pour ne pas boucler.
  static const String _dejaRejouee = 'deja_rejouee';

  void _avantEnvoi(RequestOptions options, RequestInterceptorHandler suite) {
    final Session? session = _ref.read(sessionProvider).value;
    if (session != null && session.jetonAcces.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${session.jetonAcces}';
    }
    // Un geste d argent ou de reservation porte sa cle, fournie par l appelant
    // et conservee telle quelle quand la requete est rejouee.
    final Object? cle = options.extra['cle_geste'];
    if (cle is String && cle.isNotEmpty) {
      options.headers[CleDemande.enTete] = cle;
    }
    suite.next(options);
  }

  Future<void> _surEchec(DioException echec, ErrorInterceptorHandler suite) async {
    final RequestOptions demande = echec.requestOptions;
    final bool estExpiree = echec.response?.statusCode == 401;
    final bool dejaRejouee = demande.extra[_dejaRejouee] == true;
    final bool estRafraichissement = demande.path.contains('/auth/rafraichir');

    if (!estExpiree || dejaRejouee || estRafraichissement) {
      suite.reject(echec.copyWith(error: ErreurApi.depuisDio(echec)));
      return;
    }

    final bool rafraichi = await _rafraichir();
    if (!rafraichi) {
      await _ref.read(sessionProvider.notifier).fermer();
      suite.reject(
        echec.copyWith(
          error: const ErreurApi(code: ErreurApi.codeSessionExpiree, message: ''),
        ),
      );
      return;
    }

    try {
      demande.extra[_dejaRejouee] = true;
      final Response<dynamic> reponse = await dio.fetch<dynamic>(demande);
      suite.resolve(reponse);
    } on DioException catch (second) {
      suite.reject(second.copyWith(error: ErreurApi.depuisDio(second)));
    }
  }

  /// Demande un nouveau jeton, une seule fois meme si plusieurs requetes expirent ensemble.
  Future<bool> _rafraichir() => _vols.executer<bool>(_cleRafraichissement, () async {
        final Session? session = _ref.read(sessionProvider).value;
        if (session == null || session.jetonRafraichissement.isEmpty) {
          return false;
        }
        try {
          final Response<dynamic> reponse = await dio.post<dynamic>(
            '/auth/rafraichir',
            data: <String, String>{'jeton_rafraichissement': session.jetonRafraichissement},
          );
          final dynamic corps = reponse.data;
          if (corps is! Map) {
            return false;
          }
          final String acces = corps['jeton'] as String? ?? '';
          final String suivant = corps['jeton_rafraichissement'] as String? ?? '';
          if (acces.isEmpty) {
            return false;
          }
          await _ref
              .read(sessionProvider.notifier)
              .remplacerJetons(acces: acces, rafraichissement: suivant);
          return true;
        } on DioException {
          return false;
        }
      });

  /// Lit une ressource et rend le corps JSON.
  Future<Map<String, dynamic>> lire(String chemin, {Map<String, dynamic>? parametres}) async {
    return _appeler(() => dio.get<dynamic>(chemin, queryParameters: parametres));
  }

  /// Envoie un corps JSON. Une cle de geste rend l envoi rejouable sans risque.
  Future<Map<String, dynamic>> envoyer(
    String chemin, {
    Object? corps,
    String? cleGeste,
    String? preuvePin,
  }) async {
    return _appeler(
      () => dio.post<dynamic>(
        chemin,
        data: corps,
        options: Options(
          extra: <String, Object?>{'cle_geste': cleGeste},
          headers: preuvePin == null ? null : <String, String>{'X-Preuve-Pin': preuvePin},
        ),
      ),
    );
  }

  /// Verifie que l API repond, en quatre secondes au plus.
  Future<bool> sante() async {
    try {
      final Response<dynamic> reponse = await dio.get<dynamic>(
        '/sante',
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      return reponse.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>> _appeler(Future<Response<dynamic>> Function() appel) async {
    try {
      final Response<dynamic> reponse = await appel();
      final dynamic corps = reponse.data;
      if (corps is Map<String, dynamic>) {
        return corps;
      }
      if (corps is Map) {
        return corps.cast<String, dynamic>();
      }
      return <String, dynamic>{'donnees': corps};
    } on DioException catch (echec) {
      final Object? deja = echec.error;
      throw deja is ErreurApi ? deja : ErreurApi.depuisDio(echec);
    }
  }
}

/// Le client reseau de l application.
final Provider<ClientApi> clientApiProvider = Provider<ClientApi>(ClientApi.new);
