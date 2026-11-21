// Role du fichier : les ecrans communs d etat vide, d erreur, et le bandeau hors ligne.
// Les messages de l API sont montres tels quels ; les textes de l application sont traduits.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import 'texte_adapte.dart';

/// Ce qui s affiche quand il n y a rien a montrer.
class EtatVide extends StatelessWidget {
  /// Construit un etat vide.
  const EtatVide({super.key, this.titre, this.detail, this.icone = Icons.inbox_outlined});

  /// Titre, deja traduit. Vide, le titre commun est utilise.
  final String? titre;

  /// Detail, deja traduit.
  final String? detail;

  /// Icone dessinee, jamais un emoji.
  final IconData icone;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: couleurs.muet, shape: BoxShape.circle),
              child: Icon(icone, size: 36, color: couleurs.texteSecondaire),
            ),
            const SizedBox(height: 20),
            TexteAdapte(
              titre ?? mots.etatVideTitre,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TexteAdapte(
              detail ?? mots.etatVideDetail,
              maxLignes: 3,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui s affiche quand un chargement a echoue.
class EtatErreur extends StatelessWidget {
  /// Construit un etat d erreur a partir d une erreur de l API.
  const EtatErreur({required this.erreur, required this.onReessayer, super.key});

  /// L erreur rendue par l API.
  final ErreurApi erreur;

  /// L action du bouton Reessayer.
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    // Le message de l API est montre tel quel. Sans message, on explique la panne reseau.
    final String message = erreur.message.isNotEmpty
        ? erreur.message
        : (erreur.estReseau ? mots.erreurReseau : mots.erreurTitre);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: couleurs.danger),
            const SizedBox(height: 16),
            TexteAdapte(
              mots.erreurTitre,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TexteAdapte(
              message,
              maxLignes: 4,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: Mesures.hauteurBouton,
              child: OutlinedButton(
                onPressed: onReessayer,
                child: Text(mots.reessayer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le bandeau montre en haut des ecrans quand l API est injoignable.
class BandeauHorsLigne extends ConsumerWidget {
  /// Construit le bandeau hors ligne.
  const BandeauHorsLigne({super.key, this.majLe});

  /// L heure de la derniere mise a jour du contenu affiche.
  final DateTime? majLe;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final bool enLigne = ref.watch(etatReseauProvider);
    if (enLigne) {
      return const SizedBox.shrink();
    }
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final DateTime? heure = majLe;
    final String texte = heure == null
        ? mots.bandeauHorsLigne
        : '${mots.bandeauHorsLigne} ${mots.majLe(_heureCourte(heure))}';

    return Container(
      width: double.infinity,
      color: couleurs.alerte,
      padding: const EdgeInsets.symmetric(horizontal: Mesures.marge, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, size: 18, color: couleurs.contraste),
          const SizedBox(width: 10),
          Expanded(
            child: TexteAdapte(
              texte,
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.contraste),
            ),
          ),
        ],
      ),
    );
  }

  static String _heureCourte(DateTime instant) =>
      '${instant.hour.toString().padLeft(2, '0')}:${instant.minute.toString().padLeft(2, '0')}';
}

/// La pastille Mode test, posee dans la barre du haut quand les paiements sont en test.
class BadgeModeTest extends StatelessWidget {
  /// Construit la pastille Mode test.
  const BadgeModeTest({super.key});

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Container(
      margin: const EdgeInsets.only(right: Mesures.marge),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleurs.alerte,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TexteAdapte(
        Traductions.of(contexte).modeTest,
        style: Theme.of(contexte).textTheme.labelMedium?.copyWith(color: couleurs.contraste),
      ),
    );
  }
}
