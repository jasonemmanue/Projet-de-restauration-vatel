// Role du fichier : toutes les routes de l application, une pile par onglet et une porte par role.
// Un role n atteint que ses ecrans : la redirection est faite ici, et le serveur refait le controle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/ecran_budget.dart';
import '../../features/admin/ecran_cuisine.dart';
import '../../features/admin/ecran_exploitation.dart';
import '../../features/admin/ecran_menus_admin.dart';
import '../../features/admin/ecran_plats_admin.dart';
import '../../features/admin/ecran_reglages_admin.dart';
import '../../features/admin/ecran_tableau_bord.dart';
import '../../features/auth/ecran_bienvenue.dart';
import '../../features/auth/ecran_code.dart';
import '../../features/auth/ecran_connexion.dart';
import '../../features/auth/ecran_finaliser_profil.dart';
import '../../features/auth/ecran_inscription.dart';
import '../../features/auth/ecran_mot_de_passe_oublie.dart';
import '../../features/menus/ecran_accueil.dart';
import '../../features/menus/donnees/modeles_menu.dart';
import '../../features/menus/ecran_fiche_plat.dart';
import '../../features/menus/ecran_menu.dart';
import '../../features/menus/ecran_visiteur.dart';
import '../../features/notifications/ecran_notifications.dart';
import '../../features/parent/ecran_famille.dart';
import '../../features/parent/ecran_messages.dart';
import '../../features/parent/ecran_recharge.dart';
import '../../features/porte_monnaie/ecran_lien_paiement.dart';
import '../../features/porte_monnaie/ecran_porte_monnaie.dart';
import '../../features/profil/ecran_compte.dart';
import '../../features/reservations/donnees/service_commandes.dart';
import '../../features/reservations/ecran_appreciation.dart';
import '../../features/reservations/ecran_commande.dart';
import '../../features/reservations/ecran_mes_commandes.dart';
import '../../features/reservations/ecran_ticket.dart';
import '../../features/service/ecran_collecte.dart';
import '../../features/service/ecran_manifeste.dart';
import '../../features/service/ecran_reglages_poste.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../responsive/type_ecran.dart';
import '../securite/session.dart';
import 'coquille.dart';

/// Les chemins connus de l application.
class Chemins {
  const Chemins._();

  /// Ecran montre tant que personne n est connecte.
  static const String bienvenue = '/bienvenue';

  /// Creation d un compte.
  static const String inscription = '/inscription';

  /// Connexion a un compte existant.
  static const String connexion = '/connexion';

  /// Saisie du code de verification.
  static const String code = '/code';

  /// Mot de passe oublie et reinitialisation.
  static const String motDePasseOublie = '/mot-de-passe-oublie';

  /// Completer son profil apres Google ou Apple.
  static const String finaliserProfil = '/profil/finaliser';

  /// Vitrine sans compte.
  static const String visiteur = '/visiteur';

  /// Fiche detaillee d un plat.
  static const String fichePlat = '/convive/menu/plat';

  /// Les ecrans qu on atteint sans session ouverte.
  static const List<String> publics = <String>[
    bienvenue,
    inscription,
    connexion,
    code,
    motDePasseOublie,
    visiteur,
  ];

  /// Racine de l espace convive.
  static const String convive = '/convive';

  /// Racine de l espace parent.
  static const String parent = '/parent';

  /// Racine de l espace agent.
  static const String agent = '/agent';

  /// Racine du back office.
  static const String admin = '/admin';

  /// Rend la racine de l espace d un role.
  static String racine(Role role) => switch (role) {
        Role.convive => convive,
        Role.parent => parent,
        Role.agent => agent,
        Role.admin => admin,
      };

  /// Rend le premier ecran de l espace d un role.
  static String accueil(Role role) => switch (role) {
        Role.convive => '$convive/accueil',
        Role.parent => '$parent/famille',
        Role.agent => '$agent/collecte',
        Role.admin => '$admin/tableau-bord',
      };
}

