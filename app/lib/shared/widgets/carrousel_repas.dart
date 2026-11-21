// Role du fichier : le bandeau d images qui defile, en haut sur telephone et a gauche sur grand ecran.
// Il tourne tout seul, s arrete quand le systeme demande de reduire les animations, et porte
// une accroche lisible posee sur un voile sombre, jamais sur la photo nue.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import 'filigrane_vatel.dart';
import 'texte_adapte.dart';

/// Une vue du carrousel : une photo et son accroche.
class VueCarrousel {
  /// Construit une vue.
  const VueCarrousel({required this.image, required this.titre, required this.detail});

  /// Fichier de la photo dans les ressources.
  final String image;

  /// Accroche, deja traduite.
  final String titre;

  /// Une ligne de detail, deja traduite.
  final String detail;
}

/// Le bandeau d images qui defile.
class CarrouselRepas extends StatefulWidget {
  /// Construit le carrousel.
  const CarrouselRepas({super.key, this.hauteur = 220, this.arrondi = true});

  /// Hauteur du bandeau.
  final double hauteur;

  /// Faux pour coller le bandeau aux bords, sans coins arrondis.
  final bool arrondi;

  @override
  State<CarrouselRepas> createState() => _EtatCarrouselRepas();
}

class _EtatCarrouselRepas extends State<CarrouselRepas> {
  final PageController _pages = PageController();
  Timer? _minuteur;
  int _vue = 0;

  @override
  void initState() {
    super.initState();
    final bool animationsReduites =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!animationsReduites) {
      // Un simple defilement d images : aucun appel reseau la dedans.
      _minuteur = Timer.periodic(const Duration(seconds: 5), (_) => _suivante());
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _suivante() {
    if (!mounted || !_pages.hasClients) {
      return;
    }
    final int total = _vues(Traductions.of(context)).length;
    final int suivante = (_vue + 1) % total;
    unawaited(
      _pages.animateToPage(
        suivante,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  List<VueCarrousel> _vues(Traductions mots) => <VueCarrousel>[
        VueCarrousel(
          image: 'assets/plats/attieke.jpg',
          titre: mots.carrouselTitre1,
          detail: mots.carrouselDetail1,
        ),
        VueCarrousel(
          image: 'assets/plats/poulet.jpg',
          titre: mots.carrouselTitre2,
          detail: mots.carrouselDetail2,
        ),
        VueCarrousel(
          image: 'assets/plats/sauce.jpg',
          titre: mots.carrouselTitre3,
          detail: mots.carrouselDetail3,
        ),
        VueCarrousel(
          image: 'assets/plats/riz.jpg',
          titre: mots.carrouselTitre4,
          detail: mots.carrouselDetail4,
        ),
      ];

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final List<VueCarrousel> vues = _vues(mots);

    final Widget bandeau = SizedBox(
      height: widget.hauteur,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pages,
            itemCount: vues.length,
            onPageChanged: (int index) => setState(() => _vue = index),
            itemBuilder: (BuildContext contexte, int index) => Image.asset(
              vues[index].image,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                  ColoredBox(color: couleurs.muet),
            ),
          ),
          // Voile sombre : le texte reste lisible quelle que soit la photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00000000), Color(0xCC0B1220)],
                stops: <double>[0.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SignatureVatelClaire(),
                const SizedBox(height: 12),
                TexteAdapte(
                  vues[_vue].titre,
                  maxLignes: 2,
                  style: Theme.of(contexte)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                TexteAdapte(
                  vues[_vue].detail,
                  maxLignes: 2,
                  style: Theme.of(contexte)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: const Color(0xE6FFFFFF)),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            child: Row(
              children: <Widget>[
                for (int index = 0; index < vues.length; index++)
                  AnimatedContainer(
                    duration: Mesures.transition,
                    margin: const EdgeInsets.only(right: 6),
                    height: 5,
                    width: index == _vue ? 22 : 10,
                    decoration: BoxDecoration(
                      color: index == _vue ? Colors.white : const Color(0x80FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.arrondi) {
      return bandeau;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mesures.rayonGrand),
      child: bandeau,
    );
  }
}

/// La signature de l ecole, posee en clair sur une photo.
class SignatureVatelClaire extends StatelessWidget {
  /// Construit la signature claire.
  const SignatureVatelClaire({super.key});

  @override
  Widget build(BuildContext contexte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const LogoVatel(hauteur: 22),
    );
  }
}
