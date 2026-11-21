// Role du fichier : le compte de l utilisateur. F2c y posera le profil complet et les reglages.
// Pour l instant il porte le nom du compte et la deconnexion, qui ferme la session des deux cotes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/routes/routes.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../auth/donnees/service_auth.dart';

/// L espace compte, commun à tous les rôles.
class EcranCompte extends ConsumerWidget {
  /// Construit l écran du compte.
  const EcranCompte({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final Session? session = ref.watch(sessionProvider).value;

    return PageDefilante(
      enfants: <Widget>[
        TexteAdapte(mots.ongletCompte, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 16),
        if (session != null)
          Container(
            padding: const EdgeInsets.all(Mesures.marge),
            decoration: BoxDecoration(
              color: couleurs.surface,
              borderRadius: BorderRadius.circular(Mesures.rayonCarte),
              border: Border.all(color: couleurs.filet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteAdapte(
                  session.nomComplet.isEmpty ? mots.ongletProfil : session.nomComplet,
                  style: Theme.of(contexte).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                TexteAdapte(
                  session.role.name,
                  style: Theme.of(contexte).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        TexteAdapte(
          '${mots.ecranEnConstruction} (F2c)',
          maxLignes: 2,
          style: Theme.of(contexte).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: Mesures.hauteurBouton,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(serviceAuthProvider).deconnecter();
              if (contexte.mounted) {
                contexte.go(Chemins.bienvenue);
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(mots.deconnexion),
          ),
        ),
      ],
    );
  }
}
