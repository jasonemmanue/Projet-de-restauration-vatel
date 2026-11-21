// Role du fichier : le manifeste du service en cours, cote agent.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// La liste des convives attendus au creneau en cours.
class EcranManifeste extends StatelessWidget {
  /// Construit le manifeste.
  const EcranManifeste({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletManifeste, etape: 'F6');
}
