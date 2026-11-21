// Role du fichier : la création d un compte, par numéro ou par e-mail.
// Un seul champ d identifiant, sous une bascule. Le serveur reste juge de tout : cet écran
// ne fait que guider la saisie et montrer ses messages tels quels.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_auth.dart';
import 'ecran_code.dart';
import 'widgets/bascule_identifiant.dart';
import 'widgets/champ_mot_de_passe.dart';

/// L écran d inscription.
class EcranInscription extends ConsumerStatefulWidget {
  /// Construit l écran d inscription.
  const EcranInscription({super.key});

  @override
  ConsumerState<EcranInscription> createState() => _EtatEcranInscription();
}

class _EtatEcranInscription extends ConsumerState<EcranInscription> {
  final TextEditingController _identifiant = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();

  CanalIdentifiant _canal = CanalIdentifiant.telephone;
  String _role = 'convive';
  String _statut = 'eleve';
  bool _conditions = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _prenom.dispose();
    _nom.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  String get _identifiantComplet => _canal == CanalIdentifiant.telephone
      ? '+225${_identifiant.text.replaceAll(RegExp('[^0-9]'), '')}'
      : _identifiant.text.trim();

  bool get _saisieComplete {
    final bool identifiantPret = _canal == CanalIdentifiant.telephone
        ? _identifiant.text.replaceAll(RegExp('[^0-9]'), '').length == 10
        : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_identifiant.text.trim());
    return identifiantPret &&
        _prenom.text.trim().isNotEmpty &&
        _nom.text.trim().isNotEmpty &&
        ReglesMotDePasse(_motDePasse.text).toutesTenues &&
        _conditions;
  }

  Future<void> _creer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final ServiceAuth service = ref.read(serviceAuthProvider);
    try {
      await service.inscrire(
        canal: _canal,
        identifiant: _identifiantComplet,
        motDePasse: _motDePasse.text,
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        role: _role,
        statutConvive: _role == 'convive' ? _statut : null,
      );
      final CodeEnvoye envoi = await service.envoyerCode(
        identifiant: _identifiantComplet,
        canal: _canal,
      );
      if (!mounted) {
        return;
      }
      context.go(
        Chemins.code,
        extra: ArgumentsCode(
          identifiant: _identifiantComplet,
          canal: _canal,
          premierEnvoi: envoi,
        ),
      );
    } on ErreurApi catch (echec) {
      if (mounted) {
        setState(() => _erreur = echec.message.isEmpty
            ? Traductions.of(context).erreurReseau
            : echec.message);
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
    final bool parNumero = _canal == CanalIdentifiant.telephone;

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Chemins.bienvenue)),
        title: TexteAdapte(mots.creerCompte, style: Theme.of(contexte).textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
              children: <Widget>[
                BasculeIdentifiant(
                  canal: _canal,
                  onChange: (CanalIdentifiant canal) => setState(() {
                    _canal = canal;
                    _identifiant.clear();
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _identifiant,
                  keyboardType: parNumero ? TextInputType.phone : TextInputType.emailAddress,
                  inputFormatters: parNumero
                      ? <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  decoration: InputDecoration(
                    labelText: parNumero ? mots.champNumero : mots.champEmail,
                    prefixText: parNumero ? '+225 ' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
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
                  onChange: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _conditions,
                  onChanged: (bool? valeur) => setState(() => _conditions = valeur ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: TexteAdapte(
                    mots.accepterConditions,
                    maxLignes: 2,
                    style: Theme.of(contexte).textTheme.bodyLarge,
                  ),
                ),
                if (_erreur != null) ...<Widget>[
                  const SizedBox(height: 8),
                  TexteAdapte(
                    _erreur!,
                    maxLignes: 3,
                    style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
                  ),
                ],
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go(Chemins.connexion),
                  child: Text(mots.jaiUnCompte),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.creerCompte,
        enCours: _enCours,
        onPressed: _saisieComplete ? _creer : null,
        raisonIndisponible: _conditions ? null : mots.conditionsRequises,
      ),
    );
  }
}
