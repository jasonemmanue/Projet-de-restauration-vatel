// Role du fichier : la carte d un plat, telle que la maquette la dessine.
// Photo à bord perdu en haut, contenu paddé en dessous, aucune ombre, coins de 22.
// Une alerte rouge apparaît si le plat contient un allergène déclaré par le convive.

import 'package:flutter/material.dart';

import '../../../core/outils/formats.dart';
import '../../../core/responsive/type_ecran.dart';
import '../../../core/theme/couleurs.dart';
import '../../../l10n/traductions.dart';
import '../../../shared/widgets/texte_adapte.dart';
import '../donnees/modeles_menu.dart';

/// Une carte de plat, cliquable vers sa fiche.
class CartePlat extends StatelessWidget {
  /// Construit la carte.
  const CartePlat({
    required this.plat,
    required this.allergiesDuConvive,
    super.key,
    this.onTap,
    this.hauteurPhoto = 136,
  });

  /// Le plat montré.
  final Plat plat;

  /// Les allergènes déclarés par le convive.
  final List<String> allergiesDuConvive;

  /// Ouvre la fiche du plat.
  final VoidCallback? onTap;

  /// Hauteur de la photo, à bord perdu.
  final double hauteurPhoto;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final Traductions mots = Traductions.of(contexte);
    final bool alerte = plat.contientUnDe(allergiesDuConvive);

    return Material(
      color: couleurs.surface,
      borderRadius: BorderRadius.circular(Mesures.rayonCarte),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Mesures.rayonCarte),
            border: Border.all(color: alerte ? couleurs.danger : couleurs.filet),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PhotoPlat(plat: plat, hauteur: hauteurPhoto),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TexteAdapte(plat.nom, style: Theme.of(contexte).textTheme.titleLarge),
                    if (plat.description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      TexteAdapte(
                        plat.description,
                        maxLignes: 2,
                        style: Theme.of(contexte).textTheme.bodyMedium,
                      ),
                    ],
                    if (plat.prixSupplementXof > 0) ...<Widget>[
                      const SizedBox(height: 10),
                      TexteAdapte(
                        mots.partEnPlus(formaterXof(plat.prixSupplementXof)),
                        style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                              color: couleurs.texteSecondaire,
                            ),
                      ),
                    ],
                    if (alerte) ...<Widget>[
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Icon(Icons.warning_amber_rounded, size: 16, color: couleurs.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TexteAdapte(
                              mots.allergeneAlerte(
                                plat.allergenes
                                    .firstWhere((String a) => plat.contientUnDe(<String>[a])),
                              ),
                              maxLignes: 2,
                              style: Theme.of(contexte)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: couleurs.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La photo d un plat, ou un aplat avec son initiale quand il n y en a pas.
class PhotoPlat extends StatelessWidget {
  /// Construit la photo.
  const PhotoPlat({required this.plat, required this.hauteur, super.key});

  /// Le plat montré.
  final Plat plat;

  /// Hauteur de la zone de photo.
  final double hauteur;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final String? image = plat.image;

    if (image == null || image.isEmpty) {
      return Container(
        height: hauteur,
        width: double.infinity,
        color: couleurs.accentDoux,
        alignment: Alignment.center,
        child: Icon(Icons.restaurant, size: 34, color: couleurs.accent),
      );
    }
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: hauteur,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
            Container(height: hauteur, color: couleurs.muet),
      );
    }
    return Image.asset(
      image,
      height: hauteur,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
          Container(height: hauteur, color: couleurs.muet),
    );
  }
}
