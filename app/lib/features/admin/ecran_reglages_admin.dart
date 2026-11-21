// Role du fichier : les reglages metier et les reglages de l application, cote administration.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Les reglages du back office.
class EcranReglagesAdmin extends StatelessWidget {
  /// Construit les reglages de l administration.
  const EcranReglagesAdmin({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletReglages, etape: 'F5');
}
