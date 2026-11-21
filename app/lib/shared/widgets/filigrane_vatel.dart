// Role du fichier : le logo de l ecole Vatel, en filigrane et aux endroits strategiques.
// Le fichier attendu est assets/marque/vatel.png. Tant qu il n est pas depose, on retombe sur
// le symbole de la cantine : aucune image cassee, jamais.

import 'package:flutter/material.dart';

import '../../core/theme/couleurs.dart';
import 'logo_cantine.dart';

/// Chemin du logo de l ecole dans les ressources.
const String ressourceLogoVatel = 'assets/marque/vatel.png';

/// Le logo de l ecole, a la taille voulue, avec repli sur le symbole de la cantine.
class LogoVatel extends StatelessWidget {
  /// Construit le logo de l ecole.
  const LogoVatel({super.key, this.hauteur = 40, this.opacite = 1});

  /// Hauteur du logo.
  final double hauteur;

  /// Opacite, de 0 a 1.
  final double opacite;

  @override
  Widget build(BuildContext contexte) {
    return Opacity(
      opacity: opacite,
      child: Image.asset(
        ressourceLogoVatel,
        height: hauteur,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
            LogoCantine(taille: hauteur),
      ),
    );
  }
}

/// Le logo de l ecole en filigrane, pose derriere le contenu d un ecran.
class FiligraneVatel extends StatelessWidget {
  /// Construit le filigrane.
  const FiligraneVatel({
    super.key,
    this.taille = 420,
    this.opacite = 0.06,
    this.alignement = Alignment.bottomRight,
  });

  /// Cote du filigrane.
  final double taille;

  /// Opacite du filigrane. La charte veut qu il reste a peine visible.
  final double opacite;

  /// Coin ou il se pose.
  final Alignment alignement;

  @override
  Widget build(BuildContext contexte) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignement,
          child: Transform.translate(
            offset: Offset(taille * 0.22, taille * 0.18),
            child: LogoVatel(hauteur: taille, opacite: opacite),
          ),
        ),
      ),
    );
  }
}

/// La signature « une cantine Vatel », posee en pied d ecran.
class SignatureVatel extends StatelessWidget {
  /// Construit la signature.
  const SignatureVatel({super.key, this.hauteur = 26});

  /// Hauteur du logo dans la signature.
  final double hauteur;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'une cantine',
          style: Theme.of(contexte)
              .textTheme
              .labelMedium
              ?.copyWith(color: couleurs.texteSecondaire),
        ),
        const SizedBox(width: 8),
        LogoVatel(hauteur: hauteur),
      ],
    );
  }
}
