// Role du fichier : l ecran de bienvenue, avant toute connexion.
// Images qui defilent, symbole qui se dessine, puis les portes d entree : identifiant,
// Google, Apple, code QR, et le mode visiteur pour regarder sans compte.
// Les fournisseurs proposes suivent l appareil : Android ne montre que Google.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/plateforme.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/routes/routes.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_fournisseur.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/logo_cantine.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'widgets/mise_en_page_auth.dart';

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
    final List<Fournisseur> fournisseurs = Plateforme.fournisseurs;

    return MiseEnPageAuth(
      basDePage: BoutonPrincipal(
        libelle: mots.continuerAvecIdentifiant,
        onPressed: () => contexte.go(Chemins.inscription),
      ),
      enfant: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 18),
          Center(child: LogoAnime(taille: type.estTelephone ? 96 : 130, anime: !dejaConnecte)),
          const SizedBox(height: 18),
          TexteAdapte(
            mots.nomApplication,
            alignement: TextAlign.center,
            style: Theme.of(contexte).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          TexteAdapte(
            mots.signatureMarque,
            alignement: TextAlign.center,
            style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                  color: couleurs.texteSecondaire,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 14),
          TexteAdapte(
            mots.accrocheBienvenue,
            maxLignes: 3,
            alignement: TextAlign.center,
            style: Theme.of(contexte).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (fournisseurs.contains(Fournisseur.google))
            BoutonFournisseur(
              libelle: mots.continuerAvecGoogle,
              ressourceLogo: 'assets/marque/google-g-96.png',
              onPressed: null,
            ),
          if (fournisseurs.contains(Fournisseur.apple)) ...<Widget>[
            const SizedBox(height: 10),
            BoutonFournisseur(
              libelle: mots.continuerAvecApple,
              ressourceLogo: 'assets/marque/apple-96.png',
              onPressed: null,
            ),
          ],
          const SizedBox(height: 10),
          BoutonFournisseur.icone(
            libelle: mots.connexionCodeQr,
            icone: Icons.qr_code_2,
            onPressed: null,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => contexte.go(Chemins.visiteur),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: Text(mots.modeVisiteur),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => contexte.go(Chemins.connexion),
              child: Text(mots.jaiUnCompte),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
