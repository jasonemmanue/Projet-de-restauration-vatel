// Role du fichier : les messages recus par le parent. F4 et F7 les rempliront.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Les messages de la cantine au parent.
class EcranMessages extends StatelessWidget {
  /// Construit l ecran des messages.
  const EcranMessages({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletMessages, etape: 'F4');
}
