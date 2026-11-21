// Role du fichier : le solde et l historique des mouvements.
// Le solde n existe que par ses mouvements : l écran ne calcule rien, il montre ce que l API dit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_porte_monnaie.dart';

/// Le porte-monnaie du convive ou du parent.
class EcranPorteMonnaie extends ConsumerWidget {
  /// Construit l écran du porte-monnaie.
  const EcranPorteMonnaie({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<int?> solde = ref.watch(soldeProvider);
    final AsyncValue<List<Mouvement>> mouvements = ref.watch(mouvementsProvider);

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        TexteAdapte(mots.soldeTitre, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(Mesures.marge),
          decoration: BoxDecoration(
            color: couleurs.contraste,
            borderRadius: BorderRadius.circular(Mesures.rayonGrand),
          ),
          child: solde.when(
            loading: () => const Squelette(hauteur: 34, largeur: 160),
            error: (Object _, StackTrace _) => TexteAdapte(
              '—',
              style: Theme.of(contexte)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: couleurs.surContraste),
            ),
            data: (int? montant) => TexteAdapte(
              montant == null ? '—' : formaterXof(montant),
              style: Theme.of(contexte)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: couleurs.surContraste),
            ),
          ),
        ),
        const SizedBox(height: 22),
        TexteAdapte(mots.mouvementsTitre, style: Theme.of(contexte).textTheme.headlineMedium),
        const SizedBox(height: 10),
        mouvements.when(
          loading: () => const Column(
            children: <Widget>[CarteSquelette(hauteur: 72), SizedBox(height: 10), CarteSquelette(hauteur: 72)],
          ),
          error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
          data: (List<Mouvement> liste) {
            if (liste.isEmpty) {
              return EtatVide(titre: mots.etatVideTitre, icone: Icons.swap_vert);
            }
            return Column(
              children: <Widget>[
                for (final Mouvement mouvement in liste) ...<Widget>[
                  _LigneMouvement(mouvement: mouvement),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _LigneMouvement extends StatelessWidget {
  const _LigneMouvement({required this.mouvement});

  final Mouvement mouvement;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final bool credit = mouvement.sens == 'credit';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
        border: Border.all(color: couleurs.filet),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            credit ? Icons.south_west : Icons.north_east,
            size: 20,
            color: credit ? couleurs.succes : couleurs.texteSecondaire,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteAdapte(mouvement.motif, style: Theme.of(contexte).textTheme.titleMedium),
                const SizedBox(height: 2),
                TexteAdapte(
                  '${mouvement.date.day}/${mouvement.date.month} ${formaterHeure(mouvement.date)}',
                  style: Theme.of(contexte).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TexteAdapte(
            '${credit ? '+' : '-'}${formaterXof(mouvement.montantXof)}',
            style: Theme.of(contexte).textTheme.titleMedium?.copyWith(
                  color: credit ? couleurs.succes : couleurs.texte,
                ),
          ),
        ],
      ),
    );
  }
}
