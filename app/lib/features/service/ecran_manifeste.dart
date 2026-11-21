// Role du fichier : la liste du service du jour, côté agent.
// Elle est téléchargée puis gardée : c est elle qui juge les scans quand le réseau manque.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/hors_ligne/file_envoi.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_agent.dart';

/// La liste des convives attendus aujourd hui.
class EcranManifeste extends ConsumerWidget {
  /// Construit le manifeste.
  const EcranManifeste({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<List<TicketDuJour>> liste = ref.watch(listeDuJourProvider);
    final bool enLigne = ref.watch(etatReseauProvider);
    final int enAttente = ref.watch(fileEnvoiProvider).length;

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        TexteAdapte(mots.ongletManifeste, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 10),
        if (!enLigne)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleurs.alerte,
              borderRadius: BorderRadius.circular(Mesures.rayonPetit),
            ),
            child: TexteAdapte(
              mots.scansAEnvoyer(enAttente),
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyLarge?.copyWith(color: couleurs.contraste),
            ),
          ),
        liste.when(
          loading: () => const Column(
            children: <Widget>[CarteSquelette(hauteur: 72), SizedBox(height: 10), CarteSquelette(hauteur: 72)],
          ),
          error: (Object _, StackTrace _) => EtatVide(titre: mots.aucuneCommande),
          data: (List<TicketDuJour> tickets) {
            if (tickets.isEmpty) {
              return EtatVide(titre: mots.aucuneCommande, icone: Icons.checklist_outlined);
            }
            final int servis = tickets.where((TicketDuJour t) => t.etat == 'servie').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: _Compteur(titre: mots.attendus, valeur: tickets.length)),
                    const SizedBox(width: 10),
                    Expanded(child: _Compteur(titre: mots.servis, valeur: servis)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Compteur(titre: mots.restants, valeur: tickets.length - servis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final TicketDuJour ticket in tickets)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: couleurs.surface,
                      borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                      border: Border.all(color: couleurs.filet),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          ticket.etat == 'servie' ? Icons.check_circle : Icons.circle_outlined,
                          size: 20,
                          color: ticket.etat == 'servie' ? couleurs.succes : couleurs.texteSecondaire,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TexteAdapte(
                                ticket.convive,
                                style: Theme.of(contexte).textTheme.titleMedium,
                              ),
                              if (ticket.plats.isNotEmpty)
                                TexteAdapte(
                                  ticket.plats.join(', '),
                                  maxLignes: 2,
                                  style: Theme.of(contexte).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({required this.titre, required this.valeur});

  final String titre;
  final int valeur;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
        border: Border.all(color: couleurs.filet),
      ),
      child: Column(
        children: <Widget>[
          TexteAdapte(
            titre,
            style: Theme.of(contexte)
                .textTheme
                .labelMedium
                ?.copyWith(color: couleurs.texteSecondaire),
          ),
          const SizedBox(height: 4),
          TexteAdapte('$valeur', style: Theme.of(contexte).textTheme.headlineMedium),
        ],
      ),
    );
  }
}
