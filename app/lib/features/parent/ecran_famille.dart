// Role du fichier : la famille du parent, enfants lies et leurs soldes. F4 la remplira.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// La liste des enfants lies au parent.
class EcranFamille extends StatelessWidget {
  /// Construit l ecran famille.
  const EcranFamille({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletFamille, etape: 'F4');
}
