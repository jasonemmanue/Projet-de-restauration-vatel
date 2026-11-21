// Role du fichier : le chargement en squelette, a la taille finale du contenu.
// Une carte ne repart jamais de zero pixel : la place est reservee avant les donnees.

import 'package:flutter/material.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';

/// Un bloc gris anime qui occupe exactement la place du contenu attendu.
class Squelette extends StatefulWidget {
  /// Construit un squelette de la taille voulue.
  const Squelette({
    super.key,
    this.hauteur = 16,
    this.largeur,
    this.rayon = Mesures.rayonPetit,
  });

  /// Hauteur du bloc.
  final double hauteur;

  /// Largeur du bloc. Vide, il prend toute la place.
  final double? largeur;

  /// Rayon des coins.
  final double rayon;

  @override
  State<Squelette> createState() => _EtatSquelette();
}

class _EtatSquelette extends State<Squelette> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    // L animation ne tourne pas quand le systeme demande de reduire les animations.
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext contexte, Widget? enfant) {
        final double melange = 0.45 + 0.25 * _animation.value;
        return Container(
          height: widget.hauteur,
          width: widget.largeur,
          decoration: BoxDecoration(
            color: Color.lerp(couleurs.muet, couleurs.filet, melange),
            borderRadius: BorderRadius.circular(widget.rayon),
          ),
        );
      },
    );
  }
}

/// Une carte en squelette, de la taille d une carte reelle.
class CarteSquelette extends StatelessWidget {
  /// Construit une carte en squelette.
  const CarteSquelette({super.key, this.hauteur = 96});

  /// Hauteur de la carte attendue.
  final double hauteur;

  @override
  Widget build(BuildContext contexte) {
    return Container(
      height: hauteur,
      padding: const EdgeInsets.all(Mesures.marge),
      decoration: BoxDecoration(
        color: contexte.couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: contexte.couleurs.filet),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Squelette(hauteur: 14, largeur: 160),
          SizedBox(height: 12),
          Squelette(hauteur: 12, largeur: 220),
        ],
      ),
    );
  }
}
