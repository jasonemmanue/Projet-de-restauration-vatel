// Role du fichier : le lien de paiement, pour se faire payer par un proche.
// Accessible depuis tous les ecrans d argent, quel que soit le statut du compte. F6 le remplira.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// La creation et le suivi des liens de paiement.
class EcranLienPaiement extends StatelessWidget {
  /// Construit l ecran des liens de paiement.
  const EcranLienPaiement({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).lienPaiement, etape: 'F6');
}
