// Role du fichier : le bouton principal commun, colle en bas de l ecran, a portee du pouce.
// Il sait se griser avec sa raison, ce qui sert a toutes les actions interdites hors ligne.

import 'package:flutter/material.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import 'texte_adapte.dart';

/// Un bouton principal en pilule, pose en bas de l ecran, au dessus de la zone sure.
class BoutonPrincipal extends StatelessWidget {
  /// Construit le bouton principal.
  const BoutonPrincipal({
    required this.libelle,
    required this.onPressed,
    super.key,
    this.raisonIndisponible,
    this.enCours = false,
    this.icone,
  });

  /// Le libelle, deja traduit.
  final String libelle;

  /// L action a lancer. Vide, le bouton est grise.
  final VoidCallback? onPressed;

  /// Pourquoi le bouton est grise, montre juste au dessus.
  final String? raisonIndisponible;

  /// Vrai pendant le travail : le bouton montre un indicateur.
  final bool enCours;

  /// Une icone optionnelle, dessinee, jamais un emoji.
  final IconData? icone;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final bool actif = onPressed != null && !enCours;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        Mesures.marge,
        0,
        Mesures.marge,
        Mesures.marge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (raisonIndisponible != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TexteAdapte(
                raisonIndisponible!,
                maxLignes: 3,
                alignement: TextAlign.center,
                style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.alerte),
              ),
            ),
          ],
          SizedBox(
            height: Mesures.hauteurBouton,
            child: FilledButton(
              onPressed: actif ? onPressed : null,
              child: enCours
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: couleurs.surAccent,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icone != null) ...<Widget>[
                          Icon(icone, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: TexteAdapte(
                            libelle,
                            alignement: TextAlign.center,
                            style: Theme.of(contexte).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
