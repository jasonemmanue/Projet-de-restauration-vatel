// Role du fichier : le mode visiteur. On regarde le menu de la semaine, on ne commande pas.
// Aucun compte, aucun jeton, aucune donnee gardee : juste la vitrine de la cantine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/carrousel_repas.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/modeles_menu.dart';
import 'donnees/service_menus.dart';
import 'ecran_menu.dart';
import 'widgets/carte_plat.dart';

/// La vitrine, sans compte.
class EcranVisiteur extends ConsumerWidget {
  /// Construit le mode visiteur.
  const EcranVisiteur({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<SemaineMenu> semaine = ref.watch(semaineProvider);

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(
        leading: BackButton(onPressed: () => contexte.go(Chemins.bienvenue)),
        title: TexteAdapte(
          mots.modeVisiteur,
          style: Theme.of(contexte).textTheme.headlineMedium,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(Mesures.marge, 0, Mesures.marge, Mesures.marge),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: Mesures.hauteurBouton,
            child: FilledButton(
              onPressed: () => contexte.go(Chemins.inscription),
              child: Text(mots.creerCompte),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleurs.accentDoux,
              borderRadius: BorderRadius.circular(Mesures.rayonPetit),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.visibility_outlined, size: 18, color: couleurs.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: TexteAdapte(
                    mots.visiteurBandeau,
                    maxLignes: 2,
                    style: Theme.of(contexte).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CarrouselRepas(hauteur: 180),
          const SizedBox(height: 18),
          TexteAdapte(mots.semaineTitre, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 12),
          semaine.when(
            loading: () => const Column(
              children: <Widget>[CarteSquelette(hauteur: 200), SizedBox(height: 12), CarteSquelette(hauteur: 200)],
            ),
            error: (Object _, StackTrace _) => EtatVide(titre: mots.aucunMenu),
            data: (SemaineMenu donnees) {
              if (donnees.jours.isEmpty) {
                return EtatVide(titre: mots.aucunMenu, icone: Icons.restaurant_menu_outlined);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final MenuDuJour menu in donnees.jours) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TexteAdapte(
                            '${nomDuJour(mots, menu.date)} ${menu.date.day}',
                            style: Theme.of(contexte).textTheme.headlineMedium,
                          ),
                        ),
                        TexteAdapte(
                          formaterXof(menu.prixXof),
                          style: Theme.of(contexte)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: couleurs.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final Plat plat in menu.plats) ...<Widget>[
                      CartePlat(
                        plat: plat,
                        allergiesDuConvive: const <String>[],
                        hauteurPhoto: 120,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
