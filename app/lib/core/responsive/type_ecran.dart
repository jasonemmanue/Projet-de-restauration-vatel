// Role du fichier : les trois types d ecran de docs/CHARTE.md et les tailles de texte qui vont avec.

import 'package:flutter/widgets.dart';

/// Les trois tailles d ecran prevues par la charte.
enum TypeEcran {
  /// Moins de 600 points de large.
  telephone,

  /// De 600 a 1024 points de large.
  tablette,

  /// Plus de 1024 points de large.
  ordinateur;

  /// Rend le type d ecran correspondant a une largeur.
  static TypeEcran selonLargeur(double largeur) {
    if (largeur < 600) {
      return TypeEcran.telephone;
    }
    if (largeur <= 1024) {
      return TypeEcran.tablette;
    }
    return TypeEcran.ordinateur;
  }

  /// Rend le type d ecran du contexte courant.
  static TypeEcran de(BuildContext contexte) =>
      selonLargeur(MediaQuery.sizeOf(contexte).width);

  /// Vrai sur telephone, la seule taille qui porte une barre d onglets en bas.
  bool get estTelephone => this == TypeEcran.telephone;

  /// Vrai sur tablette, qui porte un rail lateral.
  bool get estTablette => this == TypeEcran.tablette;

  /// Vrai sur ordinateur, qui porte un menu lateral fixe.
  bool get estOrdinateur => this == TypeEcran.ordinateur;
}

/// Les tailles de texte de la charte, pour un type d ecran.
@immutable
class MesuresTexte {
  /// Construit un jeu de tailles.
  const MesuresTexte({
    required this.titreEcran,
    required this.titreSection,
    required this.sousTitre,
    required this.corps,
    required this.corpsSecondaire,
    required this.bouton,
    required this.onglet,
    required this.mention,
    required this.montant,
  });

  /// Rend les tailles du type d ecran demande.
  factory MesuresTexte.selon(TypeEcran type) => switch (type) {
        TypeEcran.telephone => const MesuresTexte(
            titreEcran: 24,
            titreSection: 20,
            sousTitre: 17,
            corps: 14,
            corpsSecondaire: 13,
            bouton: 15,
            onglet: 12,
            mention: 11,
            montant: 28,
          ),
        TypeEcran.tablette => const MesuresTexte(
            titreEcran: 28,
            titreSection: 22,
            sousTitre: 18,
            corps: 15,
            corpsSecondaire: 14,
            bouton: 16,
            onglet: 13,
            mention: 12,
            montant: 32,
          ),
        TypeEcran.ordinateur => const MesuresTexte(
            titreEcran: 32,
            titreSection: 24,
            sousTitre: 20,
            corps: 16,
            corpsSecondaire: 14,
            bouton: 16,
            onglet: 13,
            mention: 12,
            montant: 36,
          ),
      };

  /// Titre d ecran.
  final double titreEcran;

  /// Titre de section.
  final double titreSection;

  /// Sous titre.
  final double sousTitre;

  /// Texte courant.
  final double corps;

  /// Legende et aide.
  final double corpsSecondaire;

  /// Libelle de bouton.
  final double bouton;

  /// Libelle d onglet.
  final double onglet;

  /// Mention legale.
  final double mention;

  /// Montant mis en avant.
  final double montant;
}

/// Mesures de mise en page communes a toute l application.
@immutable
class Mesures {
  const Mesures._();

  /// Largeur maximale du contenu sur grand ecran.
  static const double largeurContenu = 1200;

  /// Cote minimal d un element touchable.
  static const double cibleTactile = 48;

  /// Hauteur d un bouton principal, en pilule.
  static const double hauteurBouton = 52;

  /// Rayon des petits elements.
  static const double rayonPetit = 14;

  /// Rayon des cartes.
  static const double rayonCarte = 22;

  /// Rayon des grandes surfaces et des feuilles du bas.
  static const double rayonGrand = 28;

  /// Marge laterale courante.
  static const double marge = 16;

  /// Duree des transitions, dans la fourchette de la charte.
  static const Duration transition = Duration(milliseconds: 240);

  /// Bornes du reglage d accessibilite de la taille du texte.
  static const double echelleTexteMin = 0.9;

  /// Borne haute du reglage d accessibilite de la taille du texte.
  static const double echelleTexteMax = 1.3;
}
