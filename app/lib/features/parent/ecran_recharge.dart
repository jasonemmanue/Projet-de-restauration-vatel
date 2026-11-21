// Role du fichier : recharger un porte-monnaie par Mobile Money, et faire payer par un proche.
// L application ouvre la page de GeniusPay puis revient demander au serveur l etat du paiement.
// Rien n est credite ici : le solde suit ce que le serveur repond.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/coquille.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../porte_monnaie/donnees/service_paiements.dart';
import '../porte_monnaie/donnees/service_porte_monnaie.dart';

/// Les montants proposes d un toucher.
const List<int> montantsRapides = <int>[1000, 2000, 5000, 10000, 20000];

/// L ecran de recharge.
class EcranRecharge extends ConsumerStatefulWidget {
  /// Construit l ecran de recharge.
  const EcranRecharge({super.key, this.beneficiaireId, this.titreBeneficiaire});

  /// Le compte a crediter. Vide, c est le sien.
  final String? beneficiaireId;

  /// Nom du beneficiaire, quand ce n est pas soi.
  final String? titreBeneficiaire;

  @override
  ConsumerState<EcranRecharge> createState() => _EtatEcranRecharge();
}

class _EtatEcranRecharge extends ConsumerState<EcranRecharge> {
  final TextEditingController _montant = TextEditingController(text: '2000');
  final TextEditingController _telephone = TextEditingController();
  Operateur _operateur = Operateur.wave;
  bool _enCours = false;
  String? _message;
  String? _paiementEnCours;

  @override
  void dispose() {
    _montant.dispose();
    _telephone.dispose();
    super.dispose();
  }

  int get _montantXof => int.tryParse(_montant.text) ?? 0;

  Future<void> _recharger() async {
    setState(() {
      _enCours = true;
      _message = null;
    });
    try {
      final RechargeLancee lancee = await ref.read(servicePaiementsProvider).recharger(
            montantXof: _montantXof,
            operateur: _operateur,
            telephonePayeur: _telephone.text.trim(),
            beneficiaireId: widget.beneficiaireId,
          );
      ref.read(modeTestProvider.notifier).poser(test: lancee.estTest);
      _paiementEnCours = lancee.paiementId;
      if (lancee.urlRedirection.isNotEmpty) {
        await launchUrl(
          Uri.parse(lancee.urlRedirection),
          mode: LaunchMode.externalApplication,
        );
      }
      if (mounted) {
        setState(() => _message = Traductions.of(context).paiementOuvert);
      }
    } on ErreurApi catch (echec) {
      Haptique.refus();
      if (mounted) {
        setState(
          () => _message =
              echec.message.isEmpty ? Traductions.of(context).erreurReseau : echec.message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  Future<void> _verifier() async {
    final String? paiement = _paiementEnCours;
    if (paiement == null) {
      return;
    }
    setState(() => _enCours = true);
    final String etat = await ref.read(servicePaiementsProvider).etatPaiement(paiement);
    ref.invalidate(soldeProvider);
    ref.invalidate(mouvementsProvider);
    if (!mounted) {
      return;
    }
    final Traductions mots = Traductions.of(context);
    setState(() {
      _enCours = false;
      _message = switch (etat) {
        'reussi' => mots.paiementReussi,
        'echoue' => mots.paiementEchoue,
        _ => mots.paiementEnAttente,
      };
    });
    if (etat == 'reussi') {
      Haptique.succes();
    }
  }

  Future<void> _partagerLien() async {
    setState(() {
      _enCours = true;
      _message = null;
    });
    try {
      final LienPaiement lien = await ref.read(servicePaiementsProvider).creerLien(
            montantXof: _montantXof,
            message: Traductions.of(context).messageLienDefaut,
            beneficiaireId: widget.beneficiaireId,
          );
      if (!mounted) {
        return;
      }
      final String texte = Uri.encodeComponent(
        '${Traductions.of(context).messageLienDefaut} ${lien.url}',
      );
      await launchUrl(
        Uri.parse('https://wa.me/?text=$texte'),
        mode: LaunchMode.externalApplication,
      );
    } on ErreurApi catch (echec) {
      if (mounted) {
        setState(
          () => _message =
              echec.message.isEmpty ? Traductions.of(context).erreurReseau : echec.message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool enLigne = ref.watch(etatReseauProvider);
    final bool modeTest = ref.watch(modeTestProvider);
    final bool pret = _montantXof >= 500 && _telephone.text.trim().length >= 8;

    return Scaffold(
      backgroundColor: couleurs.fond,
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          if (!enLigne) const BandeauHorsLigne(),
          Row(
            children: <Widget>[
              Expanded(
                child: TexteAdapte(
                  widget.titreBeneficiaire ?? mots.ongletRecharge,
                  style: Theme.of(contexte).textTheme.headlineLarge,
                ),
              ),
              if (modeTest) const BadgeModeTest(),
            ],
          ),
          const SizedBox(height: 16),
          TexteAdapte(mots.montant, style: Theme.of(contexte).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int montant in montantsRapides)
                ChoiceChip(
                  label: Text(formaterXof(montant)),
                  selected: _montantXof == montant,
                  onSelected: (_) => setState(() => _montant.text = '$montant'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montant,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: mots.montant, suffixText: 'F'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          TexteAdapte(mots.operateur, style: Theme.of(contexte).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final Operateur operateur in Operateur.values)
                ChoiceChip(
                  label: Text(operateur.libelle),
                  selected: _operateur == operateur,
                  onSelected: (_) => setState(() => _operateur = operateur),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _telephone,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: mots.telephonePayeur,
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+225 ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_message != null) ...<Widget>[
            const SizedBox(height: 14),
            TexteAdapte(
              _message!,
              maxLignes: 3,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyLarge?.copyWith(color: couleurs.accent),
            ),
          ],
          if (_paiementEnCours != null) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: Mesures.hauteurBouton,
              child: OutlinedButton.icon(
                onPressed: _enCours ? null : _verifier,
                icon: const Icon(Icons.refresh),
                label: Text(mots.verifierPaiement),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: Mesures.hauteurBouton,
            child: OutlinedButton.icon(
              onPressed: _enCours || !enLigne || _montantXof < 500 ? null : _partagerLien,
              icon: const Icon(Icons.ios_share),
              label: Text(mots.faireePayerParUnProche),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.recharger,
        enCours: _enCours,
        onPressed: pret && enLigne ? _recharger : null,
        raisonIndisponible: enLigne ? null : mots.actionImpossibleHorsLigne,
      ),
    );
  }
}
