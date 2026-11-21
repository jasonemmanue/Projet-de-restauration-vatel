// Role du fichier : le champ de mot de passe et ses trois règles, cochées en direct.
// Le serveur reste juge : ces règles guident la saisie, elles ne la valident pas à sa place.

import 'package:flutter/material.dart';

import '../../../core/theme/couleurs.dart';
import '../../../l10n/traductions.dart';
import '../../../shared/widgets/texte_adapte.dart';

/// Les trois règles affichées sous le champ.
class ReglesMotDePasse {
  /// Évalue les trois règles sur un mot de passe.
  const ReglesMotDePasse(this.valeur);

  /// Le mot de passe en cours de saisie.
  final String valeur;

  /// Huit caractères au moins.
  bool get assezLong => valeur.length >= 8;

  /// Au moins une lettre.
  bool get aUneLettre => RegExp('[A-Za-zÀ-ÿ]').hasMatch(valeur);

  /// Au moins un chiffre.
  bool get aUnChiffre => RegExp('[0-9]').hasMatch(valeur);

  /// Vrai quand les trois règles passent.
  bool get toutesTenues => assezLong && aUneLettre && aUnChiffre;
}

/// Un champ de mot de passe avec ses règles visibles.
class ChampMotDePasse extends StatefulWidget {
  /// Construit le champ.
  const ChampMotDePasse({
    required this.controleur,
    required this.onChange,
    super.key,
    this.libelle,
    this.montrerRegles = true,
  });

  /// Le contrôleur du champ.
  final TextEditingController controleur;

  /// Appelé à chaque frappe.
  final ValueChanged<String> onChange;

  /// Libellé du champ. Vide, c'est « Mot de passe ».
  final String? libelle;

  /// Faux pour un écran de connexion, où les règles n'ont rien à faire.
  final bool montrerRegles;

  @override
  State<ChampMotDePasse> createState() => _EtatChampMotDePasse();
}

class _EtatChampMotDePasse extends State<ChampMotDePasse> {
  bool _cache = true;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final ReglesMotDePasse regles = ReglesMotDePasse(widget.controleur.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: widget.controleur,
          obscureText: _cache,
          autofillHints: const <String>[AutofillHints.password],
          decoration: InputDecoration(
            labelText: widget.libelle ?? mots.motDePasse,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _cache = !_cache),
              icon: Icon(_cache ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              tooltip: widget.libelle ?? mots.motDePasse,
            ),
          ),
          onChanged: (String valeur) {
            setState(() {});
            widget.onChange(valeur);
          },
        ),
        if (widget.montrerRegles) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: <Widget>[
              _Regle(libelle: mots.regleHuitCaracteres, tenue: regles.assezLong),
              _Regle(libelle: mots.regleUneLettre, tenue: regles.aUneLettre),
              _Regle(libelle: mots.regleUnChiffre, tenue: regles.aUnChiffre),
            ],
          ),
        ],
      ],
    );
  }
}

class _Regle extends StatelessWidget {
  const _Regle({required this.libelle, required this.tenue});

  final String libelle;
  final bool tenue;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tenue ? couleurs.accentDoux : couleurs.muet,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            tenue ? Icons.check_circle : Icons.circle_outlined,
            size: 15,
            color: tenue ? couleurs.succes : couleurs.texteSecondaire,
          ),
          const SizedBox(width: 6),
          TexteAdapte(
            libelle,
            style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                  color: tenue ? couleurs.texte : couleurs.texteSecondaire,
                ),
          ),
        ],
      ),
    );
  }
}
