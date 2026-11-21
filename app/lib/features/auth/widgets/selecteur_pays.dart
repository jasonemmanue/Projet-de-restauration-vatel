// Role du fichier : le choix du pays et de son indicatif, au dessus du champ de numero.
// Pas d emoji de drapeau : la charte les interdit, et leur rendu change d un telephone a l autre.
// Un pastille aux initiales du pays tient ce role, et reste lisible partout.

import 'package:flutter/material.dart';

import '../../../core/responsive/type_ecran.dart';
import '../../../core/theme/couleurs.dart';
import '../../../shared/widgets/texte_adapte.dart';

/// Un pays et son indicatif telephonique.
class Pays {
  /// Construit un pays.
  const Pays({
    required this.code,
    required this.nom,
    required this.indicatif,
    required this.longueur,
    this.aide = '',
  });

  /// Code a deux lettres, montre dans la pastille.
  final String code;

  /// Nom du pays, affiche.
  final String nom;

  /// Indicatif, avec le plus.
  final String indicatif;

  /// Nombre de chiffres attendus apres l indicatif.
  final int longueur;

  /// Une ligne d aide, quand le pays en demande une.
  final String aide;
}

/// Les pays proposes. La Côte d Ivoire est en tete, c est celui de la cantine.
const List<Pays> paysConnus = <Pays>[
  Pays(code: 'CI', nom: 'Côte d’Ivoire', indicatif: '+225', longueur: 10),
  Pays(code: 'BF', nom: 'Burkina Faso', indicatif: '+226', longueur: 8),
  Pays(code: 'ML', nom: 'Mali', indicatif: '+223', longueur: 8),
  Pays(code: 'SN', nom: 'Sénégal', indicatif: '+221', longueur: 9),
  Pays(code: 'TG', nom: 'Togo', indicatif: '+228', longueur: 8),
  Pays(code: 'BJ', nom: 'Bénin', indicatif: '+229', longueur: 10),
  Pays(code: 'GN', nom: 'Guinée', indicatif: '+224', longueur: 9),
  Pays(code: 'CM', nom: 'Cameroun', indicatif: '+237', longueur: 9),
  Pays(code: 'FR', nom: 'France', indicatif: '+33', longueur: 9),
];

/// Le pays par defaut.
const Pays paysParDefaut =
    Pays(code: 'CI', nom: 'Côte d’Ivoire', indicatif: '+225', longueur: 10);

/// Laisse choisir le pays et montre son indicatif.
class SelecteurPays extends StatelessWidget {
  /// Construit le selecteur.
  const SelecteurPays({required this.pays, required this.onChange, super.key});

  /// Le pays choisi.
  final Pays pays;

  /// Appele quand l utilisateur en choisit un autre.
  final ValueChanged<Pays> onChange;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: couleurs.champ,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
        border: Border.all(color: couleurs.filet),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: pays.code,
          isExpanded: true,
          borderRadius: BorderRadius.circular(Mesures.rayonPetit),
          icon: Icon(Icons.expand_more, color: couleurs.texteSecondaire),
          dropdownColor: couleurs.surface,
          onChanged: (String? code) {
            if (code == null) {
              return;
            }
            onChange(paysConnus.firstWhere((Pays p) => p.code == code));
          },
          items: <DropdownMenuItem<String>>[
            for (final Pays choix in paysConnus)
              DropdownMenuItem<String>(
                value: choix.code,
                child: Row(
                  children: <Widget>[
                    _Pastille(code: choix.code),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TexteAdapte(
                        choix.nom,
                        style: Theme.of(contexte).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TexteAdapte(
                      '(${choix.indicatif})',
                      style: Theme.of(contexte)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: couleurs.texteSecondaire),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.code});

  final String code;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: couleurs.accentDoux,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
              color: couleurs.accent,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
