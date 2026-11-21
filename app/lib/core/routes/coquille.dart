// Role du fichier : la coquille commune des espaces connectes.
// Barre en bas sur telephone, rail lateral sur tablette, menu fixe sur ordinateur.
// Chaque onglet garde sa pile et son defilement ; toucher l onglet actif remonte en haut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../outils/haptique.dart';
import '../outils/plein_ecran.dart';
import '../responsive/type_ecran.dart';
import '../theme/couleurs.dart';

/// Un onglet de la barre de navigation.
class DestinationOnglet {
  /// Construit un onglet.
  const DestinationOnglet({required this.libelle, required this.icone, required this.iconeActive});

  /// Libelle, toujours visible, deja traduit.
  final String libelle;

  /// Icone de l onglet au repos.
  final IconData icone;

  /// Icone de l onglet actif.
  final IconData iconeActive;
}

/// Compte les demandes de remontee en haut, une par toucher sur l onglet actif.
class RemonteeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Demande aux ecrans visibles de remonter en haut.
  void demander() => state = state + 1;
}

/// Le compteur de demandes de remontee en haut.
final NotifierProvider<RemonteeNotifier, int> remonteeProvider =
    NotifierProvider<RemonteeNotifier, int>(RemonteeNotifier.new);

/// Vrai tant que les paiements tournent en mode test.
final NotifierProvider<ModeTestNotifier, bool> modeTestProvider =
    NotifierProvider<ModeTestNotifier, bool>(ModeTestNotifier.new);

/// Tient le mode de paiement annonce par l API.
class ModeTestNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  /// Pose le mode annonce par l API.
  void poser({required bool test}) => state = test;
}

/// La coquille d un espace : barre de navigation, bandeau hors ligne et contenu.
class Coquille extends ConsumerWidget {
  /// Construit la coquille autour de la pile d onglets.
  const Coquille({
    required this.shell,
    required this.destinations,
    required this.titre,
    super.key,
  });

  /// La pile d onglets de GoRouter, qui garde chaque branche vivante.
  final StatefulNavigationShell shell;

  /// Les onglets de l espace, quatre au plus.
  final List<DestinationOnglet> destinations;

  /// Le titre de l espace, deja traduit.
  final String titre;

  void _allerVers(WidgetRef ref, int index) {
    final bool dejaActif = index == shell.currentIndex;
    Haptique.leger();
    if (dejaActif) {
      // Toucher l onglet actif : on revient a la racine de la branche et on remonte en haut.
      shell.goBranch(index, initialLocation: true);
      ref.read(remonteeProvider.notifier).demander();
      return;
    }
    shell.goBranch(index);
  }

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final TypeEcran type = TypeEcran.de(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool modeTest = ref.watch(modeTestProvider);

    final Widget contenu = Column(
      children: <Widget>[
        const BandeauHorsLigne(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Mesures.largeurContenu),
              child: shell,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(
        title: TexteAdapte(titre, style: Theme.of(contexte).textTheme.headlineMedium),
        actions: <Widget>[
          if (modeTest) const BadgeModeTest(),
          IconButton(
            tooltip: Traductions.of(contexte).pleinEcran,
            onPressed: () => PleinEcran.basculer(),
            icon: const Icon(Icons.fullscreen),
          ),
        ],
      ),
      body: switch (type) {
        TypeEcran.telephone => contenu,
        TypeEcran.tablette => Row(
            children: <Widget>[
              _RailLateral(
                destinations: destinations,
                indexActif: shell.currentIndex,
                onChoisi: (int index) => _allerVers(ref, index),
              ),
              Expanded(child: contenu),
            ],
          ),
        TypeEcran.ordinateur => Row(
            children: <Widget>[
              _MenuFixe(
                destinations: destinations,
                indexActif: shell.currentIndex,
                onChoisi: (int index) => _allerVers(ref, index),
              ),
              Expanded(child: contenu),
            ],
          ),
      },
      bottomNavigationBar: type.estTelephone
          ? NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (int index) => _allerVers(ref, index),
              destinations: destinations
                  .map(
                    (DestinationOnglet onglet) => NavigationDestination(
                      icon: Icon(onglet.icone),
                      selectedIcon: Icon(onglet.iconeActive),
                      label: onglet.libelle,
                      tooltip: onglet.libelle,
                    ),
                  )
                  .toList(growable: false),
            )
          : null,
    );
  }
}

class _RailLateral extends StatelessWidget {
  const _RailLateral({
    required this.destinations,
    required this.indexActif,
    required this.onChoisi,
  });

  final List<DestinationOnglet> destinations;
  final int indexActif;
  final ValueChanged<int> onChoisi;

  @override
  Widget build(BuildContext contexte) {
    return NavigationRail(
      selectedIndex: indexActif,
      onDestinationSelected: onChoisi,
      labelType: NavigationRailLabelType.all,
      minWidth: 84,
      destinations: destinations
          .map(
            (DestinationOnglet onglet) => NavigationRailDestination(
              icon: Icon(onglet.icone),
              selectedIcon: Icon(onglet.iconeActive),
              label: Text(onglet.libelle),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MenuFixe extends StatelessWidget {
  const _MenuFixe({
    required this.destinations,
    required this.indexActif,
    required this.onChoisi,
  });

  final List<DestinationOnglet> destinations;
  final int indexActif;
  final ValueChanged<int> onChoisi;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    return Container(
      width: 248,
      color: couleurs.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          children: <Widget>[
            for (int index = 0; index < destinations.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: index == indexActif ? couleurs.accentDoux : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                    onTap: () => onChoisi(index),
                    child: Container(
                      height: Mesures.cibleTactile,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            index == indexActif
                                ? destinations[index].iconeActive
                                : destinations[index].icone,
                            size: 22,
                            color: index == indexActif ? couleurs.accent : couleurs.texteSecondaire,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TexteAdapte(
                              destinations[index].libelle,
                              style: Theme.of(contexte).textTheme.titleMedium?.copyWith(
                                    color: index == indexActif ? couleurs.accent : couleurs.texte,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
