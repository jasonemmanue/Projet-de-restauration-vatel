// Role du fichier : le manifeste cuisine, ce qu il faut preparer aujourd hui.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Les commandes du jour, vues de la cuisine.
class EcranCuisine extends StatelessWidget {
  /// Construit l ecran cuisine.
  const EcranCuisine({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletCuisine, etape: 'M4');
}
