// Role du fichier : la gestion des menus de la semaine, côté back office.
// Créer le menu d un jour, y poser des plats pris au catalogue, puis le publier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/feuille_bas.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../menus/donnees/modeles_menu.dart';
import '../menus/ecran_menu.dart';
import 'donnees/service_admin.dart';

/// La gestion des menus et de leur publication.
class EcranMenusAdmin extends ConsumerWidget {
  /// Construit la gestion des menus.
  const EcranMenusAdmin({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final EtatAdmin etat = ref.watch(adminProvider);
    final DateTime aujourdhui = DateTime.now();
    final DateTime demain = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day + 1);
    final bool demainExiste = etat.menus.any(
      (MenuDuJour menu) =>
          menu.date.year == demain.year &&
          menu.date.month == demain.month &&
          menu.date.day == demain.day,
    );

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        TexteAdapte(mots.menusTitre, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 14),
        if (!demainExiste)
          SizedBox(
            height: Mesures.hauteurBouton,
            child: FilledButton.icon(
              onPressed: () {
                Haptique.leger();
                ref.read(adminProvider.notifier).creerMenu(demain, etat.tarifs.first.prixXof);
              },
              icon: const Icon(Icons.add),
              label: Text('${mots.creerMenuJour} : ${nomDuJour(mots, demain)} ${demain.day}'),
            ),
          ),
        const SizedBox(height: 16),
        for (final MenuDuJour menu in etat.menus) ...<Widget>[
          _CarteMenu(menu: menu, catalogue: etat.plats),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CarteMenu extends ConsumerWidget {
  const _CarteMenu({required this.menu, required this.catalogue});

  final MenuDuJour menu;
  final List<Plat> catalogue;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool publie = menu.estPublie;

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
                  '${nomDuJour(mots, menu.date)} ${menu.date.day}',
                  style: Theme.of(contexte).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: publie ? couleurs.accentDoux : couleurs.muet,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TexteAdapte(
                  publie ? mots.etatPublie : mots.etatBrouillon,
                  style: Theme.of(contexte).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TexteAdapte(
            '${formaterXof(menu.prixXof)} · ${mots.heureLimiteLe(menu.heureLimite ?? '11:00')}',
            style: Theme.of(contexte).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TexteAdapte(mots.platsDuMenu, style: Theme.of(contexte).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (menu.plats.isEmpty)
            TexteAdapte(mots.aucunPlatAuMenu, style: Theme.of(contexte).textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final Plat plat in menu.plats)
                  Chip(
                    label: Text(plat.nom),
                    onDeleted: () =>
                        ref.read(adminProvider.notifier).basculerPlatDuMenu(menu.date, plat),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirCatalogue(contexte, ref),
                  icon: const Icon(Icons.add),
                  label: Text(mots.catalogue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: publie || menu.plats.isEmpty
                      ? null
                      : () {
                          Haptique.succes();
                          ref.read(adminProvider.notifier).publier(menu.date);
                        },
                  child: Text(mots.publierMenu),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirCatalogue(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.catalogue,
      contenu: (BuildContext contexteFeuille) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Plat plat in catalogue)
            CheckboxListTile(
              value: menu.plats.any((Plat deja) => deja.id == plat.id),
              onChanged: (_) {
                ref.read(adminProvider.notifier).basculerPlatDuMenu(menu.date, plat);
                Navigator.of(contexteFeuille).pop();
              },
              title: TexteAdapte(plat.nom),
              subtitle: TexteAdapte(
                plat.service.name,
                style: Theme.of(contexte).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
