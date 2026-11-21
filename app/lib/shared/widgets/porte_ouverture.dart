// Role du fichier : l animation d ouverture reprise de la maquette (SplashScreen.tsx). Une photo de repas
// se resserre, le logo arrive en rebond sur un disque blanc, puis l accroche et le bouton Commencer.
// Elle s efface seule apres 2,8 s ou au toucher, et passe sans mouvement si le systeme reduit les animations.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import 'texte_adapte.dart';

/// Pose l ecran d ouverture au-dessus de l application, une fois par lancement.
class PorteOuverture extends StatefulWidget {
  /// Construit la porte autour de l application.
  const PorteOuverture({super.key, required this.enfant});

  /// L application, deja montee dessous pour que la sortie soit immediate.
  final Widget enfant;

  @override
  State<PorteOuverture> createState() => _EtatPorteOuverture();
}

class _EtatPorteOuverture extends State<PorteOuverture> with TickerProviderStateMixin {
  // Duree d affichage de la maquette, avant le fondu de sortie.
  static const Duration _affichage = Duration(milliseconds: 2800);

  late final AnimationController _entree =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _sortie =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Timer? _minuteur;
  bool _finie = false;

  @override
  void initState() {
    super.initState();
    final bool reduites =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduites) {
      _entree.value = 1;
    } else {
      unawaited(_entree.forward());
    }
    _minuteur = Timer(_affichage, _fermer);
  }

  void _fermer() {
    if (!mounted || _sortie.isAnimating || _finie) {
      return;
    }
    _sortie.forward().whenComplete(() {
      if (mounted) {
        setState(() => _finie = true);
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _entree.dispose();
    _sortie.dispose();
    super.dispose();
  }

  /// Rend la part de l animation d entree entre deux instants, en secondes.
  Animation<double> _tranche(double debut, double fin, Curve courbe) => CurvedAnimation(
        parent: _entree,
        curve: Interval(debut / 3.2, fin / 3.2, curve: courbe),
      );

  @override
  Widget build(BuildContext contexte) {
    if (_finie) {
      return widget.enfant;
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.enfant,
        FadeTransition(
          opacity: ReverseAnimation(_sortie),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.04).animate(_sortie),
            child: _ecran(contexte),
          ),
        ),
      ],
    );
  }

  Widget _ecran(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final EdgeInsets marges = MediaQuery.paddingOf(contexte);
    final Animation<double> logo = _tranche(0.12, 0.9, Curves.elasticOut);
    final Animation<double> titre = _tranche(0.26, 0.9, Curves.easeOutCubic);
    final Animation<double> detail = _tranche(0.4, 1, Curves.easeOutCubic);
    final Animation<double> bouton = _tranche(0.52, 1.1, Curves.easeOutCubic);

    return Material(
      color: couleurs.fond,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ScaleTransition(
            scale: Tween<double>(begin: 1.18, end: 1)
                .animate(CurvedAnimation(parent: _entree, curve: Curves.easeOut)),
            child: Image.asset('assets/plats/hero.jpg', fit: BoxFit.cover),
          ),
          // Voile de la maquette : la photo reste visible en haut, le texte lisible en bas.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x330F172A), Color(0x730F172A), Color(0xF00F172A)],
                stops: <double>[0, 0.4, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 36 + marges.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ScaleTransition(
                  scale: Tween<double>(begin: 0.82, end: 1).animate(logo),
                  child: FadeTransition(
                    opacity: _tranche(0.12, 0.5, Curves.easeOut),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(17),
                      child: Image.asset('assets/marque/symbole-transparent-clair-1024.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _monte(
                  titre,
                  22,
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: TexteAdapte(
                      mots.ouvertureTitre,
                      maxLignes: 2,
                      style: Theme.of(contexte).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _monte(
                  detail,
                  16,
                  TexteAdapte(
                    'Cantine Vatel · ${mots.ouvertureDetail}',
                    maxLignes: 2,
                    style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xE0FFFFFF),
                          height: 1.45,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                _monte(
                  bouton,
                  20,
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: couleurs.champ,
                        foregroundColor: couleurs.accent,
                      ),
                      onPressed: _fermer,
                      child: Text(mots.ouvertureCommencer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fait monter et apparaitre un element, comme les entrees de la maquette.
  Widget _monte(Animation<double> animation, double distance, Widget enfant) => AnimatedBuilder(
        animation: animation,
        builder: (BuildContext _, Widget? contenu) => Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, distance * (1 - animation.value)),
            child: contenu,
          ),
        ),
        child: enfant,
      );
}
