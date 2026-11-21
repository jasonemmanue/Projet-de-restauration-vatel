// Role du fichier : l écran du code de vérification, ouvert juste après l inscription.
// En mode démo, l API renvoie le code : les cases se remplissent seules et une pastille le dit.
// Sinon les cases restent vides et un rappel invite à regarder dans les indésirables.
// Le renvoi se rouvre après 60 secondes comptées sur l appareil.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/outils/haptique.dart';
import '../../core/responsive/type_ecran.dart';
import '../../core/reseau/erreur_api.dart';
import '../../core/routes/routes.dart';
import '../../core/securite/session.dart';
import '../../core/theme/couleurs.dart';
import '../../l10n/traductions.dart';
import '../../shared/widgets/bouton_principal.dart';
import '../../shared/widgets/texte_adapte.dart';
import 'donnees/service_auth.dart';
import 'widgets/cases_code.dart';

/// Ce que l écran du code doit savoir pour s ouvrir.
class ArgumentsCode {
  /// Construit les arguments de l écran du code.
  const ArgumentsCode({
    required this.identifiant,
    required this.canal,
    required this.premierEnvoi,
  });

  /// L identifiant à vérifier, numéro ou e-mail.
  final String identifiant;

  /// Le canal de vérification.
  final CanalIdentifiant canal;

  /// Ce que l API a répondu au premier envoi.
  final CodeEnvoye premierEnvoi;
}

/// L écran qui demande le code de vérification.
class EcranCode extends ConsumerStatefulWidget {
  /// Construit l écran du code.
  const EcranCode({required this.arguments, super.key});

  /// Identifiant, canal et premier envoi.
  final ArgumentsCode arguments;

  @override
  ConsumerState<EcranCode> createState() => _EtatEcranCode();
}

class _EtatEcranCode extends ConsumerState<EcranCode> {
  static const int _secondesAvantRenvoi = 60;

  late CodeEnvoye _envoi;
  String _code = '';
  String? _erreur;
  bool _enCours = false;
  int _attente = _secondesAvantRenvoi;
  Timer? _compteur;

  @override
  void initState() {
    super.initState();
    _envoi = widget.arguments.premierEnvoi;
    _lancerCompteur();
  }

  @override
  void dispose() {
    _compteur?.cancel();
    super.dispose();
  }

  void _lancerCompteur() {
    _compteur?.cancel();
    setState(() => _attente = _secondesAvantRenvoi);
    // Le compte à rebours est tenu sur l appareil : aucun appel réseau périodique.
    _compteur = Timer.periodic(const Duration(seconds: 1), (Timer minuteur) {
      if (!mounted) {
        minuteur.cancel();
        return;
      }
      setState(() => _attente = _attente - 1);
      if (_attente <= 0) {
        minuteur.cancel();
      }
    });
  }

  Future<void> _renvoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final CodeEnvoye envoi = await ref.read(serviceAuthProvider).envoyerCode(
            identifiant: widget.arguments.identifiant,
            canal: widget.arguments.canal,
          );
      if (!mounted) {
        return;
      }
      setState(() => _envoi = envoi);
      _lancerCompteur();
    } on ErreurApi catch (echec) {
      if (mounted) {
        setState(() => _erreur = echec.message);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  Future<void> _confirmer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final Session? session = await ref.read(serviceAuthProvider).confirmerCode(
            identifiant: widget.arguments.identifiant,
            canal: widget.arguments.canal,
            code: _code,
          );
      if (!mounted) {
        return;
      }
      Haptique.succes();
      if (session != null) {
        await ref.read(sessionProvider.notifier).ouvrir(session);
        if (mounted) {
          context.go(Chemins.accueil(session.role));
        }
        return;
      }
      context.go(Chemins.connexion);
    } on ErreurApi catch (echec) {
      Haptique.refus();
      if (mounted) {
        setState(() => _erreur = echec.message);
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
    final bool estTelephone = widget.arguments.canal == CanalIdentifiant.telephone;
    final int longueur = widget.arguments.canal.longueurCode;

    return Scaffold(
      backgroundColor: couleurs.fond,
      appBar: AppBar(leading: BackButton(onPressed: () => context.go(Chemins.bienvenue))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TexteAdapte(
                    mots.titreCode,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  TexteAdapte(
                    estTelephone
                        ? mots.sousTitreCodeTelephone(widget.arguments.identifiant)
                        : mots.sousTitreCodeEmail(widget.arguments.identifiant),
                    maxLignes: 3,
                    alignement: TextAlign.center,
                    style: Theme.of(contexte).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  if (_envoi.estDemo)
                    _Pastille(
                      libelle: mots.modeDemoCodeRempli,
                      couleurFond: couleurs.accentDoux,
                      couleurTexte: couleurs.texte,
                      icone: Icons.bolt_outlined,
                    )
                  else
                    _Pastille(
                      libelle: mots.penseAuxIndesirables,
                      couleurFond: couleurs.muet,
                      couleurTexte: couleurs.texteSecondaire,
                      icone: Icons.mark_email_unread_outlined,
                    ),
                  const SizedBox(height: 24),
                  CasesCode(
                    longueur: longueur,
                    enLettres: !estTelephone,
                    valeurInitiale: _envoi.estDemo ? (_envoi.codeDemo ?? '') : '',
                    onChange: (String valeur) => setState(() => _code = valeur),
                  ),
                  if (_erreur != null) ...<Widget>[
                    const SizedBox(height: 16),
                    TexteAdapte(
                      _erreur!,
                      maxLignes: 3,
                      alignement: TextAlign.center,
                      style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurs.danger),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _attente > 0 || _enCours ? null : _renvoyer,
                    child: Text(
                      _attente > 0 ? mots.renvoyerDans(_attente) : mots.renvoyerLeCode,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BoutonPrincipal(
        libelle: mots.valider,
        enCours: _enCours,
        onPressed: _code.length == longueur ? _confirmer : null,
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.libelle,
    required this.couleurFond,
    required this.couleurTexte,
    required this.icone,
  });

  final String libelle;
  final Color couleurFond;
  final Color couleurTexte;
  final IconData icone;

  @override
  Widget build(BuildContext contexte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(Mesures.rayonPetit),
      ),
      child: Row(
        children: <Widget>[
          Icon(icone, size: 18, color: couleurTexte),
          const SizedBox(width: 10),
          Expanded(
            child: TexteAdapte(
              libelle,
              maxLignes: 2,
              style: Theme.of(contexte).textTheme.bodyMedium?.copyWith(color: couleurTexte),
            ),
          ),
        ],
      ),
    );
  }
}
