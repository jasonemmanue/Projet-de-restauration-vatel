// Role du fichier : garantir qu un meme travail lance deux fois ne tourne qu une fois.
// Sert au rafraichissement du jeton, au chargement des ecrans et a la lecture du stockage securise.

import 'dart:async';

/// Garde une seule execution en vol par cle, et rend la meme reponse aux suivants.
class VolUnique {
  final Map<String, Future<Object?>> _enCours = <String, Future<Object?>>{};

  /// Lance la tache si elle n est pas deja en cours, sinon rend celle qui tourne.
  Future<T> executer<T>(String cle, Future<T> Function() tache) {
    final Future<Object?>? deja = _enCours[cle];
    if (deja != null) {
      return deja.then((Object? valeur) => valeur as T);
    }
    final Future<T> lancee = tache();
    _enCours[cle] = lancee;
    // Le nettoyage se fait dans les deux cas, succes comme echec.
    unawaited(
      lancee.whenComplete(() {
        _enCours.remove(cle);
      }).catchError((Object _) => null as T),
    );
    return lancee;
  }

  /// Vrai si un travail portant cette cle est en cours.
  bool enCours(String cle) => _enCours.containsKey(cle);
}

/// Relance une tache jusqu a trois fois avant d abandonner.
Future<T> avecTroisEssais<T>(Future<T> Function() tache) async {
  Object? dernierEchec;
  for (int essai = 1; essai <= 3; essai++) {
    try {
      return await tache();
    } on Object catch (echec) {
      dernierEchec = echec;
      if (essai < 3) {
        await Future<void>.delayed(Duration(milliseconds: 120 * essai));
      }
    }
  }
  throw Exception('Trois essais ont echoue : $dernierEchec');
}
