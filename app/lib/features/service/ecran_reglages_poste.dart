// Role du fichier : les reglages du poste de l agent, dont le mode hors ligne.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Les reglages du poste de service.
class EcranReglagesPoste extends StatelessWidget {
  /// Construit les reglages du poste.
  const EcranReglagesPoste({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletReglages, etape: 'F6');
}
