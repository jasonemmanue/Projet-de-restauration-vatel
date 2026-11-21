// Role du fichier : l accueil du convive. F3 y posera le menu du jour et la reservation rapide.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// L accueil de l espace convive.
class EcranAccueil extends StatelessWidget {
  /// Construit l accueil.
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletAccueil, etape: 'M3');
}
