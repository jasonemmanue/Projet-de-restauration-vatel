// Role du fichier : la collecte des tickets par l agent. F6 y branchera le scan et la file hors ligne.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// L ecran de scan de l agent.
class EcranCollecte extends StatelessWidget {
  /// Construit l ecran de collecte.
  const EcranCollecte({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletCollecte, etape: 'F6');
}
