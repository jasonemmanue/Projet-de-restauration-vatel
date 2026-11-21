// Role du fichier : le menu de la semaine. M3 y branchera GET /menus/semaine.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Le menu de la semaine, cote convive.
class EcranMenu extends StatelessWidget {
  /// Construit l ecran du menu.
  const EcranMenu({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletMenu, etape: 'M3');
}
