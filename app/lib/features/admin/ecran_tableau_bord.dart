// Role du fichier : le tableau de bord du back office.
// Tuiles, courbe des sept derniers jours, plats les plus commandés, et l ajustement d un solde.
// Les frais GeniusPay sont montrés à côté des recettes : l exploitant doit voir ce qu il supporte.

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
import 'donnees/service_tableau_bord.dart';

/// Le tableau de bord de l administration.
class EcranTableauBord extends ConsumerWidget {
  /// Construit le tableau de bord.
  const EcranTableauBord({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final AsyncValue<ChiffresBord> chiffres = ref.watch(chiffresBordProvider);
    final TypeEcran type = TypeEcran.de(contexte);
    final int colonnes = type.estTelephone ? 2 : 3;

    return ListView(
      padding: const EdgeInsets.all(Mesures.marge),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TexteAdapte(
                mots.ongletTableauBord,
                style: Theme.of(contexte).textTheme.headlineLarge,
              ),
            ),
            IconButton(
              onPressed: () => _ouvrirAjustement(contexte, ref),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: mots.ajusterSolde,
            ),
          ],
        ),
        const SizedBox(height: 14),
        chiffres.when(
          loading: () => const Column(
            children: <Widget>[CarteSquelette(hauteur: 92), SizedBox(height: 10), CarteSquelette(hauteur: 160)],
          ),
          error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
          data: (ChiffresBord bord) {
            if (bord.estVide) {
              return EtatVide(titre: mots.etatVideTitre, icone: Icons.insights_outlined);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GridView.count(
                  crossAxisCount: colonnes,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: <Widget>[
                    _Tuile(titre: mots.repasServis, valeur: '${bord.repasServis}'),
                    _Tuile(titre: mots.nonReclames, valeur: '${bord.nonReclames}', alerte: true),
                    _Tuile(titre: mots.recettesBrutes, valeur: formaterXof(bord.recettesBrutesXof)),
                    _Tuile(titre: mots.fraisGeniusPay, valeur: formaterXof(bord.fraisXof), alerte: true),
                    _Tuile(titre: mots.netAttendu, valeur: formaterXof(bord.netXof), accent: true),
                  ],
                ),
                const SizedBox(height: 20),
                TexteAdapte(
                  mots.septDerniersJours,
                  style: Theme.of(contexte).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                _Courbe(valeurs: bord.parJour),
                const SizedBox(height: 20),
                TexteAdapte(
                  mots.platsLesPlusReserves,
                  style: Theme.of(contexte).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                for (final LigneCuisine plat in bord.platsFavoris)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TexteAdapte(
                            plat.plat,
                            style: Theme.of(contexte).textTheme.titleMedium,
                          ),
                        ),
                        TexteAdapte(
                          '${plat.parts}',
                          style: Theme.of(contexte).textTheme.titleMedium,
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

  Future<void> _ouvrirAjustement(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController convive = TextEditingController();
    final TextEditingController montant = TextEditingController();
    final TextEditingController motif = TextEditingController();
    final TextEditingController motDePasse = TextEditingController();
    String sens = 'credit';
    String? message;

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.ajusterSolde,
      contenu: (BuildContext contexteFeuille) => StatefulBuilder(
        builder: (BuildContext contexteFeuille, StateSetter rafraichir) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: convive,
              decoration: InputDecoration(labelText: mots.identifiantConvive),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(mots.crediter),
                  selected: sens == 'credit',
                  onSelected: (_) => rafraichir(() => sens = 'credit'),
                ),
                ChoiceChip(
                  label: Text(mots.debiter),
                  selected: sens == 'debit',
                  onSelected: (_) => rafraichir(() => sens = 'debit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montant,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: mots.montant, suffixText: 'F'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motif,
              decoration: InputDecoration(labelText: mots.motif),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motDePasse,
              obscureText: true,
              decoration: InputDecoration(labelText: mots.motDePasseActions),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              TexteAdapte(message!, maxLignes: 3),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: Mesures.hauteurBouton,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(serviceBordProvider).ajusterSolde(
                          utilisateurId: convive.text.trim(),
                          sens: sens,
                          montantXof: int.tryParse(montant.text) ?? 0,
                          motif: motif.text.trim(),
                          motDePasseActions: motDePasse.text,
                        );
                    Haptique.succes();
                    rafraichir(() => message = mots.ajustementFait);
                  } on ErreurApi catch (echec) {
                    Haptique.refus();
                    rafraichir(() => message =
                        echec.message.isEmpty ? mots.erreurTitre : echec.message);
                  }
                },
                child: Text(mots.appliquer),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({
    required this.titre,
    required this.valeur,
    this.accent = false,
    this.alerte = false,
  });

  final String titre;
  final String valeur;
  final bool accent;
  final bool alerte;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final Color fond = accent
        ? couleurs.contraste
        : (alerte ? couleurs.muet : couleurs.surface);
    final Color texte = accent ? couleurs.surContraste : couleurs.texte;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: accent ? couleurs.contraste : couleurs.filet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TexteAdapte(
            titre,
            style: Theme.of(contexte).textTheme.labelMedium?.copyWith(
                  color: accent ? couleurs.surContrasteAttenue : couleurs.texteSecondaire,
                ),
          ),
          const SizedBox(height: 6),
          TexteAdapte(
            valeur,
            style: Theme.of(contexte).textTheme.headlineMedium?.copyWith(color: texte),
          ),
        ],
      ),
    );
  }
}

/// La courbe des sept derniers jours, dessinée, jamais une image.
class _Courbe extends StatelessWidget {
  const _Courbe({required this.valeurs});

  final List<int> valeurs;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    if (valeurs.isEmpty) {
      return const SizedBox.shrink();
    }
    final int sommet = valeurs.reduce((int a, int b) => a > b ? a : b);
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: couleurs.filet),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final int valeur in valeurs)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TexteAdapte(
                      '$valeur',
                      style: Theme.of(contexte).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: sommet == 0 ? 2 : (valeur / sommet) * 86 + 2,
                      decoration: BoxDecoration(
                        color: couleurs.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
