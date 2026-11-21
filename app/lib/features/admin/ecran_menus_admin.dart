// Role du fichier : la gestion des menus par l administration. M4 y posera creation et publication.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// La gestion des menus et des creneaux.
class EcranMenusAdmin extends StatelessWidget {
  /// Construit la gestion des menus.
  const EcranMenusAdmin({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletMenus, etape: 'M4');
}
