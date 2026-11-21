// Role du fichier : les commandes du convive, à venir et passées.
// Avant le gel, annuler rembourse. Après, supprimer ne rembourse pas : le libellé le dit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../menus/ecran_menu.dart';
import 'donnees/service_commandes.dart';

/// La liste des commandes du convive.
class EcranMesCommandes extends ConsumerWidget {
  /// Construit l écran.
  const EcranMesCommandes({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final AsyncValue<List<Commande>> commandes = ref.watch(mesCommandesProvider);

    return commandes.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: const <Widget>[CarteSquelette(), SizedBox(height: 12), CarteSquelette()],
      ),
      error: (Object echec, _) => EtatErreur(
        erreur: echec is ErreurApi ? echec : const ErreurApi(code: ErreurApi.codeServeur, message: ''),
        onReessayer: () => ref.invalidate(mesCommandesProvider),
      ),
      data: (List<Commande> liste) {
        if (liste.isEmpty) {
          return EtatVide(titre: mots.aucuneCommande, icone: Icons.receipt_long_outlined);
        }
        final List<Commande> aVenir = liste.where((Commande c) => c.aVenir).toList();
        final List<Commande> passees = liste.where((Commande c) => !c.aVenir).toList();
        return ListView(
          padding: const EdgeInsets.all(Mesures.marge),
          children: <Widget>[
            TexteAdapte(mots.mesCommandes, style: Theme.of(contexte).textTheme.headlineLarge),
            const SizedBox(height: 16),
            if (aVenir.isNotEmpty) ...<Widget>[
              TexteAdapte(mots.aVenir, style: Theme.of(contexte).textTheme.headlineMedium),
              const SizedBox(height: 10),
              for (final Commande commande in aVenir) ...<Widget>[
                _CarteCommande(commande: commande),
                const SizedBox(height: 12),
              ],
            ],
            if (passees.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              TexteAdapte(mots.passees, style: Theme.of(contexte).textTheme.headlineMedium),
              const SizedBox(height: 10),
              for (final Commande commande in passees) ...<Widget>[
                _CarteCommande(commande: commande),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _CarteCommande extends ConsumerWidget {
  const _CarteCommande({required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;

    return Container(
      padding: const EdgeInsets.all(Mesures.marge),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: couleurs.filet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TexteAdapte(
                  '${nomDuJour(mots, commande.date)} ${commande.date.day}',
                  style: Theme.of(contexte).textTheme.titleLarge,
                ),
              ),
              TexteAdapte(
                formaterXof(commande.totalXof),
                style: Theme.of(contexte).textTheme.titleMedium,
              ),
            ],
          ),
          if (commande.plats.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            TexteAdapte(
              commande.plats.join(', '),
              maxLignes: 3,
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
          ],
          if (commande.gelee) ...<Widget>[
            const SizedBox(height: 8),
            TexteAdapte(
              mots.commandeGeleeInfo,
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.alerte),
            ),
          ],
          if (commande.aVenir && commande.etat == 'confirmee') ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: Mesures.cibleTactile,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(serviceCommandesProvider).annuler(commande.id);
                  ref.invalidate(mesCommandesProvider);
                },
                child: Text(
                  commande.gelee ? mots.supprimerSansRemboursement : mots.annulerCommande,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