/// Le routeur de l application, reconstruit a chaque changement de session.
final Provider<GoRouter> routeurProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> changements = ValueNotifier<int>(0);
  ref.listen<AsyncValue<Session?>>(
    sessionProvider,
    (AsyncValue<Session?>? avant, AsyncValue<Session?> apres) => changements.value++,
  );
  ref.onDispose(changements.dispose);

  return GoRouter(
    initialLocation: Chemins.bienvenue,
    refreshListenable: changements,
    redirect: (BuildContext contexte, GoRouterState etat) {
      final AsyncValue<Session?> session = ref.read(sessionProvider);
      if (session.isLoading) {
        // Tant que la session se relit, on ne deplace personne.
        return null;
      }
      final Session? ouverte = session.value;
      final String chemin = etat.uri.path;
      if (ouverte == null) {
        return Chemins.publics.contains(chemin) ? null : Chemins.bienvenue;
      }
      if (!ouverte.profilComplet && chemin != Chemins.finaliserProfil) {
        return Chemins.finaliserProfil;
      }
      final String racine = Chemins.racine(ouverte.role);
      if (!chemin.startsWith(racine)) {
        return Chemins.accueil(ouverte.role);
      }
      return null;
    },
    errorBuilder: (BuildContext contexte, GoRouterState etat) => const _EcranIntrouvable(),
    routes: <RouteBase>[
      GoRoute(
        path: Chemins.bienvenue,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranBienvenue(),
      ),
      GoRoute(
        path: Chemins.finaliserProfil,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranFinaliserProfil(),
      ),
      GoRoute(
        path: Chemins.visiteur,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranVisiteur(),
      ),
      GoRoute(
        path: Chemins.inscription,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranInscription(),
      ),
      GoRoute(
        path: Chemins.connexion,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranConnexion(),
      ),
      GoRoute(
        path: Chemins.motDePasseOublie,
        builder: (BuildContext contexte, GoRouterState etat) => const EcranMotDePasseOublie(),
      ),
      GoRoute(
        path: Chemins.code,
        builder: (BuildContext contexte, GoRouterState etat) {
          final Object? arguments = etat.extra;
          if (arguments is! ArgumentsCode) {
            // Sans argument, l ecran du code n a rien a verifier : on repart de l accueil.
            return const EcranBienvenue();
          }
          return EcranCode(arguments: arguments);
        },
      ),
      _coquilleConvive(),
      _coquilleParent(),
      _coquilleAgent(),
      _coquilleAdmin(),
    ],
  );
});

