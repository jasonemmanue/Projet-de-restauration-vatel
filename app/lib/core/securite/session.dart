// Role du fichier : la session de l utilisateur connecte, gardee dans le stockage securise.
// Le role lu ici decide des routes accessibles : il n est jamais devine depuis l ecran.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../stockage/stockage_securise.dart';

/// Les quatre roles de l application.
enum Role {
  /// Eleve, etudiant ou employe.
  convive,

  /// Parent lie a un ou plusieurs enfants.
  parent,

  /// Agent de service au comptoir.
  agent,

  /// Administration de la cantine.
  admin;

  /// Rend le role portant ce nom, ou convive par defaut.
  static Role depuisTexte(String? valeur) =>
      Role.values.firstWhere((Role role) => role.name == valeur, orElse: () => Role.convive);
}

/// Ce que l application garde d un utilisateur connecte.
class Session {
  /// Construit une session a partir des jetons et du role rendus par l API.
  const Session({
    required this.jetonAcces,
    required this.jetonRafraichissement,
    required this.role,
    required this.utilisateurId,
    required this.nomComplet,
    this.statutConvive,
  });

  /// Relit une session ecrite sur l appareil.
  factory Session.depuisJson(Map<String, dynamic> json) => Session(
        jetonAcces: json['jeton_acces'] as String? ?? '',
        jetonRafraichissement: json['jeton_rafraichissement'] as String? ?? '',
        role: Role.depuisTexte(json['role'] as String?),
        utilisateurId: json['utilisateur_id'] as String? ?? '',
        nomComplet: json['nom_complet'] as String? ?? '',
        statutConvive: json['statut_convive'] as String?,
      );

  /// Jeton envoye a chaque requete.
  final String jetonAcces;

  /// Jeton qui sert a obtenir un nouveau jeton d acces.
  final String jetonRafraichissement;

  /// Role de l utilisateur, qui decide de ses ecrans.
  final Role role;

  /// Identifiant de l utilisateur.
  final String utilisateurId;

  /// Nom affiche dans l application.
  final String nomComplet;

  /// Profil tarifaire du convive : eleve, etudiant, employe ou autre.
  final String? statutConvive;

  /// Rend une copie avec de nouveaux jetons.
  Session avecJetons({required String acces, required String rafraichissement}) => Session(
        jetonAcces: acces,
        jetonRafraichissement: rafraichissement,
        role: role,
        utilisateurId: utilisateurId,
        nomComplet: nomComplet,
        statutConvive: statutConvive,
      );

  /// Rend la session sous une forme ecrivable sur l appareil.
  Map<String, dynamic> versJson() => <String, dynamic>{
        'jeton_acces': jetonAcces,
        'jeton_rafraichissement': jetonRafraichissement,
        'role': role.name,
        'utilisateur_id': utilisateurId,
        'nom_complet': nomComplet,
        'statut_convive': statutConvive,
      };
}

/// Tient la session courante et l ecrit dans le stockage securise.
class SessionNotifier extends AsyncNotifier<Session?> {
  static const String _cle = 'session';

  @override
  Future<Session?> build() async {
    final StockageSecurise stockage = ref.watch(stockageSecuriseProvider);
    final String? brut = await stockage.lire(_cle);
    if (brut == null || brut.isEmpty) {
      return null;
    }
    try {
      return Session.depuisJson(jsonDecode(brut) as Map<String, dynamic>);
    } on FormatException {
      // Une session illisible vaut une absence de session : on repart propre.
      await stockage.ecrire(_cle, null);
      return null;
    }
  }

  /// Ouvre une session et la garde sur l appareil.
  Future<void> ouvrir(Session session) async {
    await ref.read(stockageSecuriseProvider).ecrire(_cle, jsonEncode(session.versJson()));
    state = AsyncData<Session?>(session);
  }

  /// Remplace les jetons apres un rafraichissement reussi.
  Future<void> remplacerJetons({required String acces, required String rafraichissement}) async {
    final Session? courante = state.value;
    if (courante == null) {
      return;
    }
    await ouvrir(courante.avecJetons(acces: acces, rafraichissement: rafraichissement));
  }

  /// Ferme la session et efface tout ce qui la concerne.
  Future<void> fermer() async {
    await ref.read(stockageSecuriseProvider).ecrire(_cle, null);
    state = const AsyncData<Session?>(null);
  }
}

/// La session en cours, ou rien si personne n est connecte.
final AsyncNotifierProvider<SessionNotifier, Session?> sessionProvider =
    AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);
