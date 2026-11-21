// Role du fichier : ce que l application manipule d un menu, calque sur GET /menus/semaine.

import 'package:flutter/foundation.dart';

/// Les trois services d un repas.
enum Service {
  /// L entrée.
  entree,

  /// Le plat principal.
  resistance,

  /// Le dessert.
  sortie;

  /// Rend le service portant ce nom, résistance par défaut.
  static Service depuisTexte(String? valeur) => Service.values.firstWhere(
        (Service service) => service.name == valeur,
        orElse: () => Service.resistance,
      );
}

/// Un plat proposé un jour donné.
@immutable
class Plat {
  /// Construit un plat.
  const Plat({
    required this.id,
    required this.nom,
    required this.service,
    this.description = '',
    this.image,
    this.allergenes = const <String>[],
    this.regimes = const <String>[],
    this.calories,
    this.prixSupplementXof = 0,
    this.noteMoyenne,
  });

  /// Relit un plat rendu par l API.
  factory Plat.depuisJson(Map<String, dynamic> json) => Plat(
        id: json['id'] as String? ?? '',
        nom: json['nom'] as String? ?? json['nom_fr'] as String? ?? '',
        service: Service.depuisTexte(json['service'] as String? ?? json['categorie'] as String?),
        description: json['description'] as String? ?? json['description_fr'] as String? ?? '',
        image: json['image_url'] as String?,
        allergenes: _liste(json['allergenes']),
        regimes: _liste(json['regimes']),
        calories: json['calories'] as int?,
        prixSupplementXof: json['prix_supplement_xof'] as int? ?? 0,
        noteMoyenne: (json['note_moyenne'] as num?)?.toDouble(),
      );

  /// Identifiant du plat.
  final String id;

  /// Nom affiché.
  final String nom;

  /// Service auquel il appartient.
  final Service service;

  /// Description courte.
  final String description;

  /// Image du plat : une adresse, ou un fichier des ressources.
  final String? image;

  /// Allergènes déclarés.
  final List<String> allergenes;

  /// Régimes compatibles.
  final List<String> regimes;

  /// Calories, quand elles sont connues.
  final int? calories;

  /// Prix d une part en plus du menu.
  final int prixSupplementXof;

  /// Note moyenne des convives.
  final double? noteMoyenne;

  /// Vrai si le plat contient l un des allergènes donnés.
  bool contientUnDe(List<String> allergenesDuConvive) => allergenes.any(
        (String allergene) => allergenesDuConvive
            .map((String a) => a.toLowerCase())
            .contains(allergene.toLowerCase()),
      );

  static List<String> _liste(Object? brut) =>
      brut is List ? brut.map((Object? e) => '$e').toList(growable: false) : const <String>[];
}

/// Le menu d un jour.
@immutable
class MenuDuJour {
  /// Construit le menu d un jour.
  const MenuDuJour({
    required this.date,
    required this.etat,
    required this.prixXof,
    required this.plats,
    this.heureLimite,
    this.heureGel,
  });

  /// Relit un jour rendu par l API.
  factory MenuDuJour.depuisJson(Map<String, dynamic> json) {
    final Object? brut = json['plats'];
    final List<Plat> plats = brut is List
        ? brut
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> p) => Plat.depuisJson(p.cast<String, dynamic>()))
            .toList(growable: false)
        : const <Plat>[];
    return MenuDuJour(
      date: DateTime.parse(json['date_service'] as String? ?? json['date'] as String),
      etat: json['etat'] as String? ?? 'publie',
      prixXof: json['prix_xof'] as int? ?? 0,
      plats: plats,
      heureLimite: json['heure_limite'] as String?,
      heureGel: json['heure_gel'] as String?,
    );
  }

  /// Jour de service.
  final DateTime date;

  /// `brouillon`, `publie` ou `annule`.
  final String etat;

  /// Prix du repas ce jour-là, pour le profil du demandeur.
  final int prixXof;

  /// Tous les plats proposés, tous services confondus.
  final List<Plat> plats;

  /// Heure limite de commande.
  final String? heureLimite;

  /// Heure de gel, la veille.
  final String? heureGel;

  /// Vrai quand le menu est publié et commandable.
  bool get estPublie => etat == 'publie';

  /// Rend les plats d un service.
  List<Plat> parService(Service service) =>
      plats.where((Plat plat) => plat.service == service).toList(growable: false);
}

/// Une semaine de menus.
@immutable
class SemaineMenu {
  /// Construit une semaine.
  const SemaineMenu({required this.jours, required this.depuisCache, required this.majLe});

  /// Les jours rendus, du lundi au dimanche.
  final List<MenuDuJour> jours;

  /// Vrai quand les données viennent de l appareil et non du réseau.
  final bool depuisCache;

  /// Heure de la dernière mise à jour réussie.
  final DateTime majLe;

  /// Rend le menu du jour demandé, ou rien.
  MenuDuJour? pourLeJour(DateTime jour) {
    for (final MenuDuJour menu in jours) {
      if (menu.date.year == jour.year && menu.date.month == jour.month && menu.date.day == jour.day) {
        return menu;
      }
    }
    return null;
  }
}
