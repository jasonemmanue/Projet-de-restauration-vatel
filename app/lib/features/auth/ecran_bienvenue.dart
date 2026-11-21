// Role du fichier : l ecran de bienvenue, avant toute connexion.
// Le symbole se dessine puis se remplit en moins d une seconde, sauf si l utilisateur est deja
// connecte ou si le systeme demande de reduire les animations.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/logo_cantine.dart';
import '../../shared/widgets/texte_adapte.dart';

/// L ecran montre tant que personne n est connecte.
class EcranBienvenue extends ConsumerWidget {
  /// Construit l ecran de bienvenue.
  const EcranBienvenue({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool dejaConnecte = ref.watch(sessionProvider).value != null;
    final TypeEcran type = TypeEcran.de(contexte);
    final double tailleLogo = type.estTelephone ? 132 : 168;

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  LogoAnime(taille: tailleLogo, anime: !dejaConnecte),
                  const SizedBox(height: 28),
                  TexteAdapte(
                    mots.nomApplication,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  TexteAdapte(
                    mots.signatureMarque,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                          color: couleurs.texteSecondaire,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TexteAdapte(
                    mots.accrocheBienvenue,
                    maxLignes: 3,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  // La place des boutons Google et Apple est tenue ici : F2b les branchera.
                  _BoutonFournisseurAVenir(libelle: mots.continuerAvecGoogle, icone: Icons.g_mobiledata),
                  const SizedBox(height: 10),
                  _BoutonFournisseurAVenir(libelle: mots.continuerAvecApple, icone: Icons.apple),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.continuerAvecIdentifiant,
        // F2 branchera l ecran d inscription et de connexion.
        onPressed: null,
        raisonIndisponible: mots.bientotDisponible,
      ),
    );
  }
}

class _BoutonFournisseurAVenir extends StatelessWidget {
  const _BoutonFournisseurAVenir({required this.libelle, required this.icone});

  final String libelle;
  final IconData icone;

  @override
  Widget build(BuildContext contexte) {
    return SizedBox(
      height: Mesures.hauteurBouton,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icone, size: 22),
            const SizedBox(width: 10),
            Flexible(child: TexteAdapte(libelle, alignement: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
