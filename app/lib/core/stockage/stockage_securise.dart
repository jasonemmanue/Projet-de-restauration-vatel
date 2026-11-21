// Role du fichier : lecture et ecriture du stockage securise, en vol unique et avec trois essais.
// Le stockage securise peut etre lent ou occupe au demarrage : deux ecrans qui demandent le meme
// jeton ne declenchent qu une seule lecture, et un echec passager est retente.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../outils/vol_unique.dart';

/// Enveloppe le stockage securise de la plateforme.
class StockageSecurise {
  /// Construit le stockage avec les options par defaut de chaque plateforme.
  StockageSecurise()
      : _stockage = const FlutterSecureStorage();

  final FlutterSecureStorage _stockage;
  final VolUnique _vols = VolUnique();

  /// Lit une valeur, une seule fois meme si plusieurs appels arrivent ensemble.
  Future<String?> lire(String cle) =>
      _vols.executer<String?>('lire:$cle', () => avecTroisEssais(() => _stockage.read(key: cle)));

  /// Ecrit une valeur, ou l efface si elle est vide.
  Future<void> ecrire(String cle, String? valeur) async {
    if (valeur == null) {
      await avecTroisEssais(() => _stockage.delete(key: cle));
      return;
    }
    await avecTroisEssais(() => _stockage.write(key: cle, value: valeur));
  }

  /// Efface toutes les valeurs connues de l application.
  Future<void> toutEffacer() => avecTroisEssais(() => _stockage.deleteAll());
}

/// Le stockage securise de l application.
final Provider<StockageSecurise> stockageSecuriseProvider =
    Provider<StockageSecurise>((Ref ref) => StockageSecurise());
