// Role du fichier : la bascule Numéro ou E-mail, posée au dessus du seul champ d identifiant.

import 'package:flutter/material.dart';

import '../../../core/outils/haptique.dart';
import '../../../core/responsive/type_ecran.dart';
import '../../../core/theme/couleurs.dart';
import '../../../l10n/traductions.dart';
import '../../../shared/widgets/texte_adapte.dart';
import '../donnees/service_auth.dart';

/// Laisse choisir entre un numéro et une adresse e-mail.
class BasculeIdentifiant extends StatelessWidget {
  /// Construit la bascule.
  const BasculeIdentifiant({required this.canal, required this.onChange, super.key});

  /// Le canal choisi.
  final CanalIdentifiant canal;

  /// Appelé quand l utilisateur bascule.
  final ValueChanged<CanalIdentifiant> onChange;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;

    return Container(
      height: Mesures.cibleTactile,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: couleurs.muet,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          _Onglet(
            libelle: mots.identifiantNumero,
            actif: canal == CanalIdentifiant.telephone,
            onTap: () {
              Haptique.leger();
              onChange(CanalIdentifiant.telephone);
            },
          ),
          _Onglet(
            libelle: mots.identifiantEmail,
            actif: canal == CanalIdentifiant.email,
            onTap: () {
              Haptique.leger();
              onChange(CanalIdentifiant.email);
            },
          ),
        ],
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({required this.libelle, required this.actif, required this.onTap});

  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Mesures.transition,
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: actif ? couleurs.surface : const Color(0x00000000),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TexteAdapte(
            libelle,
            alignement: TextAlign.center,
            style: Theme.of(contexte).textTheme.labelLarge?.copyWith(
                  color: actif ? couleurs.texte : couleurs.texteSecondaire,
                ),
          ),
        ),
      ),
    );
  }
}
