// Role du fichier : la page defilante commune. Elle remonte en haut quand l utilisateur
// touche l onglet deja actif, et garde sa position de defilement le reste du temps.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/routes/coquille.dart';
import '../../l10n/traductions.dart';
import 'texte_adapte.dart';

/// Une page qui defile et qui obeit a la demande de remontee en haut.
class PageDefilante extends ConsumerStatefulWidget {
  /// Construit une page defilante.
  const PageDefilante({required this.enfants, super.key, this.padding});

  /// Le contenu de la page, de haut en bas.
  final List<Widget> enfants;

  /// Marge autour du contenu.
  final EdgeInsetsGeometry? padding;

  @override
  ConsumerState<PageDefilante> createState() => _EtatPageDefilante();
}

class _EtatPageDefilante extends ConsumerState<PageDefilante> {
  final ScrollController _defilement = ScrollController();

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  void _remonter() {
    if (!_defilement.hasClients) {
      return;
    }
    final bool animationsReduites =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (animationsReduites) {
      _defilement.jumpTo(0);
      return;
    }
    unawaited(
      _defilement.animateTo(
        0,
        duration: Mesures.transition,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext contexte) {
    ref.listen<int>(remonteeProvider, (int? avant, int apres) => _remonter());
    return ListView(
      controller: _defilement,
      padding: widget.padding ?? const EdgeInsets.all(Mesures.marge),
      children: widget.enfants,
    );
  }
}

/// Un ecran encore a construire, qui tient sa place dans la navigation.
class PageEnChantier extends StatelessWidget {
  /// Construit la page d attente d un ecran a venir.
  const PageEnChantier({required this.titre, required this.etape, super.key});

  /// Titre de l ecran, deja traduit.
  final String titre;

  /// L etape du plan qui construira cet ecran, par exemple F3.
  final String etape;

  @override
  Widget build(BuildContext contexte) {
    return PageDefilante(
      enfants: <Widget>[
        TexteAdapte(titre, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 12),
        TexteAdapte(
          '${Traductions.of(contexte).ecranEnConstruction} ($etape)',
          maxLignes: 2,
          style: Theme.of(contexte).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
