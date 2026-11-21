// Role du fichier : le ticket QR du jour, celui que l agent scanne au comptoir.
// Le code reste noir sur fond blanc dans les deux modes, sinon les lecteurs ne le voient pas.
// Un toucher passe en plein écran, un autre en sort : c est ce qu on fait devant la caisse.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/outils/plein_ecran.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../menus/ecran_menu.dart';
import 'donnees/service_commandes.dart';

/// Le ticket QR d une commande.
class EcranTicket extends ConsumerStatefulWidget {
  /// Construit l écran du ticket.
  const EcranTicket({super.key, this.commande});

  /// La commande montrée. Vide, on prend celle du jour.
  final Commande? commande;

  @override
  ConsumerState<EcranTicket> createState() => _EtatEcranTicket();
}

class _EtatEcranTicket extends ConsumerState<EcranTicket> {
  bool _pleinEcran = false;

  Future<void> _basculer() async {
    Haptique.leger();
    setState(() => _pleinEcran = !_pleinEcran);
    await PleinEcran.basculer();
  }

  @override
  void dispose() {
    if (_pleinEcran) {
      // On ne laisse jamais l application en plein écran derrière soi.
      unawaited(PleinEcran.quitter());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<List<Commande>> toutes = ref.watch(mesCommandesProvider);
    final bool enLigne = ref.watch(etatReseauProvider);

    final Commande? commande = widget.commande ??
        toutes.value?.where((Commande c) => memeJour(c.date, DateTime.now())).firstOrNull;

    if (commande == null) {
      return Scaffold(
        backgroundColor: couleurs.fond,
        body: EtatVide(titre: mots.aucuneCommande, icone: Icons.qr_code_2_outlined),
      );
    }

    final Widget carte = _CarteTicket(commande: commande, pleinEcran: _pleinEcran);

    if (_pleinEcran) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: _basculer,
          child: Center(child: carte),
        ),
      );
    }

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Mesures.marge),
          children: <Widget>[
            if (!enLigne) const BandeauHorsLigne(),
            const SizedBox(height: 10),
            TexteAdapte(mots.ongletTicket, style: Theme.of(contexte).textTheme.headlineLarge),
            const SizedBox(height: 6),
            TexteAdapte(
              '${nomDuJour(mots, commande.date)} ${commande.date.day}',
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            GestureDetector(onTap: _basculer, child: carte),
            const SizedBox(height: 16),
            if (commande.plats.isNotEmpty)
              TexteAdapte(
                commande.plats.join(', '),
                maxLignes: 3,
                alignement: TextAlign.center,
                style: Theme.of(contexte).textTheme.bodyLarge,
              ),
            const SizedBox(height: 10),
            TexteAdapte(
              formaterXof(commande.totalXof),
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CarteTicket extends StatelessWidget {
  const _CarteTicket({required this.commande, required this.pleinEcran});

  final Commande commande;
  final bool pleinEcran;

  @override
  Widget build(BuildContext contexte) {
    final double cote = pleinEcran
        ? MediaQuery.sizeOf(contexte).shortestSide * 0.82
        : MediaQuery.sizeOf(contexte).shortestSide * 0.62;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Noir sur blanc, en clair comme en sombre : un lecteur ne pardonne pas l inversion.
          color: Colors.white,
          borderRadius: BorderRadius.circular(Mesures.rayonGrand),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            QrImageView(
              data: commande.codeTicket,
              version: QrVersions.auto,
              size: cote,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              commande.codeTicket,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
