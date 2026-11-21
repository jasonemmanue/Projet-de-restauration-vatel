// Role du fichier : le catalogue des plats et les tarifs par profil, côté back office.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/outils/formats.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/feuille_bas.dart';
import '../../shared/widgets/texte_adapte.dart';
import '../menus/donnees/modeles_menu.dart';
import 'donnees/service_admin.dart';

/// Le catalogue des plats et les tarifs.
class EcranPlatsAdmin extends ConsumerWidget {
  /// Construit l écran des plats.
  const EcranPlatsAdmin({super.key});

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final EtatAdmin etat = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: couleurs.fond,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editer(contexte, ref, null),
        icon: const Icon(Icons.add),
        label: Text(mots.nouveauPlat),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(mots.platsTitre, style: Theme.of(contexte).textTheme.headlineLarge),
          const SizedBox(height: 14),
          for (final Service service in Service.values) ...<Widget>[
            TexteAdapte(
              _titreService(mots, service),
              style: Theme.of(contexte).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            for (final Plat plat in etat.plats.where((Plat p) => p.service == service)) ...<Widget>[
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
                          TexteAdapte(plat.nom, style: Theme.of(contexte).textTheme.titleMedium),
                          if (plat.prixSupplementXof > 0)
                            TexteAdapte(
                              mots.partEnPlus(formaterXof(plat.prixSupplementXof)),
                              style: Theme.of(contexte).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editer(contexte, ref, plat),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: mots.enregistrer,
                    ),
                    IconButton(
                      onPressed: () => ref.read(adminProvider.notifier).supprimerPlat(plat.id),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: mots.supprimer,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          TexteAdapte(mots.tarifsTitre, style: Theme.of(contexte).textTheme.headlineMedium),
          const SizedBox(height: 8),
          for (final Tarif tarif in etat.tarifs)
            _LigneTarif(tarif: tarif),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  String _titreService(Traductions mots, Service service) => switch (service) {
        Service.entree => mots.serviceEntree,
        Service.resistance => mots.serviceResistance,
        Service.sortie => mots.serviceSortie,
      };

  Future<void> _editer(BuildContext contexte, WidgetRef ref, Plat? plat) {
    final Traductions mots = Traductions.of(contexte);
    final TextEditingController nom = TextEditingController(text: plat?.nom ?? '');
    final TextEditingController description = TextEditingController(text: plat?.description ?? '');
    final TextEditingController supplement =
        TextEditingController(text: '${plat?.prixSupplementXof ?? 0}');
    Service service = plat?.service ?? Service.resistance;

    return ouvrirFeuilleBas<void>(
      contexte: contexte,
      titre: plat == null ? mots.nouveauPlat : plat.nom,
      contenu: (BuildContext contexteFeuille) => StatefulBuilder(
        builder: (BuildContext contexteFeuille, StateSetter rafraichir) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: nom,
              decoration: InputDecoration(labelText: mots.nomDuPlat),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: InputDecoration(labelText: mots.descriptionPlat),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: supplement,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: mots.supplementPrix, suffixText: 'F'),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final Service choix in Service.values)
                  ChoiceChip(
                    label: Text(_titreService(mots, choix)),
                    selected: service == choix,
                    onSelected: (_) => rafraichir(() => service = choix),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: Mesures.hauteurBouton,
              child: FilledButton(
                onPressed: () {
                  Haptique.succes();
                  ref.read(adminProvider.notifier).enregistrerPlat(
                        Plat(
                          id: plat?.id ??
                              'plat-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
                          nom: nom.text.trim(),
                          service: service,
                          description: description.text.trim(),
                          image: plat?.image,
                          allergenes: plat?.allergenes ?? const <String>[],
                          prixSupplementXof: int.tryParse(supplement.text) ?? 0,
                        ),
                      );
                  Navigator.of(contexteFeuille).pop();
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

class _LigneTarif extends ConsumerWidget {
  const _LigneTarif({required this.tarif});

  final Tarif tarif;

  @override
  Widget build(BuildContext contexte, WidgetRef ref) {
    final Palette couleurs = contexte.couleurs;
    final TextEditingController prix = TextEditingController(text: '${tarif.prixXof}');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
        border: Border.all(color: couleurs.filet),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TexteAdapte(tarif.profil, style: Theme.of(contexte).textTheme.titleMedium),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: prix,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(suffixText: 'F', border: InputBorder.none),
              onSubmitted: (String valeur) => ref
                  .read(adminProvider.notifier)
                  .poserTarif(tarif.profil, int.tryParse(valeur) ?? tarif.prixXof),
            ),
          ),
        ],
      ),
    );
  }
}
