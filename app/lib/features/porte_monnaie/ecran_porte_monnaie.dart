// Role du fichier : le solde et l historique des mouvements. M3 y branchera /porte-monnaie.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Le porte-monnaie du convive ou du parent.
class EcranPorteMonnaie extends StatelessWidget {
  /// Construit l ecran du porte-monnaie.
  const EcranPorteMonnaie({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletRecharge, etape: 'M3');
}
