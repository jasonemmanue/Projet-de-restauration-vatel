// Role du fichier : noter un repas deja servi. Quatre criteres, un commentaire.
// Hors ligne, l appreciation part dans la file d envoi avec sa cle unique et sera envoyee seule.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hors_ligne/etat_reseau.dart';
import '../../core/hors_ligne/file_envoi.dart';
import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/cle_demande.dart';
import '../../core/reseau/client_api.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_commandes.dart';

/// L ecran d appreciation d un repas.
class EcranAppreciation extends ConsumerStatefulWidget {
  /// Construit l ecran d appreciation.
  const EcranAppreciation({required this.commande, super.key});

  /// La commande notee.
  final Commande commande;

  @override
  ConsumerState<EcranAppreciation> createState() => _EtatEcranAppreciation();
}

class _EtatEcranAppreciation extends ConsumerState<EcranAppreciation> {
  final TextEditingController _commentaire = TextEditingController();
  final Map<String, int> _notes = <String, int>{
    'gout': 0,
    'quantite': 0,
    'temperature': 0,
    'attente': 0,
  };
  bool _enCours = false;
  String? _message;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  bool get _pret => _notes.values.every((int note) => note > 0);

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _message = null;
    });
    final String cleUnique = CleDemande.nouvelle();
    final Map<String, dynamic> corps = <String, dynamic>{
      'reservation_id': widget.commande.id,
      'note_gout': _notes['gout'],
      'note_quantite': _notes['quantite'],
      'note_temperature': _notes['temperature'],
      'note_attente': _notes['attente'],
      'commentaire': _commentaire.text.trim(),
    };

    if (!ref.read(etatReseauProvider)) {
      // Hors ligne : l appreciation attend son tour, elle n est pas perdue.
      await ref.read(fileEnvoiProvider.notifier).ajouter(
            ActionEnAttente(
              cleUnique: cleUnique,
              type: TypeAction.appreciation,
              chemin: '/avis',
              corps: corps,
              faiteLe: DateTime.now(),
            ),
          );
      if (mounted) {
        Haptique.succes();
        setState(() {
          _enCours = false;
          _message = Traductions.of(context).appreciationEnAttente;
        });
      }
      return;
    }

    try {
      await ref.read(clientApiProvider).envoyer('/avis', corps: corps, cleGeste: cleUnique);
      Haptique.succes();
      if (mounted) {
        setState(() => _message = Traductions.of(context).appreciationEnvoyee);
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

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;

    final Map<String, String> criteres = <String, String>{
      'gout': mots.critereGout,
      'quantite': mots.critereQuantite,
      'temperature': mots.critereTemperature,
      'attente': mots.critereAttente,
    };

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(title: TexteAdapte(mots.noterLeRepas)),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.envoyer,
        enCours: _enCours,
        onPressed: _pret ? _envoyer : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Mesures.marge),
        children: <Widget>[
          TexteAdapte(
            widget.commande.plats.join(', '),
            maxLignes: 3,
            style: Theme.of(contexte).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          for (final MapEntry<String, String> critere in criteres.entries) ...<Widget>[
            TexteAdapte(critere.value, style: Theme.of(contexte).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                for (int etoile = 1; etoile <= 5; etoile++)
                  IconButton(
                    onPressed: () {
                      Haptique.leger();
                      setState(() => _notes[critere.key] = etoile);
                    },
                    icon: Icon(
                      etoile <= (_notes[critere.key] ?? 0) ? Icons.star : Icons.star_border,
                      size: 30,
                      color: etoile <= (_notes[critere.key] ?? 0)
                          ? couleurs.alerte
                          : couleurs.texteSecondaire,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          TextField(
            controller: _commentaire,
            maxLines: 4,
            decoration: InputDecoration(labelText: mots.commentaireLibre),
          ),
          if (_message != null) ...<Widget>[
            const SizedBox(height: 14),
            TexteAdapte(
              _message!,
              maxLignes: 3,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyLarge?.copyWith(color: couleurs.succes),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
