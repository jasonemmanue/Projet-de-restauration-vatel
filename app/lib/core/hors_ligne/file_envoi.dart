// Role du fichier : la file des actions faites hors ligne, gardee sur l appareil.
// Seuls les scans de l agent et les appreciations y entrent. Reserver, recharger et payer
// demandent le reseau : aucune action d argent ne passe par ici.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reseau/client_api.dart';
import '../reseau/erreur_api.dart';
import '../stockage/preferences.dart';

/// Ce qu une action en attente peut etre.
enum TypeAction {
  /// Scan d un ticket fait au comptoir sans reseau.
  scan,

  /// Appreciation d un plat ecrite sans reseau.
  appreciation,
}

/// Une action faite hors ligne, en attente d envoi.
class ActionEnAttente {
  /// Construit une action a envoyer plus tard.
  const ActionEnAttente({
    required this.cleUnique,
    required this.type,
    required this.chemin,
    required this.corps,
    required this.faiteLe,
  });

  /// Relit une action ecrite sur l appareil.
  factory ActionEnAttente.depuisJson(Map<String, dynamic> json) => ActionEnAttente(
        cleUnique: json['cle_unique'] as String,
        type: TypeAction.values.firstWhere(
          (TypeAction type) => type.name == json['type'],
          orElse: () => TypeAction.scan,
        ),
        chemin: json['chemin'] as String,
        corps: (json['corps'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
        faiteLe: DateTime.parse(json['faite_le'] as String),
      );

  /// Cle unique du geste : le serveur ne le compte qu une fois.
  final String cleUnique;

  /// Nature de l action.
  final TypeAction type;

  /// Route de l API a appeler.
  final String chemin;

  /// Corps a envoyer.
  final Map<String, dynamic> corps;

  /// Heure a laquelle l action a ete faite sur l appareil.
  final DateTime faiteLe;

  /// Rend l action sous une forme ecrivable.
  Map<String, dynamic> versJson() => <String, dynamic>{
        'cle_unique': cleUnique,
        'type': type.name,
        'chemin': chemin,
        'corps': corps,
        'faite_le': faiteLe.toIso8601String(),
      };
}

/// Tient la file des actions hors ligne et la vide au retour du reseau.
class FileEnvoiNotifier extends Notifier<List<ActionEnAttente>> {
  bool _envoiEnCours = false;

  @override
  List<ActionEnAttente> build() {
    final SharedPreferences preferences = ref.watch(preferencesProvider);
    final List<String> brut = preferences.getStringList(ClesPreference.fileEnvoi) ?? <String>[];
    return brut
        .map((String ligne) => ActionEnAttente.depuisJson(jsonDecode(ligne) as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Ajoute une action a envoyer plus tard, sans doublon de cle unique.
  Future<void> ajouter(ActionEnAttente action) async {
    if (state.any((ActionEnAttente deja) => deja.cleUnique == action.cleUnique)) {
      return;
    }
    state = <ActionEnAttente>[...state, action];
    await _ecrire();
  }

  /// Envoie les actions une par une, dans l ordre, et retire celles qui passent.
  Future<void> vider() async {
    if (_envoiEnCours || state.isEmpty) {
      return;
    }
    _envoiEnCours = true;
    try {
      final ClientApi client = ref.read(clientApiProvider);
      for (final ActionEnAttente action in List<ActionEnAttente>.of(state)) {
        try {
          await client.envoyer(action.chemin, corps: action.corps, cleGeste: action.cleUnique);
          state = state.where((ActionEnAttente autre) => autre.cleUnique != action.cleUnique).toList();
          await _ecrire();
        } on ErreurApi catch (echec) {
          if (echec.estReseau) {
            // Le reseau est reparti : on s arrete et on reprendra au prochain retour.
            return;
          }
          // L API a repondu et refuse l action : la garder ne sert a rien.
          state = state.where((ActionEnAttente autre) => autre.cleUnique != action.cleUnique).toList();
          await _ecrire();
        }
      }
    } finally {
      _envoiEnCours = false;
    }
  }

  Future<void> _ecrire() async {
    final SharedPreferences preferences = ref.read(preferencesProvider);
    await preferences.setStringList(
      ClesPreference.fileEnvoi,
      state.map((ActionEnAttente action) => jsonEncode(action.versJson())).toList(),
    );
  }
}

/// La file des actions faites hors ligne.
final NotifierProvider<FileEnvoiNotifier, List<ActionEnAttente>> fileEnvoiProvider =
    NotifierProvider<FileEnvoiNotifier, List<ActionEnAttente>>(FileEnvoiNotifier.new);
