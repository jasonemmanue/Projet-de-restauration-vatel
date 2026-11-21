// Role du fichier : le menu de la semaine, un jour à la fois.
// Les plats sont groupés par service, avec le prix du jour pour le profil du convive.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/modeles_menu.dart';
import 'donnees/service_menus.dart';
import 'widgets/carte_plat.dart';

/// Rend le nom du jour dans la langue en cours.
String nomDuJour(Traductions mots, DateTime jour) => switch (jour.weekday) {
      DateTime.monday => mots.jourLundi,
      DateTime.tuesday => mots.jourMardi,
      DateTime.wednesday => mots.jourMercredi,
      DateTime.thursday => mots.jourJeudi,
      DateTime.friday => mots.jourVendredi,
      DateTime.saturday => mots.jourSamedi,
      _ => mots.jourDimanche,
    };

/// Le menu de la semaine, côté convive.
class EcranMenu extends ConsumerStatefulWidget {
  /// Construit l écran du menu.
  const EcranMenu({super.key});

  @override
  ConsumerState<EcranMenu> createState() => _EtatEcranMenu();
}

class _EtatEcranMenu extends ConsumerState<EcranMenu> {
  DateTime? _jourChoisi;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final AsyncValue<SemaineMenu> semaine = ref.watch(semaineProvider);

    return semaine.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.semaineTitre, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 18),
          const Squelette(hauteur: 44),
          const SizedBox(height: 18),
          const CarteSquelette(hauteur: 220),
          const SizedBox(height: 14),
          const CarteSquelette(hauteur: 220),
        ],
      ),
      error: (Object echec, _) => EtatErreur(
        erreur: echec is ErreurApi
            ? echec
            : const ErreurApi(code: ErreurApi.codeServeur, message: ''),
        onReessayer: () => ref.invalidate(semaineProvider),
      ),
      data: (SemaineMenu donnees) => _contenu(contexte, mots, donnees),
    );
  }

  Widget _contenu(BuildContext contexte, Traductions mots, SemaineMenu semaine) {
    if (semaine.jours.isEmpty) {
      return EtatVide(titre: mots.aucunMenu, icone: Icons.restaurant_menu_outlined);
    }
    final DateTime jour = _jourChoisi ?? _jourParDefaut(semaine);
    final MenuDuJour? menu = semaine.pourLeJour(jour);
    final List<String> allergies = ref.watch(allergiesProvider);
    final Palette couleurs = contexte.couleurs;

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        TexteAdapte(mots.semaineTitre, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 14),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: semaine.jours.length,
            separatorBuilder: (BuildContext _, int _) => const SizedBox(width: 8),
            itemBuilder: (BuildContext contexte, int index) {
              final MenuDuJour duJour = semaine.jours[index];
              final bool actif = memeJour(duJour.date, jour);
              return GestureDetector(
                onTap: () {
                  Haptique.leger();
                  setState(() => _jourChoisi = duJour.date);
                },
                child: AnimatedContainer(
                  duration: Mesures.transition,
                  width: 92,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: actif ? couleurs.accent : couleurs.surface,
                    borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                    border: Border.all(color: actif ? couleurs.accent : couleurs.filet),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TexteAdapte(
                        nomDuJour(mots, duJour.date),
                        style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                              color: actif ? couleurs.surAccent : couleurs.texteSecondaire,
                            ),
                      ),
                      const SizedBox(height: 4),
                      TexteAdapte(
                        '${duJour.date.day}',
                        style: Theme.of(contexte).textTheme.titleLarge?.copyWith(
                              color: actif ? couleurs.surAccent : couleurs.texte,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (menu == null)
          EtatVide(titre: mots.aucunMenu, icone: Icons.restaurant_menu_outlined)
        else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: couleurs.accentDoux,
              borderRadius: BorderRadius.circular(Mesures.rayonPetit),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TexteAdapte(
                    mots.prixDuJour,
                    style: Theme.of(contexte).textTheme.titleMedium,
                  ),
                ),
                TexteAdapte(
                  formaterXof(menu.prixXof),
                  style: Theme.of(contexte).textTheme.titleLarge?.copyWith(color: couleurs.accent),
                ),
              ],
            ),
          ),
          if (menu.heureLimite != null) ...<Widget>[
            const SizedBox(height: 8),
            TexteAdapte(
              mots.heureLimiteLe(menu.heureLimite!),
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 18),
          for (final Service service in Service.values) ...<Widget>[
            if (menu.parService(service).isNotEmpty) ...<Widget>[
              TexteAdapte(
                _titreService(mots, service),
                style: Theme.of(contexte).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              for (final Plat plat in menu.parService(service)) ...<Widget>[
                CartePlat(
                  plat: plat,
                  allergiesDuConvive: allergies,
                  onTap: () => contexte.go(Chemins.fichePlat, extra: plat),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 10),
            ],
          ],
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  DateTime _jourParDefaut(SemaineMenu semaine) {
    final DateTime aujourdhui = DateTime.now();
    for (final MenuDuJour menu in semaine.jours) {
      if (memeJour(menu.date, aujourdhui) || menu.date.isAfter(aujourdhui)) {
        return menu.date;
      }
    }
    return semaine.jours.first.date;
  }

  String _titreService(Traductions mots, Service service) => switch (service) {
        Service.entree => mots.serviceEntree,
        Service.resistance => mots.serviceResistance,
        Service.sortie => mots.serviceSortie,
      };
}
