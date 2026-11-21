// Role du fichier : le mot de passe oublié, en trois temps sur un seul écran.
// Identifiant, puis code reçu, puis nouveau mot de passe. Aucun aller-retour entre écrans.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/routes.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_auth.dart';
import 'widgets/bascule_identifiant.dart';
import 'widgets/cases_code.dart';
import 'widgets/champ_mot_de_passe.dart';

/// Les trois temps de la réinitialisation.
enum _Etape {
  /// On demande l identifiant.
  identifiant,

  /// On attend le code reçu.
  code,

  /// On pose le nouveau mot de passe.
  motDePasse,
}

/// L écran de mot de passe oublié.
class EcranMotDePasseOublie extends ConsumerStatefulWidget {
  /// Construit l écran.
  const EcranMotDePasseOublie({super.key});

  @override
  ConsumerState<EcranMotDePasseOublie> createState() => _EtatEcranMotDePasseOublie();
}

class _EtatEcranMotDePasseOublie extends ConsumerState<EcranMotDePasseOublie> {
  final TextEditingController _identifiant = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();

  CanalIdentifiant _canal = CanalIdentifiant.telephone;
  _Etape _etape = _Etape.identifiant;
  CodeEnvoye? _envoi;
  String _code = '';
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  String get _identifiantComplet => _canal == CanalIdentifiant.telephone
      ? '+225${_identifiant.text.replaceAll(RegExp('[^0-9]'), '')}'
      : _identifiant.text.trim();

  Future<void> _lancer(Future<void> Function() travail) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await travail();
    } on ErreurApi catch (echec) {
      Haptique.refus();
      if (mounted) {
        setState(() => _erreur =
            echec.message.isEmpty ? Traductions.of(context).erreurReseau : echec.message);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  Future<void> _demanderCode() => _lancer(() async {
        final CodeEnvoye envoi = await ref.read(serviceAuthProvider).motDePasseOublie(
              identifiant: _identifiantComplet,
              canal: _canal,
            );
        if (!mounted) {
          return;
        }
        setState(() {
          _envoi = envoi;
          _code = envoi.estDemo ? (envoi.codeDemo ?? '') : '';
          _etape = _Etape.code;
        });
      });

  Future<void> _poserMotDePasse() => _lancer(() async {
        await ref.read(serviceAuthProvider).reinitialiserMotDePasse(
              identifiant: _identifiantComplet,
              canal: _canal,
              code: _code,
              nouveauMotDePasse: _motDePasse.text,
            );
        if (!mounted) {
          return;
        }
        Haptique.succes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Traductions.of(context).motDePasseChange)),
        );
        context.go(Chemins.connexion);
      });

  @override
  Widget build(BuildContext contexte) {
    final Traductions mots = Traductions.of(contexte);
    final Palette couleurs = contexte.couleurs;
    final bool parNumero = _canal == CanalIdentifiant.telephone;
    final CodeEnvoye? envoi = _envoi;

    final bool pret = switch (_etape) {
      _Etape.identifiant => _identifiant.text.trim().isNotEmpty,
      _Etape.code => _code.length == _canal.longueurCode,
      _Etape.motDePasse => ReglesMotDePasse(_motDePasse.text).toutesTenues,
    };

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Chemins.connexion)),
        title: TexteAdapte(
          mots.reinitialiserMotDePasse,
          style: Theme.of(contexte).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
              children: <Widget>[
                if (_etape == _Etape.identifiant) ...<Widget>[
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
                ],
                if (_etape == _Etape.code) ...<Widget>[
                  TexteAdapte(
                    parNumero
                        ? mots.sousTitreCodeTelephone(_identifiantComplet)
                        : mots.sousTitreCodeEmail(_identifiantComplet),
                    maxLignes: 3,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (envoi != null && envoi.estDemo)
                    TexteAdapte(
                      mots.modeDemoCodeRempli,
                      maxLignes: 2,
                      alignement: TextAlign.center,
                      style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.accent),
                    )
                  else
                    TexteAdapte(
                      mots.penseAuxIndesirables,
                      maxLignes: 2,
                      alignement: TextAlign.center,
                      style: Theme.of(contexte).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 18),
                  CasesCode(
                    longueur: _canal.longueurCode,
                    enLettres: !parNumero,
                    valeurInitiale: envoi != null && envoi.estDemo ? (envoi.codeDemo ?? '') : '',
                    onChange: (String valeur) => setState(() => _code = valeur),
                  ),
                ],
                if (_etape == _Etape.motDePasse)
                  ChampMotDePasse(
                    controleur: _motDePasse,
                    libelle: mots.nouveauMotDePasse,
                    onChange: (_) => setState(() {}),
                  ),
                if (_erreur != null) ...<Widget>[
                  const SizedBox(height: 14),
                  TexteAdapte(
                    _erreur!,
                    maxLignes: 3,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: _etape == _Etape.motDePasse ? mots.valider : mots.continuer,
        enCours: _enCours,
        onPressed: !pret
            ? null
            : switch (_etape) {
                _Etape.identifiant => _demanderCode,
                _Etape.code => () => setState(() => _etape = _Etape.motDePasse),
                _Etape.motDePasse => _poserMotDePasse,
              },
      ),
    );
  }
}
