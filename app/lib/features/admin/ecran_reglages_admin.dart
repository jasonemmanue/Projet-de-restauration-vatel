// Role du fichier : les reglages du back office. Pays acceptes, comptes a verifier, journal.
// Un pays ajoute ici est aussitot propose a l inscription : l application lit cette liste.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/etats.dart';
import '../../shared/widgets/feuille_bas.dart';
import '../../shared/widgets/squelette.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_exploitation.dart';

/// Les reglages de l administration.
class EcranReglagesAdmin extends ConsumerWidget {
  /// Construit les reglages de l administration.
  const EcranReglagesAdmin({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final AsyncValue<List<Map<String, dynamic>>> pays = ref.watch(paysAdminProvider);
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);

    return Scaffold(
      backgroundColor: couleurs.fond,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouterPays(contexte, ref),
        icon: const Icon(Icons.add),
        label: Text(mots.ajouterPays),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.ongletReglages, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 18),

          TexteAdapte(mots.paysAcceptes, style: Theme.of(contexte).textTheme.headlineMedium),
          const SizedBox(height: 6),
          TexteAdapte(
            mots.paysExplication,
            maxLignes: 3,
            style: Theme.of(contexte).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          pays.when(
            loading: () => const CarteSquelette(hauteur: 70),
            error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
            data: (List<Map<String, dynamic>> liste) {
              if (liste.isEmpty) {
                return EtatVide(titre: mots.etatVideTitre, icone: Icons.public);
              }
              return Column(
                children: <Widget>[
                  for (final Map<String, dynamic> unPays in liste)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: couleurs.surface,
                        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                        border: Border.all(color: couleurs.filet),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: couleurs.accentDoux,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TexteAdapte(
                              '${unPays['code']}',
                              style: Theme.of(contexte)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: couleurs.accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TexteAdapte(
                              '${unPays['nom']}',
                              style: Theme.of(contexte).textTheme.titleMedium,
                            ),
                          ),
                          TexteAdapte(
                            '${unPays['indicatif']}',
                            style: Theme.of(contexte).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: () async {
                              await ref
                                  .read(serviceExploitationProvider)
                                  .retirerPays('${unPays['code']}');
                              ref.invalidate(paysAdminProvider);
                            },
                            icon: const Icon(Icons.delete_outline),
                            tooltip: mots.supprimer,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          TexteAdapte(mots.comptesTitre, style: Theme.of(contexte).textTheme.headlineMedium),
          const SizedBox(height: 10),
          comptes.when(
            loading: () => const CarteSquelette(hauteur: 70),
            error: (Object _, StackTrace _) => EtatVide(titre: mots.etatVideTitre),
            data: (List<CompteAdmin> liste) {
              if (liste.isEmpty) {
                return EtatVide(titre: mots.etatVideTitre, icone: Icons.group_outlined);
              }
              return Column(
                children: <Widget>[
                  for (final CompteAdmin compte in liste)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: couleurs.surface,
                        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
                        border: Border.all(color: couleurs.filet),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TexteAdapte(
                                  compte.nomComplet,
                                  style: Theme.of(contexte).textTheme.titleMedium,
                                ),
                                TexteAdapte(
                                  '${compte.role} · ${compte.identifiant}',
                                  style: Theme.of(contexte).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (compte.verifie)
                            Icon(Icons.verified, size: 20, color: couleurs.succes)
                          else
                            SizedBox(
                              height: Mesures.cibleTactile,
                              child: OutlinedButton(
                                onPressed: () async {
                                  Haptique.succes();
                                  await ref
                                      .read(serviceExploitationProvider)
                                      .validerCompte(compte.id);
                                  ref.invalidate(comptesProvider);
                                },
                                child: Text(mots.validerALaMain),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Future<void> _ajouterPays(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController code = TextEditingController();
    final TextEditingController nom = TextEditingController();
    final TextEditingController indicatif = TextEditingController();
    final TextEditingController longueur = TextEditingController(text: '10');
    String? message;

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: mots.ajouterPays,
      contenu: (BuildContext contexteFeuille) => StatefulBuilder(
        builder: (BuildContext contexteFeuille, StateSetter rafraichir) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: nom,
              decoration: InputDecoration(labelText: mots.nomDuPays),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(2)],
                    decoration: InputDecoration(labelText: mots.codePays),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: indicatif,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: mots.indicatif, prefixText: '+'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: longueur,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: mots.nombreDeChiffres),
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
                    await ref.read(serviceExploitationProvider).ajouterPays(
                          code: code.text.trim(),
                          nom: nom.text.trim(),
                          indicatif: indicatif.text.trim(),
                          longueur: int.tryParse(longueur.text) ?? 10,
                        );
                    Haptique.succes();
                    ref.invalidate(paysAdminProvider);
                    if (contexteFeuille.mounted) {
                      Navigator.of(contexteFeuille).pop();
                    }
                  } on ErreurApi catch (echec) {
                    rafraichir(
                      () => message = echec.message.isEmpty ? mots.erreurTitre : echec.message,
                    );
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
