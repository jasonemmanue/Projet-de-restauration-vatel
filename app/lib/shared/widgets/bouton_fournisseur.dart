// Role du fichier : les boutons de connexion Google, Apple et code QR.
// Le logo tient dans une boite carree a taille fixe, en ajustement par contenu : il ne se
// deforme jamais, quelle que soit la longueur du libelle ou la largeur de l ecran.

import 'package:flutter/material.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import 'texte_adapte.dart';

/// Cote de la boite du logo, dans un bouton de 52 de haut.
const double _coteLogo = 22;

/// Un bouton de connexion par fournisseur, en pilule, logo a gauche.
class BoutonFournisseur extends StatelessWidget {
  /// Construit un bouton de connexion avec un logo en image.
  const BoutonFournisseur({
    required this.libelle,
    required this.ressourceLogo,
    required this.onPressed,
    super.key,
  }) : icone = null;

  /// Construit un bouton de connexion avec une icone dessinee.
  const BoutonFournisseur.icone({
    required this.libelle,
    required this.icone,
    required this.onPressed,
    super.key,
  }) : ressourceLogo = null;

  /// Le libelle, deja traduit.
  final String libelle;

  /// Le fichier du logo, dans les ressources de l application.
  final String? ressourceLogo;

  /// Une icone dessinee, pour le code QR.
  final IconData? icone;

  /// L action du bouton. Vide, le bouton est grise.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return SizedBox(
      height: Mesures.hauteurBouton,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: couleurs.surface,
          foregroundColor: couleurs.texte,
          side: BorderSide(color: couleurs.filet),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: _coteLogo,
              height: _coteLogo,
              child: ressourceLogo != null
                  ? Image.asset(ressourceLogo!, fit: BoxFit.contain, filterQuality: FilterQuality.high)
                  : Icon(icone, size: _coteLogo, color: couleurs.texte),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: TexteAdapte(
                libelle,
                alignement: TextAlign.center,
                style: Theme.of(contexte).textTheme.labelLarge,
              ),
            ),
            // Une boite vide de la largeur du logo garde le libelle optiquement centre.
            const SizedBox(width: _coteLogo + 12),
          ],
        ),
      ),
    );
  }
}
