// Role du fichier : le compte de l utilisateur. F2c y posera le profil complet et les reglages.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';

/// L espace compte, commun a tous les roles.
class EcranCompte extends StatelessWidget {
  /// Construit l ecran du compte.
  const EcranCompte({super.key});

  @override
  Widget build(BuildContext contexte) =>
      PageEnChantier(titre: Traductions.of(contexte).ongletCompte, etape: 'F2c');
}
