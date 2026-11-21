// Role du fichier : la feuille du bas commune, avec sa poignee.
// La charte prefere les feuilles du bas aux boites de dialogue : tout choix passe par ici.

import 'package:flutter/material.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import 'texte_adapte.dart';

/// Ouvre une feuille du bas commune et rend ce que l utilisateur a choisi.
Future<T?> ouvrirFeuilleBas<T>({
  required BuildContext contexte,
  required String titre,
  required WidgetBuilder contenu,
}) {
  return showModalBottomSheet<T>(
    context: contexte,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: contexte.couleurs.surface,
    builder: (BuildContext contexteFeuille) => FeuilleBas(titre: titre, enfant: contenu(contexteFeuille)),
  );
}

/// Le contenu d une feuille du bas : poignee, titre, puis le corps.
class FeuilleBas extends StatelessWidget {
  /// Construit une feuille du bas.
  const FeuilleBas({required this.titre, required this.enfant, super.key});

  /// Titre de la feuille, deja traduit.
  final String titre;

  /// Le corps de la feuille.
  final Widget enfant;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: Mesures.marge,
          right: Mesures.marge,
          bottom: MediaQuery.viewInsetsOf(contexte).bottom + Mesures.marge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: couleurs.filet,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TexteAdapte(titre, style: Theme.of(contexte).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Flexible(child: SingleChildScrollView(child: enfant)),
          ],
        ),
      ),
    );
  }
}
