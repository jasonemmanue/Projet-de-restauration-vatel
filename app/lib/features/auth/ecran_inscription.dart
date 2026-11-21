// Role du fichier : la creation d un compte, par numero ou par e-mail.
// Images a gauche sur grand ecran, en haut sur telephone. Un seul champ d identifiant, sous une
// bascule, avec le pays et son indicatif quand c est un numero.
// Le serveur reste juge de tout : cet ecran guide la saisie et montre ses messages tels quels.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'widgets/mise_en_page_auth.dart';
import 'widgets/selecteur_pays.dart';

/// Adresse du site public, ou vivent les pages legales.
const String adresseSite = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://cantine-vatel.web.app',
);

/// L ecran d inscription.
class EcranInscription extends ConsumerStatefulWidget {
  /// Construit l ecran d inscription.
  const EcranInscription({super.key});

  @override
  ConsumerState<EcranInscription> createState() => _EtatEcranInscription();
}

class _EtatEcranInscription extends ConsumerState<EcranInscription> {
  final TextEditingController _identifiant = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();

  CanalIdentifiant _canal = CanalIdentifiant.telephone;
  Pays _pays = paysParDefaut;
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
    _confirmation.dispose();
    super.dispose();
  }

  String get _chiffres => _identifiant.text.replaceAll(RegExp('[^0-9]'), '');

  String get _identifiantComplet => _canal == CanalIdentifiant.telephone
      ? '${_pays.indicatif}$_chiffres'
      : _identifiant.text.trim();

  bool get _saisieComplete {
    final bool identifiantPret = _canal == CanalIdentifiant.telephone
        ? _chiffres.length == _pays.longueur
        : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_identifiant.text.trim());
    return identifiantPret &&
        _prenom.text.trim().isNotEmpty &&
        _nom.text.trim().isNotEmpty &&
        ReglesMotDePasse(_motDePasse.text).toutesTenues &&
        _confirmation.text == _motDePasse.text &&
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
    final bool parNumero = _canal == CanalIdentifiant.telephone;

    return MiseEnPageAuth(
      barre: AppBar(
        leading: BackButton(onPressed: () => contexte.go(Chemins.bienvenue)),
        title: TexteAdapte(mots.creerCompte, style: Theme.of(contexte).textTheme.headlineMedium),
      ),
      basDePage: BoutonPrincipal(
        libelle: mots.creerCompte,
        enCours: _enCours,
        onPressed: _saisieComplete ? _creer : null,
        raisonIndisponible: _conditions ? null : mots.conditionsRequises,
      ),
      enfant: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
        children: <Widget>[
          const SizedBox(height: 14),
          BasculeIdentifiant(
            canal: _canal,
            onChange: (CanalIdentifiant canal) => setState(() {
              _canal = canal;
              _identifiant.clear();
            }),
          ),
          const SizedBox(height: 14),
          if (parNumero) ...<Widget>[
            SelecteurPays(pays: _pays, onChange: (Pays pays) => setState(() => _pays = pays)),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _identifiant,
            keyboardType: parNumero ? TextInputType.phone : TextInputType.emailAddress,
            inputFormatters: parNumero
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_pays.longueur),
                  ]
                : null,
            decoration: InputDecoration(
              labelText: parNumero ? mots.champNumero : mots.champEmail,
              prefixIcon: Icon(parNumero ? Icons.phone_outlined : Icons.alternate_email),
              prefixText: parNumero ? '${_pays.indicatif} ' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (parNumero && _pays.code == 'CI') ...<Widget>[
            const SizedBox(height: 6),
            TexteAdapte(
              mots.aideNumeroCi,
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyMedium,
            ),
          ],
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
              ButtonSegment<String>(
                value: 'convive',
                label: Text(mots.roleConvive),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment<String>(
                value: 'parent',
                label: Text(mots.roleParent),
                icon: const Icon(Icons.family_restroom_outlined),
              ),
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
          const SizedBox(height: 12),
          ChampMotDePasse(
            controleur: _confirmation,
            libelle: mots.confirmerMotDePasse,
            montrerRegles: false,
            onChange: (String _) => setState(() {}),
          ),
          if (_confirmation.text.isNotEmpty && _confirmation.text != _motDePasse.text) ...<Widget>[
            const SizedBox(height: 6),
            TexteAdapte(
              mots.motsDePasseDifferents,
              maxLignes: 2,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
            ),
          ],
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _conditions,
            onChanged: (bool? valeur) => setState(() => _conditions = valeur ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: <Widget>[
                Text(mots.jaccepteLes, style: Theme.of(contexte).textTheme.bodyLarge),
                InkWell(
                  onTap: () => unawaited(
                    launchUrl(
                      Uri.parse('$adresseSite/legal/conditions.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  child: Text(
                    mots.conditionsUtilisation,
                    style: Theme.of(contexte).textTheme.bodyLarge?.copyWith(
                          color: couleurs.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: couleurs.accent,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (_erreur != null) ...<Widget>[
            const SizedBox(height: 8),
            TexteAdapte(
              _erreur!,
              maxLignes: 3,
              alignement: TextAlign.center,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
            ),
          ],
          Center(
            child: TextButton(
              onPressed: () => contexte.go(Chemins.connexion),
              child: Text(mots.jaiUnCompte),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
