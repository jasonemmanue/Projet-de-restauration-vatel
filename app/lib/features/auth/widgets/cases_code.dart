// Role du fichier : les cases du code de vérification, six pour un numéro, cinq pour un e-mail.
// Le code peut être posé d un coup, ce qui sert au mode démo où l API le renvoie.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/type_ecran.dart';
import '../../../core/theme/couleurs.dart';

/// Une rangée de cases, une par caractère du code.
class CasesCode extends StatefulWidget {
  /// Construit les cases.
  const CasesCode({
    required this.longueur,
    required this.onChange,
    super.key,
    this.valeurInitiale = '',
    this.enLettres = false,
  });

  /// Nombre de cases.
  final int longueur;

  /// Appelé à chaque changement, avec le code complet saisi.
  final ValueChanged<String> onChange;

  /// Code posé dès l ouverture, utilisé par le mode démo.
  final String valeurInitiale;

  /// Vrai pour un code en majuscules et chiffres, faux pour des chiffres seuls.
  final bool enLettres;

  @override
  State<CasesCode> createState() => _EtatCasesCode();
}

class _EtatCasesCode extends State<CasesCode> {
  late final List<TextEditingController> _controleurs;
  late final List<FocusNode> _focus;

  @override
  void initState() {
    super.initState();
    _controleurs = List<TextEditingController>.generate(
      widget.longueur,
      (int index) => TextEditingController(
        text: index < widget.valeurInitiale.length ? widget.valeurInitiale[index] : '',
      ),
    );
    _focus = List<FocusNode>.generate(widget.longueur, (_) => FocusNode());
    if (widget.valeurInitiale.isNotEmpty) {
      // Le code de démo est posé d un coup : on prévient l écran dès le premier rendu.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChange(_valeur));
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controleur in _controleurs) {
      controleur.dispose();
    }
    for (final FocusNode noeud in _focus) {
      noeud.dispose();
    }
    super.dispose();
  }

  String get _valeur => _controleurs.map((TextEditingController c) => c.text).join();

  void _surFrappe(int index, String valeur) {
    if (valeur.length > 1) {
      // Un collage remplit toutes les cases d un coup.
      final String colle = widget.enLettres ? valeur.toUpperCase() : valeur;
      for (int i = 0; i < widget.longueur; i++) {
        _controleurs[i].text = i < colle.length ? colle[i] : '';
      }
      _focus[widget.longueur - 1].requestFocus();
    } else if (valeur.isNotEmpty && index < widget.longueur - 1) {
      _focus[index + 1].requestFocus();
    } else if (valeur.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    setState(() {});
    widget.onChange(_valeur);
  }

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(widget.longueur, (int index) {
        final bool remplie = _controleurs[index].text.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 48,
            height: 58,
            child: TextField(
              controller: _controleurs[index],
              focusNode: _focus[index],
              textAlign: TextAlign.center,
              keyboardType: widget.enLettres ? TextInputType.text : TextInputType.number,
              textCapitalization:
                  widget.enLettres ? TextCapitalization.characters : TextCapitalization.none,
              inputFormatters: <TextInputFormatter>[
                if (!widget.enLettres) FilteringTextInputFormatter.digitsOnly,
                if (widget.enLettres) UpperCaseFormatter(),
              ],
              maxLength: 1,
              style: Theme.of(contexte).textTheme.headlineMedium,
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: remplie ? couleurs.accentDoux : couleurs.champ,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                  borderSide: BorderSide(color: remplie ? couleurs.accent : couleurs.filet),
                ),
              ),
              onChanged: (String valeur) => _surFrappe(index, valeur),
            ),
          ),
        );
      }),
    );
  }
}

/// Met en majuscules ce qui est tapé, pour les codes envoyés par e-mail.
class UpperCaseFormatter extends TextInputFormatter {
  /// Construit le formateur.
  UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue avant, TextEditingValue apres) =>
      apres.copyWith(text: apres.text.toUpperCase());
}
