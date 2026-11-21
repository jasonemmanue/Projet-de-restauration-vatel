// Role du fichier : commander pour un jour, une semaine ou un mois.
// Le convive choisit ses plats par service, voit le total et le solde après, puis confirme.
// La confirmation porte une clé de geste : renvoyée deux fois, elle ne compte qu une fois.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../menus/donnees/modeles_menu.dart';
import '../menus/donnees/service_menus.dart';
import '../menus/ecran_menu.dart';
import '../porte_monnaie/donnees/service_porte_monnaie.dart';
import 'donnees/service_commandes.dart';

/// L écran de commande.
class EcranCommande extends ConsumerStatefulWidget {
  /// Construit l écran de commande.
  const EcranCommande({super.key});

  @override
  ConsumerState<EcranCommande> createState() => _EtatEcranCommande();
}

class _EtatEcranCommande extends ConsumerState<EcranCommande> {
  Portee _portee = Portee.jour;
  final Map<String, Map<Service, Plat>> _choix = <String, Map<Service, Plat>>{};
  bool _enCours = false;
  String? _erreur;
  bool _reussi = false;

  String _cle(DateTime jour) => jour.toIso8601String().split('T').first;

  List<MenuDuJour> _joursOuverts(SemaineMenu semaine) {
    final DateTime aujourdhui = DateTime.now();
    final List<MenuDuJour> ouverts = semaine.jours
        .where((MenuDuJour menu) =>
            menu.estPublie &&
            !menu.date.isBefore(DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day)))
        .toList(growable: false);
    if (_portee == Portee.jour) {
      return ouverts.take(1).toList(growable: false);
    }
    return ouverts;
  }

  int _total(List<MenuDuJour> jours) {
    int total = 0;
    for (final MenuDuJour menu in jours) {
      final Map<Service, Plat>? duJour = _choix[_cle(menu.date)];
      if (duJour != null && duJour.isNotEmpty) {
        total += menu.prixXof;
      }
    }
    return total;
  }

  int _joursChoisis(List<MenuDuJour> jours) => jours
      .where((MenuDuJour menu) => (_choix[_cle(menu.date)] ?? <Service, Plat>{}).isNotEmpty)
      .length;

  Future<void> _confirmer(List<MenuDuJour> jours) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final List<ChoixJour> commande = <ChoixJour>[];
    for (final MenuDuJour menu in jours) {
      final Map<Service, Plat> duJour = _choix[_cle(menu.date)] ?? <Service, Plat>{};
      if (duJour.isEmpty) {
        continue;
      }
      commande.add(
        ChoixJour(
          date: menu.date,
          plats: duJour.values.map((Plat plat) => ChoixPlat(plat: plat)).toList(growable: false),
        ),
      );
    }
    try {
      await ref.read(serviceCommandesProvider).commander(
            portee: _portee,
            debut: jours.first.date,
            jours: commande,
          );
      Haptique.succes();
      if (mounted) {
        setState(() => _reussi = true);
        ref.invalidate(mesCommandesProvider);
        ref.invalidate(soldeProvider);
      }
    } on ErreurApi catch (echec) {
      Haptique.refus();
      if (mounted) {
        setState(() => _erreur =
            echec.message.isEmpty ? Traductions.of(context).erreurReseau : echec.message);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<SemaineMenu> semaine = ref.watch(semaineProvider);
    final AsyncValue<int?> solde = ref.watch(soldeProvider);
    final bool enLigne = ref.watch(etatReseauProvider);

    if (semaine.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: const <Widget>[
          Squelette(hauteur: 44),
          SizedBox(height: 16),
          CarteSquelette(hauteur: 150),
        ],
      );
    }

    final SemaineMenu donnees = semaine.value ??
        SemaineMenu(jours: const <MenuDuJour>[], depuisCache: false, majLe: DateTime.now());
    final List<MenuDuJour> jours = _joursOuverts(donnees);
    final int total = _total(jours);
    final int? soldeConnu = solde.value;
    final int? apres = soldeConnu == null ? null : soldeConnu - total;
    final bool insuffisant = apres != null && apres < 0;

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.commandeTitre, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 14),
          TexteAdapte(mots.choisirPortee, style: Theme.of(contexte).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final Portee portee in Portee.values)
                ChoiceChip(
                  label: Text(_libellePortee(mots, portee)),
                  selected: _portee == portee,
                  onSelected: (_) {
                    Haptique.leger();
                    setState(() => _portee = portee);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          for (final MenuDuJour menu in jours) ...<Widget>[
            _CarteJour(
              menu: menu,
              choix: _choix[_cle(menu.date)] ?? <Service, Plat>{},
              onChoix: (Service service, Plat plat) {
                setState(() {
                  final Map<Service, Plat> duJour =
                      Map<Service, Plat>.from(_choix[_cle(menu.date)] ?? <Service, Plat>{});
                  if (duJour[service]?.id == plat.id) {
                    duJour.remove(service);
                  } else {
                    duJour[service] = plat;
                  }
                  _choix[_cle(menu.date)] = duJour;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 140),
        ],
      ),
      bottomNavigationBar: Container(
        color: couleurs.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(Mesures.marge, 12, Mesures.marge, 0),
              child: Column(
                children: <Widget>[
                  if (_erreur != null)
                    TexteAdapte(
                      _erreur!,
                      maxLignes: 3,
                      style: Theme.of(contexte)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: couleurs.danger),
                    ),
                  if (_reussi)
                    TexteAdapte(
                      mots.commandeEnregistree,
                      style: Theme.of(contexte)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: couleurs.succes),
                    ),
                  _LigneRecap(
                    titre: mots.joursChoisis(_joursChoisis(jours)),
                    valeur: formaterXof(total),
                    gras: true,
                  ),
                  _LigneRecap(
                    titre: mots.soldeApres,
                    valeur: apres == null ? '—' : formaterXof(apres),
                    couleur: insuffisant ? couleurs.danger : null,
                  ),
                ],
              ),
            ),
            BoutonPrincipal(
              libelle: mots.confirmerCommande,
              enCours: _enCours,
              onPressed: total > 0 && !insuffisant && !_reussi && enLigne
                  ? () => _confirmer(jours)
                  : null,
              raisonIndisponible: !enLigne
                  ? mots.actionImpossibleHorsLigne
                  : (insuffisant ? mots.soldeInsuffisant : null),
            ),
          ],
        ),
      ),
    );
  }

  String _libellePortee(Traductions mots, Portee portee) => switch (portee) {
        Portee.jour => mots.porteeJour,
        Portee.semaine => mots.porteeSemaine,
        Portee.mois => mots.porteeMois,
      };
}

