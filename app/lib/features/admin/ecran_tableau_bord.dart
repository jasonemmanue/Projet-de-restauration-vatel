// Role du fichier : le tableau de bord du back office. M4 y posera les chiffres du jour.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Le tableau de bord de l administration.
class EcranTableauBord extends StatelessWidget {
  /// Construit le tableau de bord.
  const EcranTableauBord({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletTableauBord, etape: 'M4');
}
