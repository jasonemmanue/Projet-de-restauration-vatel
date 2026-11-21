// Role du fichier : une semaine de menus de démonstration, le temps que A4 livre les vraies routes.
// Elle sert aussi d écran de secours quand l API ne répond pas et qu aucun cache n existe.
// À retirer dès que GET /menus/semaine est en ligne : le serveur décide, pas l application.

import 'modeles_menu.dart';

/// Prix du repas, par profil, en attendant la table des tarifs.
const Map<String, int> prixDemoParProfil = <String, int>{
  'eleve': 1500,
  'etudiant': 1500,
  'employe': 2500,
  'autre': 2500,
};

/// Rend une semaine de démonstration qui commence au lundi de la semaine demandée.
SemaineMenu semaineDemo({DateTime? depuis, int prixXof = 1500}) {
  final DateTime reference = depuis ?? DateTime.now();
  final DateTime jour = DateTime(reference.year, reference.month, reference.day);
  // Le week-end, la semaine en cours est finie : on montre celle qui vient.
  final DateTime lundi = reference.weekday >= DateTime.saturday
      ? jour.add(Duration(days: 8 - reference.weekday))
      : jour.subtract(Duration(days: reference.weekday - 1));

  final List<MenuDuJour> jours = <MenuDuJour>[];
  for (int index = 0; index < 5; index++) {
    final DateTime jour = lundi.add(Duration(days: index));
    jours.add(
      MenuDuJour(
        date: jour,
        etat: 'publie',
        prixXof: prixXof,
        heureLimite: '11:00',
        heureGel: '18:00',
        plats: _platsDuJour(index),
      ),
    );
  }
  return SemaineMenu(jours: jours, depuisCache: false, majLe: DateTime.now());
}

List<Plat> _platsDuJour(int index) {
  final List<List<Plat>> semaine = <List<Plat>>[
    <Plat>[
      const Plat(
        id: 'demo-e1',
        nom: 'Salade d avocat',
        service: Service.entree,
        description: 'Avocat, tomate, oignon frais, filet de citron.',
        image: 'assets/plats/hero.jpg',
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 180,
        prixSupplementXof: 500,
      ),
      const Plat(
        id: 'demo-r1',
        nom: 'Attiéké poisson braisé',
        service: Service.resistance,
        description: 'Attiéké de Dabou, poisson braisé, tomate et piment doux.',
        image: 'assets/plats/attieke.jpg',
        allergenes: <String>['poisson'],
        regimes: <String>['sans_porc'],
        calories: 620,
        prixSupplementXof: 1200,
        noteMoyenne: 4.6,
      ),
      const Plat(
        id: 'demo-s1',
        nom: 'Ananas frais',
        service: Service.sortie,
        description: 'Ananas de Bonoua, coupé le matin.',
        regimes: <String>['vegetarien', 'sans_gluten', 'sans_porc'],
        calories: 90,
        prixSupplementXof: 300,
      ),
    ],
    <Plat>[
      const Plat(
        id: 'demo-e2',
        nom: 'Beignets de haricot',
        service: Service.entree,
        description: 'Haricots pilés, frits à la minute.',
        allergenes: <String>['arachide'],
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 240,
        prixSupplementXof: 500,
      ),
      const Plat(
        id: 'demo-r2',
        nom: 'Riz sauce graine',
        service: Service.resistance,
        description: 'Sauce graine de palme, viande de bœuf, riz blanc.',
        image: 'assets/plats/sauce.jpg',
        regimes: <String>['sans_porc'],
        calories: 700,
        prixSupplementXof: 1200,
        noteMoyenne: 4.4,
      ),
      const Plat(
        id: 'demo-s2',
        nom: 'Banane braisée',
        service: Service.sortie,
        description: 'Banane douce braisée au feu de bois.',
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 150,
        prixSupplementXof: 300,
      ),
    ],
    <Plat>[
      const Plat(
        id: 'demo-e3',
        nom: 'Salade de choux',
        service: Service.entree,
        description: 'Chou blanc, carotte râpée, vinaigrette légère.',
        regimes: <String>['vegetarien', 'sans_gluten', 'sans_porc'],
        calories: 120,
        prixSupplementXof: 500,
      ),
      const Plat(
        id: 'demo-r3',
        nom: 'Poulet braisé et alloco',
        service: Service.resistance,
        description: 'Poulet mariné braisé, bananes plantain frites.',
        image: 'assets/plats/poulet.jpg',
        regimes: <String>['sans_porc', 'sans_gluten'],
        calories: 760,
        prixSupplementXof: 1500,
        noteMoyenne: 4.8,
      ),
      const Plat(
        id: 'demo-s3',
        nom: 'Dégué',
        service: Service.sortie,
        description: 'Mil, lait caillé, un peu de vanille.',
        allergenes: <String>['lait'],
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 210,
        prixSupplementXof: 400,
      ),
    ],
    <Plat>[
      const Plat(
        id: 'demo-e4',
        nom: 'Soupe de poisson',
        service: Service.entree,
        description: 'Bouillon clair, poisson frais, aubergine locale.',
        allergenes: <String>['poisson'],
        regimes: <String>['sans_porc', 'sans_gluten'],
        calories: 160,
        prixSupplementXof: 600,
      ),
      const Plat(
        id: 'demo-r4',
        nom: 'Riz gras au bœuf',
        service: Service.resistance,
        description: 'Riz cuit dans son bouillon, bœuf mijoté, légumes.',
        image: 'assets/plats/riz.jpg',
        regimes: <String>['sans_porc'],
        calories: 680,
        prixSupplementXof: 1200,
        noteMoyenne: 4.3,
      ),
      const Plat(
        id: 'demo-s4',
        nom: 'Papaye',
        service: Service.sortie,
        description: 'Papaye mûre, quartier de citron vert.',
        regimes: <String>['vegetarien', 'sans_gluten', 'sans_porc'],
        calories: 80,
        prixSupplementXof: 300,
      ),
    ],
    <Plat>[
      const Plat(
        id: 'demo-e5',
        nom: 'Avocat vinaigrette',
        service: Service.entree,
        description: 'Demi-avocat, vinaigrette moutarde.',
        allergenes: <String>['moutarde'],
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 190,
        prixSupplementXof: 500,
      ),
      const Plat(
        id: 'demo-r5',
        nom: 'Garba du vendredi',
        service: Service.resistance,
        description: 'Attiéké, thon frit, oignon, piment à part.',
        image: 'assets/plats/attieke.jpg',
        allergenes: <String>['poisson'],
        regimes: <String>['sans_porc'],
        calories: 640,
        prixSupplementXof: 1000,
        noteMoyenne: 4.7,
      ),
      const Plat(
        id: 'demo-s5',
        nom: 'Yaourt nature',
        service: Service.sortie,
        description: 'Yaourt brassé, miel en option.',
        allergenes: <String>['lait'],
        regimes: <String>['vegetarien', 'sans_porc'],
        calories: 130,
        prixSupplementXof: 300,
      ),
    ],
  ];
  return semaine[index % semaine.length];
}