class _CarteJour extends StatelessWidget {
  const _CarteJour({required this.menu, required this.choix, required this.onChoix});

  final MenuDuJour menu;
  final Map<Service, Plat> choix;
  final void Function(Service, Plat) onChoix;

  @override
  Widget build(BuildContext contexte) {
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
                  '${nomDuJour(mots, menu.date)} ${menu.date.day}',
                  style: Theme.of(contexte).textTheme.titleLarge,
                ),
              ),
              TexteAdapte(
                formaterXof(menu.prixXof),
                style: Theme.of(contexte).textTheme.titleMedium?.copyWith(color: couleurs.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final Service service in Service.values)
            if (menu.parService(service).isNotEmpty) ...<Widget>[
              TexteAdapte(
                _titre(mots, service),
                style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                      color: couleurs.texteSecondaire,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  for (final Plat plat in menu.parService(service))
                    ChoiceChip(
                      label: Text(plat.nom),
                      selected: choix[service]?.id == plat.id,
                      onSelected: (_) {
                        Haptique.leger();
                        onChoix(service, plat);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          if (choix.isEmpty)
            TexteAdapte(
              mots.rienChoisiCeJour,
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  String _titre(Traductions mots, Service service) => switch (service) {
        Service.entree => mots.serviceEntree,
        Service.resistance => mots.serviceResistance,
        Service.sortie => mots.serviceSortie,
      };
}

class _LigneRecap extends StatelessWidget {
  const _LigneRecap({required this.titre, required this.valeur, this.gras = false, this.couleur});

  final String titre;
  final String valeur;
  final bool gras;
  final Color? couleur;

  @override
  Widget build(BuildContext contexte) {
    final TextStyle? style = gras
        ? Theme.of(contexte).textTheme.titleLarge
        : Theme.of(contexte).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: TexteAdapte(titre, style: style?.copyWith(color: couleur))),
          TexteAdapte(valeur, style: style?.copyWith(color: couleur)),
        ],
      ),
    );
  }
}
