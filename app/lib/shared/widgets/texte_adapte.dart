// Role du fichier : afficher un texte sans jamais le couper par des points de suspension.
// Sur une ligne, la taille baisse jusqu a ce que le texte tienne. Sur plusieurs lignes,
// le texte passe a la ligne normalement.

import 'package:flutter/widgets.dart';

/// Un texte qui s adapte a la place disponible au lieu d etre tronque.
class TexteAdapte extends StatelessWidget {
  /// Construit un texte adapte a la largeur disponible.
  const TexteAdapte(
    this.texte, {
    super.key,
    this.style,
    this.maxLignes = 1,
    this.facteurMin = 0.72,
    this.alignement = TextAlign.start,
  });

  /// Le texte a afficher, deja traduit.
  final String texte;

  /// Le style voulu. La taille peut etre reduite pour tenir.
  final TextStyle? style;

  /// Nombre de lignes autorisees. Au dela de une, le texte passe a la ligne.
  final int maxLignes;

  /// Reduction maximale de la taille avant de laisser le texte passer a la ligne.
  final double facteurMin;

  /// Alignement du texte.
  final TextAlign alignement;

  @override
  Widget build(BuildContext contexte) {
    final TextStyle styleFinal = style ?? DefaultTextStyle.of(contexte).style;
    if (maxLignes != 1) {
      return Text(
        texte,
        style: styleFinal,
        textAlign: alignement,
        maxLines: maxLignes,
        softWrap: true,
        // Jamais de points de suspension : le texte est visible ou il passe a la ligne.
        overflow: TextOverflow.visible,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double largeur = contraintes.maxWidth;
        final double tailleVoulue = styleFinal.fontSize ?? 14;
        final double echelle = MediaQuery.textScalerOf(contexte).scale(tailleVoulue) / tailleVoulue;
        double taille = tailleVoulue;

        if (largeur.isFinite) {
          while (taille > tailleVoulue * facteurMin) {
            final TextPainter mesure = TextPainter(
              text: TextSpan(text: texte, style: styleFinal.copyWith(fontSize: taille * echelle)),
              maxLines: 1,
              textDirection: Directionality.of(contexte),
            )..layout();
            if (mesure.width <= largeur) {
              break;
            }
            taille -= 0.5;
          }
        }

        return Text(
          texte,
          style: styleFinal.copyWith(fontSize: taille),
          textAlign: alignement,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textScaler: TextScaler.linear(echelle),
        );
      },
    );
  }
}