StatefulShellRoute _coquilleConvive() {
  return StatefulShellRoute.indexedStack(
    builder: (BuildContext contexte, GoRouterState etat, StatefulNavigationShell shell) {
      final Traductions mots = Traductions.of(contexte);
      return Coquille(
        shell: shell,
        titre: mots.nomApplication,
        destinations: <DestinationOnglet>[
          DestinationOnglet(
            libelle: mots.ongletAccueil,
            icone: Icons.home_outlined,
            iconeActive: Icons.home,
          ),
          DestinationOnglet(
            libelle: mots.ongletMenu,
            icone: Icons.restaurant_outlined,
            iconeActive: Icons.restaurant,
          ),
          DestinationOnglet(
            libelle: mots.ongletTicket,
            icone: Icons.qr_code_2_outlined,
            iconeActive: Icons.qr_code_2,
          ),
          DestinationOnglet(
            libelle: mots.ongletCompte,
            icone: Icons.person_outline,
            iconeActive: Icons.person,
          ),
        ],
      );
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.convive}/accueil',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranAccueil(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.convive}/menu',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranMenu(),
            routes: <RouteBase>[
              GoRoute(
                path: 'commander',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranCommande(),
              ),
              GoRoute(
                path: 'plat',
                builder: (BuildContext contexte, GoRouterState etat) {
                  final Object? plat = etat.extra;
                  if (plat is! Plat) {
                    // Sans plat a montrer, on reste sur le menu.
                    return const EcranMenu();
                  }
                  return EcranFichePlat(plat: plat);
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.convive}/ticket',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranMesCommandes(),
            routes: <RouteBase>[
              GoRoute(
                path: 'noter',
                builder: (BuildContext contexte, GoRouterState etat) {
                  final Object? commande = etat.extra;
                  if (commande is! Commande) {
                    return const EcranMesCommandes();
                  }
                  return EcranAppreciation(commande: commande);
                },
              ),
              GoRoute(
                path: 'billet',
                builder: (BuildContext contexte, GoRouterState etat) {
                  final Object? commande = etat.extra;
                  return EcranTicket(commande: commande is Commande ? commande : null);
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.convive}/compte',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranCompte(),
            routes: <RouteBase>[
              GoRoute(
                path: 'porte-monnaie',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranPorteMonnaie(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranNotifications(),
              ),
              // Tout convive recharge son propre porte-monnaie, quel que soit son statut,
              // et peut se faire payer par un proche avec un lien.
              GoRoute(
                path: 'recharge',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranRecharge(),
              ),
              GoRoute(
                path: 'lien-paiement',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranLienPaiement(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

StatefulShellRoute _coquilleParent() {
  return StatefulShellRoute.indexedStack(
    builder: (BuildContext contexte, GoRouterState etat, StatefulNavigationShell shell) {
      final Traductions mots = Traductions.of(contexte);
      return Coquille(
        shell: shell,
        titre: mots.ongletFamille,
        destinations: <DestinationOnglet>[
          DestinationOnglet(
            libelle: mots.ongletFamille,
            icone: Icons.family_restroom_outlined,
            iconeActive: Icons.family_restroom,
          ),
          DestinationOnglet(
            libelle: mots.ongletRecharge,
            icone: Icons.account_balance_wallet_outlined,
            iconeActive: Icons.account_balance_wallet,
          ),
          DestinationOnglet(
            libelle: mots.ongletMessages,
            icone: Icons.forum_outlined,
            iconeActive: Icons.forum,
          ),
          DestinationOnglet(
            libelle: mots.ongletProfil,
            icone: Icons.person_outline,
            iconeActive: Icons.person,
          ),
        ],
      );
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.parent}/famille',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranFamille(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.parent}/recharge',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranRecharge(),
            routes: <RouteBase>[
              GoRoute(
                path: 'lien-paiement',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranLienPaiement(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.parent}/messages',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranMessages(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.parent}/profil',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranCompte(),
          ),
        ],
      ),
    ],
  );
}

StatefulShellRoute _coquilleAgent() {
  return StatefulShellRoute.indexedStack(
    builder: (BuildContext contexte, GoRouterState etat, StatefulNavigationShell shell) {
      final Traductions mots = Traductions.of(contexte);
      return Coquille(
        shell: shell,
        titre: mots.ongletCollecte,
        destinations: <DestinationOnglet>[
          DestinationOnglet(
            libelle: mots.ongletCollecte,
            icone: Icons.qr_code_scanner_outlined,
            iconeActive: Icons.qr_code_scanner,
          ),
          DestinationOnglet(
            libelle: mots.ongletManifeste,
            icone: Icons.checklist_outlined,
            iconeActive: Icons.checklist,
          ),
          DestinationOnglet(
            libelle: mots.ongletReglages,
            icone: Icons.tune_outlined,
            iconeActive: Icons.tune,
          ),
        ],
      );
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.agent}/collecte',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranCollecte(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.agent}/manifeste',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranManifeste(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.agent}/reglages',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranReglagesPoste(),
          ),
        ],
      ),
    ],
  );
}

StatefulShellRoute _coquilleAdmin() {
  return StatefulShellRoute.indexedStack(
    builder: (BuildContext contexte, GoRouterState etat, StatefulNavigationShell shell) {
      final Traductions mots = Traductions.of(contexte);
      return Coquille(
        shell: shell,
        titre: mots.ongletTableauBord,
        destinations: <DestinationOnglet>[
          DestinationOnglet(
            libelle: mots.ongletTableauBord,
            icone: Icons.insights_outlined,
            iconeActive: Icons.insights,
          ),
          DestinationOnglet(
            libelle: mots.ongletCuisine,
            icone: Icons.soup_kitchen_outlined,
            iconeActive: Icons.soup_kitchen,
          ),
          DestinationOnglet(
            libelle: mots.ongletMenus,
            icone: Icons.menu_book_outlined,
            iconeActive: Icons.menu_book,
          ),
          DestinationOnglet(
            libelle: mots.ongletReglages,
            icone: Icons.tune_outlined,
            iconeActive: Icons.tune,
          ),
        ],
      );
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.admin}/tableau-bord',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranTableauBord(),
            routes: <RouteBase>[
              GoRoute(
                path: 'budget',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranBudget(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.admin}/cuisine',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranCuisine(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.admin}/menus',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranMenusAdmin(),
            routes: <RouteBase>[
              GoRoute(
                path: 'plats',
                builder: (BuildContext contexte, GoRouterState etat) => const EcranPlatsAdmin(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '${Chemins.admin}/exploitation',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranExploitation(),
          ),
          GoRoute(
            path: '${Chemins.admin}/reglages',
            builder: (BuildContext contexte, GoRouterState etat) => const EcranReglagesAdmin(),
          ),
        ],
      ),
    ],
  );
}

class _EcranIntrouvable extends StatelessWidget {
  const _EcranIntrouvable();

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Mesures.marge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TexteAdapte(
                mots.pageIntrouvable,
                maxLignes: 2,
                alignement: TextAlign.center,
                style: Theme.of(contexte).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => contexte.go(Chemins.bienvenue),
                child: Text(mots.retourAccueil),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
