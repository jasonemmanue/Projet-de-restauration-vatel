// Role du fichier : le ticket QR du jour. M3 y posera le QR, noir sur blanc dans les deux modes.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Le ticket QR du convive.
class EcranTicket extends StatelessWidget {
  /// Construit l ecran du ticket.
  const EcranTicket({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletTicket, etape: 'M3');
}
