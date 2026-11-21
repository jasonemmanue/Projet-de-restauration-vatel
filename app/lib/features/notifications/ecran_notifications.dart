// Role du fichier : le centre de notifications, dans l application.
// Les notifications poussees arrivent par Firebase ; celles-ci viennent du serveur et restent
// lisibles hors ligne, depuis le cache.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_notifications.dart';

/// Les notifications recues par l utilisateur.
class EcranNotifications extends ConsumerStatefulWidget {
  /// Construit le centre de notifications.
  const EcranNotifications({super.key});

  @override
  ConsumerState<EcranNotifications> createState() => _EtatEcranNotifications();
}

class _EtatEcranNotifications extends ConsumerState<EcranNotifications> {
  @override
  void initState() {
    super.initState();
    // Le branchement est demande a l ouverture de l ecran, pas au demarrage de l application :
    // on ne reclame pas une autorisation avant que l utilisateur comprenne pourquoi.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(serviceNotificationsProvider).brancher(),
    );
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<List<NotificationRecue>> notifications = ref.watch(notificationsProvider);

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        TexteAdapte(mots.ongletNotifications, style: Theme.of(contexte).textTheme.headlineLarge),
        const SizedBox(height: 16),
        notifications.when(
          loading: () => const Column(
            children: <Widget>[CarteSquelette(hauteur: 80), SizedBox(height: 10), CarteSquelette(hauteur: 80)],
          ),
          error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
          data: (List<NotificationRecue> liste) {
            if (liste.isEmpty) {
              return EtatVide(titre: mots.etatVideTitre, icone: Icons.notifications_none);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final NotificationRecue notification in liste)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: notification.lue ? couleurs.surface : couleurs.accentDoux,
                      borderRadius: BorderRadius.circular(Mesures.rayonCarte),
                      border: Border.all(color: couleurs.filet),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TexteAdapte(
                                notification.titre,
                                style: Theme.of(contexte).textTheme.titleMedium,
                              ),
                            ),
                            TexteAdapte(
                              formaterHeure(notification.recueLe),
                              style: Theme.of(contexte).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TexteAdapte(
                          notification.corps,
                          maxLignes: 3,
                          style: Theme.of(contexte).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
