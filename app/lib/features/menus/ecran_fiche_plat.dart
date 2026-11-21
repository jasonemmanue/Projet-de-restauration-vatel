// Role du fichier : la fiche d un plat, ouverte depuis une carte du menu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/modeles_menu.dart';
import 'donnees/service_menus.dart';
import 'widgets/carte_plat.dart';

/// La fiche détaillée d un plat.
class EcranFichePlat extends ConsumerWidget {
  /// Construit la fiche.
  const EcranFichePlat({required this.plat, super.key});

  /// Le plat montré.
  final Plat plat;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final List<String> allergies = ref.watch(allergiesProvider);
    final bool alerte = plat.contientUnDe(allergies);

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: couleurs.fond,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: PhotoPlat(plat: plat, hauteur: 260),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Mesures.marge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TexteAdapte(plat.nom, style: Theme.of(contexte).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  if (plat.description.isNotEmpty)
                    TexteAdapte(
                      plat.description,
                      maxLignes: 5,
                      style: Theme.of(contexte).textTheme.bodyLarge,
                    ),
                  if (alerte) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: couleurs.danger,
                        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TexteAdapte(
                              mots.allergeneAlerte(plat.allergenes.first),
                              maxLignes: 2,
                              style: Theme.of(contexte)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _Ligne(titre: mots.allergenes, valeur: plat.allergenes.join(', ')),
                  _Ligne(titre: mots.regimes, valeur: plat.regimes.join(', ')),
                  _Ligne(
                    titre: mots.calories,
                    valeur: plat.calories == null ? '' : '${plat.calories} kcal',
                  ),
                  _Ligne(
                    titre: mots.note,
                    valeur: plat.noteMoyenne == null ? '' : '${plat.noteMoyenne} / 5',
                  ),
                  if (plat.prixSupplementXof > 0)
                    _Ligne(
                      titre: mots.partEnPlus(''),
                      valeur: formaterXof(plat.prixSupplementXof),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: Mesures.hauteurBouton,
                    child: OutlinedButton(
                      onPressed: () => contexte.pop(),
                      child: Text(mots.retour),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.titre, required this.valeur});

  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext contexte) {
    if (valeur.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final Palette couleurs = contexte.couleurs;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: TexteAdapte(
              titre,
              style: Theme.of(contexte)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: couleurs.texteSecondaire),
            ),
          ),
          Expanded(
            child: TexteAdapte(
              valeur,
              maxLignes: 3,
              style: Theme.of(contexte).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
