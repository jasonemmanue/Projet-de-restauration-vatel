// Role du fichier : dessiner le symbole de la marque et son animation d ouverture.
// La geometrie est celle de la maquette (assiette, encoche de creneau, aiguille, reperes).
// Le symbole est dessine, jamais une image ni un emoji : il reste net a toutes les tailles.

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/couleurs.dart';

/// Le symbole de la marque, dessine a la taille voulue.
class LogoCantine extends StatelessWidget {
  /// Construit le symbole.
  const LogoCantine({
    super.key,
    this.taille = 64,
    this.progression = 1,
    this.sombre,
  });

  /// Cote du symbole, en points.
  final double taille;

  /// Avancement du trace, de 0 a 1. A 1, le symbole est complet.
  final double progression;

  /// Force le ton sombre ou clair. Vide, le ton suit le theme.
  final bool? sombre;

  @override
  Widget build(BuildContext contexte) {
    final bool tonSombre = sombre ?? Theme.of(contexte).brightness == Brightness.dark;
    return SizedBox(
      width: taille,
      height: taille,
      child: CustomPaint(
        painter: _PeintreLogo(progression: progression, sombre: tonSombre),
      ),
    );
  }
}

/// Le symbole qui se dessine puis se remplit, en moins d une seconde.
class LogoAnime extends StatefulWidget {
  /// Construit le symbole anime.
  const LogoAnime({super.key, this.taille = 120, this.anime = true, this.sombre});

  /// Cote du symbole.
  final double taille;

  /// Faux pour afficher directement le symbole complet, sans animation.
  final bool anime;

  /// Force le ton sombre ou clair.
  final bool? sombre;

  @override
  State<LogoAnime> createState() => _EtatLogoAnime();
}

class _EtatLogoAnime extends State<LogoAnime> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    final bool animationsReduites =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (widget.anime && !animationsReduites) {
      _animation.forward();
    } else {
      _animation.value = 1;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext contexte) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext contexte, Widget? enfant) => LogoCantine(
        taille: widget.taille,
        progression: Curves.easeOutCubic.transform(_animation.value),
        sombre: widget.sombre,
      ),
    );
  }
}

class _PeintreLogo extends CustomPainter {
  const _PeintreLogo({required this.progression, required this.sombre});

  final double progression;
  final bool sombre;

  /// Part de l animation consacree au trace, le reste au remplissage.
  static const double _partTrace = 0.65;

  @override
  void paint(Canvas toile, Size taille) {
    final double echelle = taille.width / 64;
    final Color trait = sombre ? CouleursMarque.traitSombre : CouleursMarque.traitClair;
    final Color accent = sombre ? CouleursMarque.accentSombre : CouleursMarque.accentClair;
    final Color fond = sombre ? CouleursMarque.fondSombre : CouleursMarque.fondClair;

    final double avanceeTrace = (progression / _partTrace).clamp(0.0, 1.0);
    final double avanceeFond =
        ((progression - _partTrace * 0.9) / (1 - _partTrace * 0.9)).clamp(0.0, 1.0);

    Offset point(double x, double y) => Offset(x * echelle, y * echelle);
    double mesure(double valeur) => valeur * echelle;

    // L assiette se remplit en meme temps que les aplats, pour ne pas masquer le trace.
    final Paint remplissageAssiette = Paint()..color = fond.withValues(alpha: avanceeFond);
    toile.drawCircle(point(32, 32), mesure(28), remplissageAssiette);

    void tracerCercle(double cx, double cy, double rayon, double epaisseur, Color couleur) {
      final Path chemin = Path()
        ..addArc(
          Rect.fromCircle(center: point(cx, cy), radius: mesure(rayon)),
          -1.5708,
          6.2832,
        );
      final Paint pinceau = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = mesure(epaisseur)
        ..strokeCap = StrokeCap.round
        ..color = couleur;
      for (final PathMetric metrique in chemin.computeMetrics()) {
        toile.drawPath(
          metrique.extractPath(0, metrique.length * avanceeTrace),
          pinceau,
        );
      }
    }

    tracerCercle(32, 32, 28, 3, trait);
    tracerCercle(32, 32, 22, 1.5, trait.withValues(alpha: 0.35 * avanceeTrace));
    tracerCercle(32, 33, 11, 2.25, trait);

    if (avanceeFond <= 0) {
      return;
    }

    // Encoche de creneau.
    final Path encoche = Path()
      ..moveTo(point(32, 2.5).dx, point(32, 2.5).dy)
      ..lineTo(point(38.5, 14.5).dx, point(38.5, 14.5).dy)
      ..lineTo(point(25.5, 14.5).dx, point(25.5, 14.5).dy)
      ..close();
    toile.drawPath(encoche, Paint()..color = accent.withValues(alpha: avanceeFond));

    // Aiguille et pivot.
    toile.drawLine(
      point(32, 33),
      Offset.lerp(point(32, 33), point(41.5, 26.5), avanceeFond)!,
      Paint()
        ..color = accent
        ..strokeWidth = mesure(2.75)
        ..strokeCap = StrokeCap.round,
    );
    toile.drawCircle(
      point(32, 33),
      mesure(3.2) * avanceeFond,
      Paint()..color = accent,
    );

    // Reperes discrets aux quatre points cardinaux.
    final Paint repere = Paint()..color = trait.withValues(alpha: 0.45 * avanceeFond);
    for (final Offset centre in <Offset>[
      point(32, 18.5),
      point(45.5, 33),
      point(32, 47.5),
      point(18.5, 33),
    ]) {
      toile.drawCircle(centre, mesure(1.4), repere);
    }
  }

  @override
  bool shouldRepaint(_PeintreLogo ancien) =>
      ancien.progression != progression || ancien.sombre != sombre;
}
