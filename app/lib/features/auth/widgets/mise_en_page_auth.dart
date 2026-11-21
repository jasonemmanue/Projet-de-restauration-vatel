// Role du fichier : la mise en page commune des ecrans d entree.
// Sur grand ecran, deux colonnes : les images a gauche, le formulaire a droite.
// Sur telephone, le bandeau d images en haut, le formulaire dessous. Meme code, deux formes.

import 'package:flutter/material.dart';

import '../../../core/responsive/type_ecran.dart';
import '../../../core/theme/couleurs.dart';
import '../../../shared/widgets/carrousel_repas.dart';
import '../../../shared/widgets/filigrane_vatel.dart';

/// Pose un contenu d authentification dans la bonne forme selon l ecran.
class MiseEnPageAuth extends StatelessWidget {
  /// Construit la mise en page.
  const MiseEnPageAuth({
    required this.enfant,
    super.key,
    this.barre,
    this.basDePage,
    this.montrerCarrousel = true,
  });

  /// Le formulaire ou le contenu de l ecran.
  final Widget enfant;

  /// Une barre du haut, sur telephone seulement.
  final PreferredSizeWidget? barre;

  /// Ce qui se colle en bas de l ecran.
  final Widget? basDePage;

  /// Faux pour un ecran qui n a pas besoin des images.
  final bool montrerCarrousel;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final TypeEcran type = TypeEcran.de(contexte);
    final bool deuxColonnes = !type.estTelephone && montrerCarrousel;

    if (deuxColonnes) {
      return Scaffold(
        backgroundColor: couleurs.fond,
        body: Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(Mesures.marge),
                child: const CarrouselRepas(hauteur: double.infinity),
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                children: <Widget>[
                  const FiligraneVatel(taille: 360),
                  SafeArea(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: enfant,
                            ),
                          ),
                        ),
                        if (basDePage != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: basDePage!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: barre,
      body: Stack(
        children: <Widget>[
          const FiligraneVatel(taille: 320),
          SafeArea(
            child: Column(
              children: <Widget>[
                if (montrerCarrousel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Mesures.marge,
                      Mesures.marge,
                      Mesures.marge,
                      0,
                    ),
                    child: const CarrouselRepas(hauteur: 190),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: enfant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: basDePage,
    );
  }
}
