// Role du fichier : completer son profil apres une connexion Google ou Apple.
// Ces fournisseurs rendent un nom et parfois un e-mail, jamais le reste : il manque le numero,
// le role et le profil tarifaire. Tant que ce n est pas rempli, l application n ouvre rien d autre.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/client_api.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/routes.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'widgets/champ_mot_de_passe.dart';
import 'widgets/mise_en_page_auth.dart';
import 'widgets/selecteur_pays.dart';

/// L ecran de finalisation du profil.
class EcranFinaliserProfil extends ConsumerStatefulWidget {
  /// Construit l ecran.
  const EcranFinaliserProfil({super.key});

  @override
  ConsumerState<EcranFinaliserProfil> createState() => _EtatEcranFinaliserProfil();
}

class _EtatEcranFinaliserProfil extends ConsumerState<EcranFinaliserProfil> {
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _numero = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();

  Pays _pays = paysParDefaut;
  String _role = 'convive';
  String _statut = 'eleve';
  bool _enCours = false;
  String? _erreur;
  bool _preRempli = false;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  void _preRemplir(Session session) {
    if (_preRempli || session.nomComplet.isEmpty) {
      return;
    }
    final List<String> morceaux = session.nomComplet.split(' ');
    _prenom.text = morceaux.first;
    if (morceaux.length > 1) {
      _nom.text = morceaux.sublist(1).join(' ');
    }
    _preRempli = true;
  }

  bool get _pret =>
      _prenom.text.trim().isNotEmpty &&
      _nom.text.trim().isNotEmpty &&
      _numero.text.replaceAll(RegExp('[^0-9]'), '').length == _pays.longueur &&
      ReglesMotDePasse(_motDePasse.text).toutesTenues;

  Future<void> _finaliser() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(clientApiProvider).envoyer(
        '/auth/profil/finaliser',
        corps: <String, dynamic>{
          'prenom': _prenom.text.trim(),
          'nom': _nom.text.trim(),
          'identifiant': '${_pays.indicatif}${_numero.text.replaceAll(RegExp('[^0-9]'), '')}',
          'type': 'telephone',
          'role': _role,
          if (_role == 'convive') 'statut_convive': _statut,
          'mot_de_passe': _motDePasse.text,
        },
      );
      Haptique.succes();
      final Session? session = ref.read(sessionProvider).value;
      if (mounted && session != null) {
        context.go(Chemins.accueil(session.role));
      }
    } on ErreurApi catch (echec) {
      Haptique.refus();
      if (mounted) {
        setState(
          () => _erreur =
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
    final Session? session = ref.watch(sessionProvider).value;
    if (session != null) {
      _preRemplir(session);
    }

    return MiseEnPageAuth(
      barre: AppBar(
        automaticallyImplyLeading: false,
        title: TexteAdapte(
          mots.finaliserProfil,
          style: Theme.of(contexte).textTheme.headlineMedium,
        ),
      ),
      basDePage: BoutonPrincipal(
        libelle: mots.valider,
        enCours: _enCours,
        onPressed: _pret ? _finaliser : null,
      ),
      enfant: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
        shrinkWrap: true,
        children: <Widget>[
          const SizedBox(height: 14),
          TexteAdapte(
            mots.finaliserExplication,
            maxLignes: 3,
            style: Theme.of(contexte).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _prenom,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: mots.prenom),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nom,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: mots.nom),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelecteurPays(pays: _pays, onChange: (Pays pays) => setState(() => _pays = pays)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _numero,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_pays.longueur),
            ],
            decoration: InputDecoration(
              labelText: mots.champNumero,
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '${_pays.indicatif} ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          TexteAdapte(mots.jeSuis, style: Theme.of(contexte).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'convive', label: Text(mots.roleConvive)),
              ButtonSegment<String>(value: 'parent', label: Text(mots.roleParent)),
            ],
            selected: <String>{_role},
            onSelectionChanged: (Set<String> choix) => setState(() => _role = choix.first),
          ),
          if (_role == 'convive') ...<Widget>[
            const SizedBox(height: 18),
            TexteAdapte(mots.profilTarifaire, style: Theme.of(contexte).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final MapEntry<String, String> profil in <String, String>{
                  'eleve': mots.statutEleve,
                  'etudiant': mots.statutEtudiant,
                  'employe': mots.statutEmploye,
                  'autre': mots.statutAutre,
                }.entries)
                  ChoiceChip(
                    label: Text(profil.value),
                    selected: _statut == profil.key,
                    onSelected: (_) => setState(() => _statut = profil.key),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          ChampMotDePasse(
            controleur: _motDePasse,
            onChange: (String _) => setState(() {}),
          ),
          if (_erreur != null) ...<Widget>[
            const SizedBox(height: 12),
            TexteAdapte(
              _erreur!,
              maxLignes: 3,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
