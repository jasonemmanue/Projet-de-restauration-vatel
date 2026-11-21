// Role du fichier : la famille du parent. Un enfant par carte : son solde, son repas du jour,
// son seuil d alerte, et le bouton qui recharge son compte.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/feuille_bas.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_parent.dart';
import 'ecran_recharge.dart';

/// La liste des enfants lies au parent.
class EcranFamille extends ConsumerWidget {
  /// Construit l ecran famille.
  const EcranFamille({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final AsyncValue<List<Enfant>> enfants = ref.watch(enfantsProvider);

    return Scaffold(
      backgroundColor: contexte.couleurs.fond,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _lier(contexte, ref),
        icon: const Icon(Icons.person_add_alt),
        label: Text(mots.lierEnfant),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.famille, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 16),
          enfants.when(
            loading: () => const Column(
              children: <Widget>[CarteSquelette(hauteur: 140), SizedBox(height: 12), CarteSquelette(hauteur: 140)],
            ),
            error: (Object _, StackTrace _) => EtatVide(titre: mots.aucunEnfant),
            data: (List<Enfant> liste) {
              if (liste.isEmpty) {
                return EtatVide(titre: mots.aucunEnfant, icone: Icons.family_restroom_outlined);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final Enfant enfant in liste) ...<Widget>[
                    _CarteEnfant(enfant: enfant),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Future<void> _lier(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController code = TextEditingController();
    String? message;

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.lierEnfant,
      contenu: (BuildContext contexteFeuille) => StatefulBuilder(
        builder: (BuildContext contexteFeuille, StateSetter rafraichir) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: mots.codeLiaison,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              TexteAdapte(message!, maxLignes: 3, alignement: TextAlign.center),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: Mesures.hauteurBouton,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(serviceParentProvider).lier(code.text);
                    Haptique.succes();
                    ref.invalidate(enfantsProvider);
                    if (contexteFeuille.mounted) {
                      Navigator.of(contexteFeuille).pop();
                    }
                  } on ErreurApi catch (echec) {
                    Haptique.refus();
                    rafraichir(
                      () => message = echec.message.isEmpty ? mots.erreurTitre : echec.message,
                    );
                  }
                },
                child: Text(mots.valider),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _CarteEnfant extends ConsumerWidget {
  const _CarteEnfant({required this.enfant});

  final Enfant enfant;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;

    return Container(
      padding: const EdgeInsets.all(Mesures.marge),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: enfant.soldeBas ? couleurs.alerte : couleurs.filet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TexteAdapte(
                  '${enfant.prenom} ${enfant.nom}',
                  style: Theme.of(contexte).textTheme.titleLarge,
                ),
              ),
              TexteAdapte(
                formaterXof(enfant.soldeXof),
                style: Theme.of(contexte).textTheme.titleLarge?.copyWith(
                      color: enfant.soldeBas ? couleurs.alerte : couleurs.accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TexteAdapte(
            enfant.repasDuJour.isEmpty ? mots.aucunRepasDuJour : enfant.repasDuJour,
            maxLignes: 2,
            style: Theme.of(contexte).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: Mesures.cibleTactile,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(contexte).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => EcranRecharge(
                          beneficiaireId: enfant.id,
                          titreBeneficiaire: mots.rechargerPour(enfant.prenom),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(mots.recharger),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: Mesures.cibleTactile,
                child: OutlinedButton(
                  onPressed: () => _poserSeuil(contexte, ref),
                  child: Text(mots.seuilAlerte),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _poserSeuil(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController seuil =
        TextEditingController(text: '${enfant.seuilAlerteXof ?? 1000}');

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.seuilAlerte,
      contenu: (BuildContext contexteFeuille) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: seuil,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: mots.seuilAlerte, suffixText: 'F'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: Mesures.hauteurBouton,
            child: FilledButton(
              onPressed: () async {
                await ref
                    .read(serviceParentProvider)
                    .poserSeuil(enfant.id, int.tryParse(seuil.text) ?? 0);
                ref.invalidate(enfantsProvider);
                if (contexteFeuille.mounted) {
                  Navigator.of(contexteFeuille).pop();
                }
              },
              child: Text(mots.enregistrer),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
