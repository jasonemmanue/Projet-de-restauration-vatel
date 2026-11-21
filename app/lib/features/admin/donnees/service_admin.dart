// Role du fichier : les appels du back office, plats, menus et tarifs.
// L API d abord. Tant que A8 n a pas livré ses routes, un dépôt local tient lieu de secours
// pour que la démonstration tourne. Il disparaît dès que les routes existent.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reseau/client_api.dart';
import '../../../core/reseau/erreur_api.dart';
import '../../menus/donnees/jeu_demo.dart';
import '../../menus/donnees/modeles_menu.dart';

/// Un tarif de repas, par profil.
class Tarif {
  /// Construit un tarif.
  const Tarif({required this.profil, required this.prixXof});

  /// `eleve`, `etudiant`, `employe`, `autre` ou `visiteur`.
  final String profil;

  /// Prix du repas du jour pour ce profil.
  final int prixXof;
}

/// L état du back office, tenu localement tant que l API n expose pas ses routes.
class EtatAdmin {
  /// Construit l état.
  const EtatAdmin({required this.plats, required this.menus, required this.tarifs});

  /// Tous les plats connus.
  final List<Plat> plats;

  /// Les menus de la semaine.
  final List<MenuDuJour> menus;

  /// Les tarifs par profil.
  final List<Tarif> tarifs;

  /// Rend une copie avec les champs donnés remplacés.
  EtatAdmin copie({List<Plat>? plats, List<MenuDuJour>? menus, List<Tarif>? tarifs}) => EtatAdmin(
        plats: plats ?? this.plats,
        menus: menus ?? this.menus,
        tarifs: tarifs ?? this.tarifs,
      );
}

/// Tient le back office : plats, menus et tarifs.
class AdminNotifier extends Notifier<EtatAdmin> {
  @override
  EtatAdmin build() {
    final SemaineMenu demo = semaineDemo();
    final List<Plat> plats = <Plat>[];
    for (final MenuDuJour menu in demo.jours) {
      for (final Plat plat in menu.plats) {
        if (!plats.any((Plat deja) => deja.id == plat.id)) {
          plats.add(plat);
        }
      }
    }
    return EtatAdmin(
      plats: plats,
      menus: demo.jours,
      tarifs: const <Tarif>[
        Tarif(profil: 'eleve', prixXof: 1500),
        Tarif(profil: 'etudiant', prixXof: 1500),
        Tarif(profil: 'employe', prixXof: 2500),
        Tarif(profil: 'autre', prixXof: 2500),
      ],
    );
  }

  /// Ajoute ou remplace un plat.
  Future<void> enregistrerPlat(Plat plat) async {
    await _tenter(() => ref.read(clientApiProvider).envoyer(
          '/admin/plats',
          corps: <String, dynamic>{
            'nom_fr': plat.nom,
            'categorie': plat.service.name,
            'description_fr': plat.description,
            'allergenes': plat.allergenes,
            'prix_supplement_xof': plat.prixSupplementXof,
          },
        ));
    final List<Plat> plats = List<Plat>.of(state.plats);
    final int index = plats.indexWhere((Plat deja) => deja.id == plat.id);
    if (index >= 0) {
      plats[index] = plat;
    } else {
      plats.add(plat);
    }
    state = state.copie(plats: plats);
  }

  /// Retire un plat du catalogue.
  Future<void> supprimerPlat(String platId) async {
    await _tenter(() => ref.read(clientApiProvider).envoyer('/admin/plats/$platId/supprimer'));
    state = state.copie(
      plats: state.plats.where((Plat plat) => plat.id != platId).toList(growable: false),
    );
  }

  /// Change le prix d un profil.
  Future<void> poserTarif(String profil, int prixXof) async {
    await _tenter(() => ref.read(clientApiProvider).envoyer(
          '/admin/tarifs',
          corps: <String, dynamic>{'profil': profil, 'prix_xof': prixXof},
        ));
    final List<Tarif> tarifs = state.tarifs
        .map((Tarif tarif) => tarif.profil == profil ? Tarif(profil: profil, prixXof: prixXof) : tarif)
        .toList(growable: false);
    state = state.copie(tarifs: tarifs);
  }

  /// Ajoute ou retire un plat du menu d un jour.
  Future<void> basculerPlatDuMenu(DateTime jour, Plat plat) async {
    final List<MenuDuJour> menus = <MenuDuJour>[];
    for (final MenuDuJour menu in state.menus) {
      if (!_memeJour(menu.date, jour)) {
        menus.add(menu);
        continue;
      }
      final List<Plat> plats = List<Plat>.of(menu.plats);
      final int index = plats.indexWhere((Plat deja) => deja.id == plat.id);
      if (index >= 0) {
        plats.removeAt(index);
      } else {
        plats.add(plat);
      }
      menus.add(
        MenuDuJour(
          date: menu.date,
          etat: menu.etat,
          prixXof: menu.prixXof,
          plats: plats,
          heureLimite: menu.heureLimite,
          heureGel: menu.heureGel,
        ),
      );
    }
    state = state.copie(menus: menus);
  }

  /// Publie le menu d un jour.
  Future<void> publier(DateTime jour) async {
    await _tenter(() => ref.read(clientApiProvider).envoyer(
          '/admin/menus/publier',
          corps: <String, dynamic>{'date_service': jour.toIso8601String().split('T').first},
        ));
    state = state.copie(
      menus: state.menus
          .map(
            (MenuDuJour menu) => _memeJour(menu.date, jour)
                ? MenuDuJour(
                    date: menu.date,
                    etat: 'publie',
                    prixXof: menu.prixXof,
                    plats: menu.plats,
                    heureLimite: menu.heureLimite,
                    heureGel: menu.heureGel,
                  )
                : menu,
          )
          .toList(growable: false),
    );
  }

  /// Crée le menu d un jour, en brouillon.
  Future<void> creerMenu(DateTime jour, int prixXof) async {
    if (state.menus.any((MenuDuJour menu) => _memeJour(menu.date, jour))) {
      return;
    }
    await _tenter(() => ref.read(clientApiProvider).envoyer(
          '/admin/menus',
          corps: <String, dynamic>{
            'date_service': jour.toIso8601String().split('T').first,
            'heure_limite': '11:00',
            'heure_gel': '18:00',
          },
        ));
    final List<MenuDuJour> menus = List<MenuDuJour>.of(state.menus)
      ..add(
        MenuDuJour(
          date: jour,
          etat: 'brouillon',
          prixXof: prixXof,
          plats: const <Plat>[],
          heureLimite: '11:00',
          heureGel: '18:00',
        ),
      )
      ..sort((MenuDuJour a, MenuDuJour b) => a.date.compareTo(b.date));
    state = state.copie(menus: menus);
  }

  /// Appelle l API et avale l absence de route, le temps que A8 la livre.
  Future<void> _tenter(Future<Map<String, dynamic>> Function() appel) async {
    try {
      await appel();
    } on ErreurApi {
      return;
    }
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// L état du back office.
final NotifierProvider<AdminNotifier, EtatAdmin> adminProvider =
    NotifierProvider<AdminNotifier, EtatAdmin>(AdminNotifier.new);
