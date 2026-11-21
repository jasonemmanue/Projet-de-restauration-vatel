// Role du fichier : le comptoir de l agent. Scan continu, résultat plein écran vert ou rouge,
// saisie manuelle, et une pastille qui dit combien de scans attendent le réseau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/hors_ligne/file_envoi.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/feuille_bas.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_agent.dart';

/// L écran de scan de l agent.
class EcranCollecte extends ConsumerStatefulWidget {
  /// Construit l écran de collecte.
  const EcranCollecte({super.key});

  @override
  ConsumerState<EcranCollecte> createState() => _EtatEcranCollecte();
}

class _EtatEcranCollecte extends ConsumerState<EcranCollecte> {
  final MobileScannerController _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  ResultatScan? _resultat;
  String _dernierCode = '';
  bool _enCours = false;

  @override
  void dispose() {
    unawaited(_camera.dispose());
    super.dispose();
  }

  Future<void> _traiter(String code) async {
    if (_enCours || code.isEmpty || code == _dernierCode) {
      return;
    }
    setState(() {
      _enCours = true;
      _dernierCode = code;
    });
    final List<TicketDuJour> liste = ref.read(listeDuJourProvider).value ?? const <TicketDuJour>[];
    final ResultatScan resultat = await ref.read(serviceAgentProvider).scanner(code, liste);
    if (!mounted) {
      return;
    }
    if (resultat.estVert) {
      Haptique.succes();
    } else {
      Haptique.refus();
    }
    setState(() {
      _resultat = resultat;
      _enCours = false;
    });
  }

  void _fermerResultat() {
    setState(() {
      _resultat = null;
      _dernierCode = '';
    });
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool enLigne = ref.watch(etatReseauProvider);
    final int enAttente = ref.watch(fileEnvoiProvider).length;
    final ResultatScan? resultat = _resultat;

    if (resultat != null) {
      return _EcranResultat(resultat: resultat, onFermer: _fermerResultat);
    }

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (!enLigne)
              Container(
                width: double.infinity,
                color: couleurs.alerte,
                padding: const EdgeInsets.symmetric(horizontal: Mesures.marge, vertical: 10),
                child: TexteAdapte(
                  mots.scansAEnvoyer(enAttente),
                  maxLignes: 2,
                  alignement: TextAlign.center,
                  style: Theme.of(contexte)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: couleurs.contraste),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Mesures.marge),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Mesures.rayonGrand),
                  child: MobileScanner(
                    controller: _camera,
                    onDetect: (BarcodeCapture capture) {
                      final String? code = capture.barcodes.isEmpty
                          ? null
                          : capture.barcodes.first.rawValue;
                      if (code != null) {
                        unawaited(_traiter(code));
                      }
                    },
                    errorBuilder: (BuildContext contexte, MobileScannerException echec) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Mesures.marge),
                        child: TexteAdapte(
                          mots.saisieManuelle,
                          maxLignes: 2,
                          alignement: TextAlign.center,
                          style: Theme.of(contexte).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Mesures.marge,
                0,
                Mesures.marge,
                Mesures.marge,
              ),
              child: SizedBox(
                height: Mesures.hauteurBouton,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _saisirAlaMain(contexte),
                  icon: const Icon(Icons.keyboard_alt_outlined),
                  label: Text(mots.saisieManuelle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saisirAlaMain(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController code = TextEditingController();
    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.saisieManuelle,
      contenu: (BuildContext contexteFeuille) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: mots.codeDuTicket),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: Mesures.hauteurBouton,
            child: FilledButton(
              onPressed: () {
                Navigator.of(contexteFeuille).pop();
                unawaited(_traiter(code.text.trim()));
              },
              child: Text(mots.valider),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _EcranResultat extends StatelessWidget {
  const _EcranResultat({required this.resultat, required this.onFermer});

  final ResultatScan resultat;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool vert = resultat.estVert;
    final String libelle = switch (resultat) {
      ResultatScan.accepte => mots.scanAccepte,
      ResultatScan.dejaServi => mots.scanDejaServi,
      ResultatScan.inconnu => mots.scanInconnu,
      ResultatScan.mauvaisJour => mots.scanMauvaisJour,
      ResultatScan.annulee => mots.scanAnnule,
    };

    return Scaffold(
      backgroundColor: vert ? couleurs.succes : couleurs.danger,
      body: GestureDetector(
        onTap: onFermer,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    vert ? Icons.check_circle : Icons.cancel,
                    size: 110,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  TexteAdapte(
                    libelle,
                    maxLignes: 2,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TexteAdapte(
                    mots.toucherPourContinuer,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
