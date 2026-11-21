// Role du fichier : l ecran de bienvenue, avant toute connexion.
// Le symbole se dessine puis se remplit en moins d une seconde, sauf si l utilisateur est deja
// connecte ou si le systeme demande de reduire les animations.
// Les fournisseurs proposes suivent l appareil : Android ne montre que Google, iPhone, iPad et
// ordinateur montrent Google et Apple. Le code QR est propose partout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/plateforme.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_fournisseur.dart';
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
    final double tailleLogo = type.estTelephone ? 124 : 160;
    final List<Fournisseur> fournisseurs = Plateforme.fournisseurs;

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 24),
                  LogoAnime(taille: tailleLogo, anime: !dejaConnecte),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 18),
                  TexteAdapte(
                    mots.accrocheBienvenue,
                    maxLignes: 3,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  // F2b branchera ces boutons. Leur place et leur dessin sont fixes ici.
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.continuerAvecIdentifiant,
        onPressed: null,
        raisonIndisponible: mots.bientotDisponible,
      ),
    );
  }
}
