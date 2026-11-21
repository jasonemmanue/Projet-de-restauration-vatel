// Role du fichier : ce que la cuisine doit préparer aujourd hui, par service et par plat.
// L écran se rafraîchit toutes les 30 secondes, mais seulement quand il est visible et que
// l application est au premier plan : rien ne tourne dans le vide.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_tableau_bord.dart';

/// Les commandes du jour, vues de la cuisine.
class EcranCuisine extends ConsumerStatefulWidget {
  /// Construit l écran cuisine.
  const EcranCuisine({super.key});

  @override
  ConsumerState<EcranCuisine> createState() => _EtatEcranCuisine();
}

class _EtatEcranCuisine extends ConsumerState<EcranCuisine> with WidgetsBindingObserver {
  Timer? _minuteur;
  DateTime _derniereActualisation = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lancerMinuteur();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Au premier plan, on reprend le rythme ; en arrière-plan, on arrête tout.
    if (etat == AppLifecycleState.resumed) {
      _actualiser();
      _lancerMinuteur();
    } else {
      _minuteur?.cancel();
      _minuteur = null;
    }
  }

  void _lancerMinuteur() {
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 30), (_) => _actualiser());
  }

  void _actualiser() {
    if (!mounted) {
      return;
    }
    ref.invalidate(commandesDuJourProvider);
    setState(() => _derniereActualisation = DateTime.now());
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<List<LigneCuisine>> commandes = ref.watch(commandesDuJourProvider);

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TexteAdapte(
                mots.ongletCuisine,
                style: Theme.of(contexte).textTheme.headlineLarge,
              ),
            ),
            IconButton(
              onPressed: _actualiser,
              icon: const Icon(Icons.refresh),
              tooltip: mots.reessayer,
            ),
          ],
        ),
        TexteAdapte(
          mots.actualiseA(formaterHeure(_derniereActualisation)),
          style: Theme.of(contexte).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        commandes.when(
          loading: () => const Column(
            children: <Widget>[CarteSquelette(hauteur: 76), SizedBox(height: 10), CarteSquelette(hauteur: 76)],
          ),
          error: (Object _, StackTrace _) => EtatVide(titre: mots.aucuneCommande),
          data: (List<LigneCuisine> lignes) {
            if (lignes.isEmpty) {
              return EtatVide(titre: mots.aucuneCommande, icone: Icons.soup_kitchen_outlined);
            }
            final int total = lignes.fold<int>(0, (int somme, LigneCuisine l) => somme + l.parts);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(Mesures.marge),
                  decoration: BoxDecoration(
                    color: couleurs.accentDoux,
                    borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TexteAdapte(
                          mots.aPreparer,
                          style: Theme.of(contexte).textTheme.titleMedium,
                        ),
                      ),
                      TexteAdapte(
                        '$total',
                        style: Theme.of(contexte)
                            .textTheme
                            .displayLarge
                            ?.copyWith(color: couleurs.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final LigneCuisine ligne in lignes) ...<Widget>[
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TexteAdapte(
                                ligne.plat,
                                style: Theme.of(contexte).textTheme.titleMedium,
                              ),
                              TexteAdapte(
                                mots.partsServies(ligne.parts, ligne.servies),
                                style: Theme.of(contexte).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        TexteAdapte(
                          '${ligne.parts}',
                          style: Theme.of(contexte).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
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
