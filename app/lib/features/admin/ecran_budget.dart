// Role du fichier : le budget de la cantine, vu par l administration.
// Tuiles, calendrier du mois, évolution, répartition des sorties, et saisie d une ligne.
// Les lignes automatiques, paiements et frais, ne se modifient pas : le serveur les écrit.

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
import 'donnees/service_budget.dart';

/// Le budget et les finances de la cantine.
class EcranBudget extends ConsumerWidget {
  /// Construit l écran du budget.
  const EcranBudget({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<ResumeBudget> budget = ref.watch(budgetProvider);
    final TypeEcran type = TypeEcran.de(contexte);

    return Scaffold(
      backgroundColor: couleurs.fond,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saisir(contexte, ref),
        icon: const Icon(Icons.add),
        label: Text(mots.nouvelleEntree),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.budgetTitre, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 8),
          TexteAdapte(
            mots.budgetExplication,
            maxLignes: 3,
            style: Theme.of(contexte).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          budget.when(
            loading: () => const Column(
              children: <Widget>[CarteSquelette(hauteur: 96), SizedBox(height: 10), CarteSquelette(hauteur: 150)],
            ),
            error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
            data: (ResumeBudget resume) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GridView.count(
                  crossAxisCount: type.estTelephone ? 2 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: <Widget>[
                    _Tuile(
                      titre: mots.soldeGlobal,
                      valeur: formaterXof(resume.soldeGlobalXof),
                      negatif: resume.soldeGlobalXof < 0,
                    ),
                    _Tuile(titre: mots.totalEntrees, valeur: formaterXof(resume.entreesXof), positif: true),
                    _Tuile(titre: mots.totalSorties, valeur: formaterXof(resume.sortiesXof), negatif: true),
                    _Tuile(
                      titre: mots.soldeCeMois,
                      valeur: formaterXof(resume.soldeMoisXof),
                      negatif: resume.soldeMoisXof < 0,
                    ),
                    _Tuile(
                      titre: mots.entreesCeMois,
                      valeur: formaterXof(resume.entreesMoisXof),
                      positif: true,
                    ),
                    _Tuile(
                      titre: mots.sortiesCeMois,
                      valeur: formaterXof(resume.sortiesMoisXof),
                      negatif: true,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TexteAdapte(
                  mots.calendrierBudget,
                  style: Theme.of(contexte).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const _Calendrier(),
                const SizedBox(height: 22),
                if (resume.sortiesParCategorie.isNotEmpty) ...<Widget>[
                  TexteAdapte(
                    mots.repartitionSorties,
                    style: Theme.of(contexte).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  for (final MapEntry<String, int> part in resume.sortiesParCategorie.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TexteAdapte(
                              part.key,
                              style: Theme.of(contexte).textTheme.titleMedium,
                            ),
                          ),
                          TexteAdapte(
                            formaterXof(part.value),
                            style: Theme.of(contexte).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                if (resume.lignes.isEmpty)
                  EtatVide(titre: mots.etatVideTitre, icone: Icons.account_balance_outlined)
                else
                  for (final LigneBudget ligne in resume.lignes) _Ligne(ligne: ligne),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Future<void> _saisir(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController montant = TextEditingController();
    final TextEditingController libelle = TextEditingController();
    String sens = 'sortie';
    String categorie = 'charge';
    String? message;

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.nouvelleEntree,
      contenu: (BuildContext contexteFeuille) => StatefulBuilder(
        builder: (BuildContext contexteFeuille, StateSetter rafraichir) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(mots.entree),
                  selected: sens == 'entree',
                  onSelected: (_) => rafraichir(() => sens = 'entree'),
                ),
                ChoiceChip(
                  label: Text(mots.sortie),
                  selected: sens == 'sortie',
                  onSelected: (_) => rafraichir(() => sens = 'sortie'),
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
              controller: libelle,
              decoration: InputDecoration(labelText: mots.motif),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final String choix in <String>[
                  'achat_cuisine',
                  'salaire',
                  'charge',
                  'equipement',
                  'autre',
                ])
                  ChoiceChip(
                    label: Text(choix.replaceAll('_', ' ')),
                    selected: categorie == choix,
                    onSelected: (_) => rafraichir(() => categorie = choix),
                  ),
              ],
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
                    await ref.read(serviceBudgetProvider).ajouter(
                          date: DateTime.now(),
                          sens: sens,
                          montantXof: int.tryParse(montant.text) ?? 0,
                          categorie: categorie,
                          libelle: libelle.text.trim(),
                        );
                    Haptique.succes();
                    ref.invalidate(budgetProvider);
                    ref.invalidate(calendrierBudgetProvider);
                    if (contexteFeuille.mounted) {
                      Navigator.of(contexteFeuille).pop();
                    }
                  } on ErreurApi catch (echec) {
                    Haptique.refus();
                    rafraichir(() =>
                        message = echec.message.isEmpty ? mots.erreurTitre : echec.message);
                  }
                },
                child: Text(mots.enregistrer),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Calendrier extends ConsumerWidget {
  const _Calendrier();

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<Map<int, int>> calendrier = ref.watch(calendrierBudgetProvider);
    final DateTime maintenant = DateTime.now();
    final int jours = DateTime(maintenant.year, maintenant.month + 1, 0).day;
    final Map<int, int> soldes = calendrier.value ?? <int, int>{};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: couleurs.filet),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (int jour = 1; jour <= jours; jour++)
            Container(
              width: 42,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _fond(couleurs, soldes[jour]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: jour == maintenant.day ? couleurs.accent : couleurs.filet,
                  width: jour == maintenant.day ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TexteAdapte('$jour', style: Theme.of(contexte).textTheme.labelMedium),
                  if (soldes[jour] != null)
                    TexteAdapte(
                      soldes[jour]! >= 0 ? '+' : '-',
                      style: Theme.of(contexte).textTheme.labelSmall?.copyWith(
                            color: soldes[jour]! >= 0 ? couleurs.succes : couleurs.danger,
                          ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _fond(Palette couleurs, int? solde) {
    if (solde == null) {
      return couleurs.surface;
    }
    return solde >= 0 ? couleurs.accentDoux : couleurs.muet;
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({
    required this.titre,
    required this.valeur,
    this.positif = false,
    this.negatif = false,
  });

  final String titre;
  final String valeur;
  final bool positif;
  final bool negatif;

  @override
  Widget build(BuildContext contexte) {
    final Palette couleurs = contexte.couleurs;
    final Color teinte = positif
        ? couleurs.succes
        : (negatif ? couleurs.danger : couleurs.texte);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonCarte),
        border: Border.all(color: couleurs.filet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TexteAdapte(
            titre,
            style: Theme.of(contexte)
                .textTheme
                .labelMedium
                ?.copyWith(color: couleurs.texteSecondaire),
          ),
          const SizedBox(height: 6),
          TexteAdapte(
            valeur,
            style: Theme.of(contexte).textTheme.headlineMedium?.copyWith(color: teinte),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.ligne});

  final LigneBudget ligne;

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool entree = ligne.sens == 'entree';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
        border: Border.all(color: couleurs.filet),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            entree ? Icons.south_west : Icons.north_east,
            size: 20,
            color: entree ? couleurs.succes : couleurs.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteAdapte(ligne.libelle, style: Theme.of(contexte).textTheme.titleMedium),
                TexteAdapte(
                  '${ligne.date.day}/${ligne.date.month} · ${ligne.categorie.replaceAll('_', ' ')}'
                  '${ligne.automatique ? ' · ${mots.ligneAutomatique}' : ''}',
                  style: Theme.of(contexte).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TexteAdapte(
            '${entree ? '+' : '-'}${formaterXof(ligne.montantXof)}',
            style: Theme.of(contexte)
                .textTheme
                .titleMedium
                ?.copyWith(color: entree ? couleurs.succes : couleurs.texte),
          ),
        ],
      ),
    );
  }
}
