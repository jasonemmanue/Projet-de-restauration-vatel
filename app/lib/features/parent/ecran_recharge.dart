// Role du fichier : la recharge Mobile Money. F6 y branchera GeniusPay et les liens de paiement.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// La recharge du porte-monnaie, par Mobile Money ou par lien de paiement.
class EcranRecharge extends StatelessWidget {
  /// Construit l ecran de recharge.
  const EcranRecharge({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletRecharge, etape: 'F6');
}
