// Role du fichier : produire la cle unique d un geste d argent ou de reservation.
// Le serveur s en sert pour ne compter qu une fois un geste renvoye deux fois.

import 'dart:math';

/// Fabrique des cles de geste, uniques par appareil et par instant.
class CleDemande {
  CleDemande._();

  static final Random _hasard = Random.secure();

  /// Nom de l en tete attendu par l API.
  static const String enTete = 'X-Cle-Demande';

  /// Rend une nouvelle cle de geste, a garder tant que le geste est rejoue.
  static String nouvelle() {
    final String instant = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
    final String bruit = List<int>.generate(8, (_) => _hasard.nextInt(36))
        .map((int valeur) => valeur.toRadixString(36))
        .join();
    return '$instant-$bruit';
  }
}
