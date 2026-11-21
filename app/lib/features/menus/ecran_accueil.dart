// Role du fichier : l accueil du convive. Salutation, solde, repas du jour, menu du jour.
// Les données arrivent déjà chargées par l onglet : aucune carte ne repart de zéro pixel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/routes/routes.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/page_defilante.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../porte_monnaie/donnees/service_porte_monnaie.dart';
import 'donnees/modeles_menu.dart';
import 'donnees/service_menus.dart';
import 'ecran_menu.dart';
import 'widgets/carte_plat.dart';

/// L accueil de l espace convive.
class EcranAccueil extends ConsumerWidget {
  /// Construit l accueil.
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final Session? session = ref.watch(sessionProvider).value;
    final AsyncValue<SemaineMenu> semaine = ref.watch(semaineProvider);
    final AsyncValue<int?> solde = ref.watch(soldeProvider);
    final List<String> allergies = ref.watch(allergiesProvider);
    final DateTime aujourdhui = DateTime.now();
    final String prenom = session?.nomComplet.split(' ').first ?? '';

    final MenuDuJour? menu = semaine.value?.pourLeJour(aujourdhui);

    return PageDefilante(
      enfants: <Widget>[
        TexteAdapte(
          prenom.isEmpty ? mots.bonjour : '${mots.bonjour} $prenom',
          style: Theme.of(contexte).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        TexteAdapte(
          '${nomDuJour(mots, aujourdhui)} ${aujourdhui.day}',
          style: Theme.of(contexte).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),

        // Le solde, sur une surface de contraste comme dans la maquette.
        Container(
          padding: const EdgeInsets.all(Mesures.marge),
          decoration: BoxDecoration(
            color: couleurs.contraste,
            borderRadius: BorderRadius.circular(Mesures.rayonGrand),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TexteAdapte(
                mots.soldeTitre,
                style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                      color: couleurs.surContrasteAttenue,
                    ),
              ),
              const SizedBox(height: 8),
              solde.when(
                loading: () => const Squelette(hauteur: 34, largeur: 160),
                error: (Object _, StackTrace _) => TexteAdapte(
                  '—',
                  style: Theme.of(contexte).textTheme.displayLarge?.copyWith(
                        color: couleurs.surContraste,
                      ),
                ),
                data: (int? montant) => TexteAdapte(
                  montant == null ? '—' : formaterXof(montant),
                  style: Theme.of(contexte).textTheme.displayLarge?.copyWith(
                        color: couleurs.surContraste,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Le repas du jour, ou l invitation à commander.
        Container(
          padding: const EdgeInsets.all(Mesures.marge),
          decoration: BoxDecoration(
            color: couleurs.surface,
            borderRadius: BorderRadius.circular(Mesures.rayonCarte),
            border: Border.all(color: couleurs.filet),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TexteAdapte(mots.repasDuJour, style: Theme.of(contexte).textTheme.titleLarge),
              const SizedBox(height: 8),
              TexteAdapte(
                mots.aucunRepasDuJour,
                maxLignes: 2,
                style: Theme.of(contexte).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: Mesures.hauteurBouton,
                child: FilledButton(
                  onPressed: () => contexte.go('${Chemins.convive}/menu'),
                  child: Text(mots.commanderRepas),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        Row(
          children: <Widget>[
            Expanded(
              child: TexteAdapte(
                mots.menuDuJour,
                style: Theme.of(contexte).textTheme.headlineMedium,
              ),
            ),
            TextButton(
              onPressed: () => contexte.go('${Chemins.convive}/menu'),
              child: Text(mots.voirLaSemaine),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (semaine.isLoading) ...<Widget>[
          const CarteSquelette(hauteur: 220),
          const SizedBox(height: 12),
          const CarteSquelette(hauteur: 220),
        ] else if (menu == null)
          Container(
            padding: const EdgeInsets.all(Mesures.marge),
            decoration: BoxDecoration(
              color: couleurs.muet,
              borderRadius: BorderRadius.circular(Mesures.rayonCarte),
            ),
            child: TexteAdapte(
              mots.aucunMenu,
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyLarge,
            ),
          )
        else
          for (final Plat plat in menu.plats) ...<Widget>[
            CartePlat(
              plat: plat,
              allergiesDuConvive: allergies,
              onTap: () => contexte.go(Chemins.fichePlat, extra: plat),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 20),
      ],
    );
  }
}
