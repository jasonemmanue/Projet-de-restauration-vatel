// Role du fichier : le centre de notifications. F7 y branchera /notifications.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// Les notifications recues par l utilisateur.
class EcranNotifications extends StatelessWidget {
  /// Construit le centre de notifications.
  const EcranNotifications({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletNotifications, etape: 'F7');
}
