// Role du fichier : les deux palettes de docs/CHARTE.md, seule source de couleur de l application.
// Aucun ecran n ecrit une couleur en dur : il passe par le theme, qui est construit a partir d ici.

import 'package:flutter/material.dart';

/// Les roles de couleur d un mode d affichage, clair ou sombre.
@immutable
class Palette {
  /// Construit une palette a partir de chaque role de couleur de la charte.
  const Palette({
    required this.accent,
    required this.accentDoux,
    required this.surAccent,
    required this.accentProfond,
    required this.fond,
    required this.surface,
    required this.muet,
    required this.filet,
    required this.texte,
    required this.texteSecondaire,
    required this.texteAdouci,
    required this.succes,
    required this.danger,
    required this.alerte,
    required this.contraste,
    required this.surContraste,
    required this.surContrasteAttenue,
    required this.champ,
    required this.texteChamp,
  });

  /// Identite de la marque : bouton principal, onglet actif, lien.
  final Color accent;

  /// Fond de pastille, etat selectionne, surface d accent.
  final Color accentDoux;

  /// Texte et icones poses sur l accent.
  final Color surAccent;

  /// Etat presse de l accent.
  final Color accentProfond;

  /// Fond general de l ecran.
  final Color fond;

  /// Cartes, feuilles du bas, barres.
  final Color surface;

  /// Zones calmes et etats vides.
  final Color muet;

  /// Traits de separation et contours de carte.
  final Color filet;

  /// Texte principal.
  final Color texte;

  /// Legendes, dates et aides.
  final Color texteSecondaire;

  /// Titres secondaires poses sur une surface.
  final Color texteAdouci;

  /// Reservation confirmee, scan accepte, paiement recu.
  final Color succes;

  /// Echec de paiement, scan refuse, champ invalide.
  final Color danger;

  /// Solde bas, stock faible, heure limite proche.
  final Color alerte;

  /// Surfaces toujours sombres : favoris, anti gaspillage.
  final Color contraste;

  /// Texte pose sur une surface de contraste.
  final Color surContraste;

  /// Texte secondaire pose sur une surface de contraste.
  final Color surContrasteAttenue;

  /// Fond des champs de saisie.
  final Color champ;

  /// Texte saisi dans un champ.
  final Color texteChamp;
}

/// La palette du mode clair, recopiee de tokens.css.
const Palette paletteClaire = Palette(
  accent: Color(0xFF2F6BFF),
  accentDoux: Color(0xFFE8EFFF),
  surAccent: Color(0xFFFFFFFF),
  accentProfond: Color(0xFF1D4ED8),
  fond: Color(0xFFF4F6FB),
  surface: Color(0xFFFFFFFF),
  muet: Color(0xFFEEF1F8),
  filet: Color(0xFFE2E8F0),
  texte: Color(0xFF0F172A),
  texteSecondaire: Color(0xFF64748B),
  texteAdouci: Color(0xFF1E293B),
  succes: Color(0xFF0D9488),
  danger: Color(0xFFEF4444),
  alerte: Color(0xFFF59E0B),
  contraste: Color(0xFF0F172A),
  surContraste: Color(0xFFFFFFFF),
  surContrasteAttenue: Color(0xFF93C5FD),
  champ: Color(0xFFFFFFFF),
  texteChamp: Color(0xFF0F172A),
);

/// La palette du mode sombre, recopiee de tokens.css.
const Palette paletteSombre = Palette(
  accent: Color(0xFF60A5FA),
  accentDoux: Color(0xFF1E293B),
  surAccent: Color(0xFF0F172A),
  accentProfond: Color(0xFF93C5FD),
  fond: Color(0xFF0B1220),
  surface: Color(0xFF111827),
  muet: Color(0xFF1F2937),
  filet: Color(0xFF334155),
  texte: Color(0xFFF8FAFC),
  texteSecondaire: Color(0xFF94A3B8),
  texteAdouci: Color(0xFFE2E8F0),
  succes: Color(0xFF0D9488),
  danger: Color(0xFFEF4444),
  alerte: Color(0xFFF59E0B),
  contraste: Color(0xFF020617),
  surContraste: Color(0xFFF8FAFC),
  surContrasteAttenue: Color(0xFF93C5FD),
  champ: Color(0xFF1E293B),
  texteChamp: Color(0xFFF8FAFC),
);

/// Les couleurs propres au logo, distinctes des jetons d interface.
@immutable
class CouleursMarque {
  const CouleursMarque._();

  /// Trait du symbole sur fond clair.
  static const Color traitClair = Color(0xFF171717);

  /// Accent du symbole sur fond clair.
  static const Color accentClair = Color(0xFF2557D6);

  /// Remplissage de l assiette sur fond clair.
  static const Color fondClair = Color(0xFFFFFFFF);

  /// Trait du symbole sur fond sombre.
  static const Color traitSombre = Color(0xFFF5F5F4);

  /// Accent du symbole sur fond sombre.
  static const Color accentSombre = Color(0xFF6B93FF);

  /// Remplissage de l assiette sur fond sombre.
  static const Color fondSombre = Color(0xFF1C1C1C);
}

/// Donne acces a la palette depuis n importe quel widget, par le theme.
@immutable
class JetonsCouleur extends ThemeExtension<JetonsCouleur> {
  /// Enveloppe une palette pour la poser dans le theme.
  const JetonsCouleur(this.palette);

  /// La palette du mode en cours.
  final Palette palette;

  @override
  JetonsCouleur copyWith({Palette? palette}) => JetonsCouleur(palette ?? this.palette);

  @override
  JetonsCouleur lerp(ThemeExtension<JetonsCouleur>? autre, double t) {
    // Les couleurs changent d un bloc a l autre : pas d interpolation partielle.
    if (autre is! JetonsCouleur) {
      return this;
    }
    return t < 0.5 ? this : autre;
  }
}

/// Raccourci de lecture de la palette dans un widget.
extension PaletteDuContexte on BuildContext {
  /// Rend la palette du mode d affichage en cours.
  Palette get couleurs => Theme.of(this).extension<JetonsCouleur>()!.palette;
}
