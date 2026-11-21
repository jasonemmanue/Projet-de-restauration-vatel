// Role du fichier : la connexion par numero ou par e-mail.
// Meme mise en page que l inscription : images a gauche sur grand ecran, en haut sur telephone.
// Un compte encore a verifier part vers l ecran du code, il n est pas laisse sur un message.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'ecran_code.dart';
import 'widgets/bascule_identifiant.dart';
import 'widgets/champ_mot_de_passe.dart';
import 'widgets/mise_en_page_auth.dart';
import 'widgets/selecteur_pays.dart';

/// L ecran de connexion.
class EcranConnexion extends ConsumerStatefulWidget {
  /// Construit l ecran de connexion.
  const EcranConnexion({super.key});

  @override
  ConsumerState<EcranConnexion> createState() => _EtatEcranConnexion();
}

class _EtatEcranConnexion extends ConsumerState<EcranConnexion> {
  final TextEditingController _identifiant = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  CanalIdentifiant _canal = CanalIdentifiant.telephone;
  Pays _pays = paysParDefaut;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  String get _identifiantComplet => _canal == CanalIdentifiant.telephone
      ? '${_pays.indicatif}${_identifiant.text.replaceAll(RegExp('[^0-9]'), '')}'
      : _identifiant.text.trim();

  Future<void> _connecter() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final ServiceAuth service = ref.read(serviceAuthProvider);
    try {
      final Session? session = await service.connecter(
        identifiant: _identifiantComplet,
        motDePasse: _motDePasse.text,
      );
      if (session == null) {
        setState(() => _erreur = Traductions.of(context).erreurTitre);
        return;
      }
      await ref.read(sessionProvider.notifier).ouvrir(session);
      Haptique.succes();
      if (mounted) {
        context.go(Chemins.accueil(session.role));
      }
    } on ErreurApi catch (echec) {
      if (!mounted) {
        return;
      }
      if (echec.code == 'compte_a_verifier' || echec.code == 'verification_requise') {
        // Compte non verifie, ou session laissee dormir plus de cinq jours : on repasse par le code.
        final CodeEnvoye envoi = await service.envoyerCode(
          identifiant: _identifiantComplet,
          canal: _canal,
        );
        if (mounted) {
          context.go(
            Chemins.code,
            extra: ArgumentsCode(
              identifiant: _identifiantComplet,
              canal: _canal,
              premierEnvoi: envoi,
            ),
          );
        }
        return;
      }
      Haptique.refus();
      setState(
        () => _erreur =
            echec.message.isEmpty ? Traductions.of(context).erreurReseau : echec.message,
      );
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
    final bool pret = _identifiant.text.trim().isNotEmpty && _motDePasse.text.isNotEmpty;

    return MiseEnPageAuth(
      barre: AppBar(
        leading: BackButton(onPressed: () => contexte.go(Chemins.bienvenue)),
        title: TexteAdapte(mots.seConnecter, style: Theme.of(contexte).textTheme.headlineMedium),
      ),
      basDePage: BoutonPrincipal(
        libelle: mots.seConnecter,
        enCours: _enCours,
        onPressed: pret ? _connecter : null,
      ),
      enfant: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Mesures.marge),
        shrinkWrap: true,
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
          const SizedBox(height: 14),
          ChampMotDePasse(
            controleur: _motDePasse,
            montrerRegles: false,
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
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => contexte.go(Chemins.motDePasseOublie),
              child: Text(mots.motDePasseOublie),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => contexte.go(Chemins.inscription),
              child: Text(mots.creerCompte),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
