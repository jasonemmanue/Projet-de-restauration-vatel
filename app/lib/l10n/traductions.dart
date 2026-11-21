import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'traductions_en.dart';
import 'traductions_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Traductions
/// returned by `Traductions.of(context)`.
///
/// Applications need to include `Traductions.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/traductions.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Traductions.localizationsDelegates,
///   supportedLocales: Traductions.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Traductions.supportedLocales
/// property.
abstract class Traductions {
  Traductions(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Traductions of(BuildContext context) {
    return Localizations.of<Traductions>(context, Traductions)!;
  }

  static const LocalizationsDelegate<Traductions> delegate =
      _TraductionsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @nomApplication.
  ///
  /// In fr, this message translates to:
  /// **'Cantine Vatel'**
  String get nomApplication;

  /// No description provided for @signatureMarque.
  ///
  /// In fr, this message translates to:
  /// **'Commande · Repas · QR'**
  String get signatureMarque;

  /// No description provided for @accrocheBienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Réserve ton repas, choisis ton créneau, montre ton QR au comptoir.'**
  String get accrocheBienvenue;

  /// No description provided for @continuerAvecIdentifiant.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec mon numéro ou mon e-mail'**
  String get continuerAvecIdentifiant;

  /// No description provided for @continuerAvecGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continuerAvecGoogle;

  /// No description provided for @continuerAvecApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continuerAvecApple;

  /// No description provided for @bientotDisponible.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get bientotDisponible;

  /// No description provided for @ongletAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get ongletAccueil;

  /// No description provided for @ongletMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get ongletMenu;

  /// No description provided for @ongletTicket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get ongletTicket;

  /// No description provided for @ongletCompte.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get ongletCompte;

  /// No description provided for @ongletFamille.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get ongletFamille;

  /// No description provided for @ongletRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Recharge'**
  String get ongletRecharge;

  /// No description provided for @ongletMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get ongletMessages;

  /// No description provided for @ongletCollecte.
  ///
  /// In fr, this message translates to:
  /// **'Collecte'**
  String get ongletCollecte;

  /// No description provided for @ongletManifeste.
  ///
  /// In fr, this message translates to:
  /// **'Manifeste'**
  String get ongletManifeste;

  /// No description provided for @ongletReglages.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get ongletReglages;

  /// No description provided for @ongletTableauBord.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get ongletTableauBord;

  /// No description provided for @ongletCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get ongletCuisine;

  /// No description provided for @ongletMenus.
  ///
  /// In fr, this message translates to:
  /// **'Menus'**
  String get ongletMenus;

  /// No description provided for @ongletProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get ongletProfil;

  /// No description provided for @ongletNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get ongletNotifications;

  /// No description provided for @chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement'**
  String get chargement;

  /// No description provided for @etatVideTitre.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour le moment'**
  String get etatVideTitre;

  /// No description provided for @etatVideDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu ajouteras apparaîtra ici.'**
  String get etatVideDetail;

  /// No description provided for @erreurTitre.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get erreurTitre;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @bandeauHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne. Tu vois la dernière version chargée.'**
  String get bandeauHorsLigne;

  /// No description provided for @majLe.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour à {heure}'**
  String majLe(String heure);

  /// No description provided for @actionImpossibleHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Impossible hors ligne : réserver, recharger et payer demandent le réseau.'**
  String get actionImpossibleHorsLigne;

  /// No description provided for @modeTest.
  ///
  /// In fr, this message translates to:
  /// **'Mode test'**
  String get modeTest;

  /// No description provided for @pleinEcran.
  ///
  /// In fr, this message translates to:
  /// **'Plein écran'**
  String get pleinEcran;

  /// No description provided for @quitterPleinEcran.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le plein écran'**
  String get quitterPleinEcran;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeSysteme.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSysteme;

  /// No description provided for @themeClair.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeClair;

  /// No description provided for @themeSombre.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeSombre;

  /// No description provided for @langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langue;

  /// No description provided for @francais.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @anglais.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get anglais;

  /// No description provided for @sessionExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Connecte-toi à nouveau.'**
  String get sessionExpiree;

  /// No description provided for @erreurReseau.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur est injoignable. Vérifie ta connexion.'**
  String get erreurReseau;

  /// No description provided for @pageIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Cette page n\'existe pas.'**
  String get pageIntrouvable;

  /// No description provided for @retourAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à l\'accueil'**
  String get retourAccueil;

  /// No description provided for @ecranEnConstruction.
  ///
  /// In fr, this message translates to:
  /// **'Écran en construction'**
  String get ecranEnConstruction;

  /// No description provided for @connexionCodeQr.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec un code QR'**
  String get connexionCodeQr;

  /// No description provided for @ouvrirSurWebPc.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir sur Web / PC'**
  String get ouvrirSurWebPc;

  /// No description provided for @disponibleSur.
  ///
  /// In fr, this message translates to:
  /// **'Disponible sur'**
  String get disponibleSur;

  /// No description provided for @telechargerDans.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger dans'**
  String get telechargerDans;

  /// No description provided for @lienPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Lien de paiement'**
  String get lienPaiement;

  /// No description provided for @serviceEntree.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get serviceEntree;

  /// No description provided for @serviceResistance.
  ///
  /// In fr, this message translates to:
  /// **'Résistance'**
  String get serviceResistance;

  /// No description provided for @serviceSortie.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get serviceSortie;

  /// No description provided for @porteeJour.
  ///
  /// In fr, this message translates to:
  /// **'La journée'**
  String get porteeJour;

  /// No description provided for @porteeSemaine.
  ///
  /// In fr, this message translates to:
  /// **'La semaine'**
  String get porteeSemaine;

  /// No description provided for @porteeMois.
  ///
  /// In fr, this message translates to:
  /// **'Le mois'**
  String get porteeMois;

  /// No description provided for @reserverPeriode.
  ///
  /// In fr, this message translates to:
  /// **'Réserver la période'**
  String get reserverPeriode;

  /// No description provided for @totalPeriode.
  ///
  /// In fr, this message translates to:
  /// **'Total de la période'**
  String get totalPeriode;

  /// No description provided for @choisirParService.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un plat par service'**
  String get choisirParService;

  /// No description provided for @creerCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerCompte;

  /// No description provided for @jaiUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get jaiUnCompte;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @identifiantNumero.
  ///
  /// In fr, this message translates to:
  /// **'Numéro'**
  String get identifiantNumero;

  /// No description provided for @identifiantEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get identifiantEmail;

  /// No description provided for @champNumero.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get champNumero;

  /// No description provided for @champEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get champEmail;

  /// No description provided for @prenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get prenom;

  /// No description provided for @nom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nom;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get nouveauMotDePasse;

  /// No description provided for @regleHuitCaracteres.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins'**
  String get regleHuitCaracteres;

  /// No description provided for @regleUneLettre.
  ///
  /// In fr, this message translates to:
  /// **'Une lettre'**
  String get regleUneLettre;

  /// No description provided for @regleUnChiffre.
  ///
  /// In fr, this message translates to:
  /// **'Un chiffre'**
  String get regleUnChiffre;

  /// No description provided for @jeSuis.
  ///
  /// In fr, this message translates to:
  /// **'Je suis'**
  String get jeSuis;

  /// No description provided for @roleConvive.
  ///
  /// In fr, this message translates to:
  /// **'Un convive'**
  String get roleConvive;

  /// No description provided for @roleParent.
  ///
  /// In fr, this message translates to:
  /// **'Un parent'**
  String get roleParent;

  /// No description provided for @profilTarifaire.
  ///
  /// In fr, this message translates to:
  /// **'Profil tarifaire'**
  String get profilTarifaire;

  /// No description provided for @statutEleve.
  ///
  /// In fr, this message translates to:
  /// **'Élève'**
  String get statutEleve;

  /// No description provided for @statutEtudiant.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant'**
  String get statutEtudiant;

  /// No description provided for @statutEmploye.
  ///
  /// In fr, this message translates to:
  /// **'Employé'**
  String get statutEmploye;

  /// No description provided for @statutAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get statutAutre;

  /// No description provided for @accepterConditions.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les conditions d\'utilisation'**
  String get accepterConditions;

  /// No description provided for @continuer.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continuer;

  /// No description provided for @valider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get valider;

  /// No description provided for @retour.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get retour;

  /// No description provided for @titreCode.
  ///
  /// In fr, this message translates to:
  /// **'Entre le code'**
  String get titreCode;

  /// No description provided for @sousTitreCodeTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres envoyé au {identifiant}'**
  String sousTitreCodeTelephone(String identifiant);

  /// No description provided for @sousTitreCodeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code de 5 caractères envoyé à {identifiant}'**
  String sousTitreCodeEmail(String identifiant);

  /// No description provided for @modeDemoCodeRempli.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo : code rempli automatiquement'**
  String get modeDemoCodeRempli;

  /// No description provided for @penseAuxIndesirables.
  ///
  /// In fr, this message translates to:
  /// **'Pense à regarder dans les indésirables si tu ne vois rien.'**
  String get penseAuxIndesirables;

  /// No description provided for @renvoyerDans.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {secondes} s'**
  String renvoyerDans(int secondes);

  /// No description provided for @renvoyerLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get renvoyerLeCode;

  /// No description provided for @motDePasseOublie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get motDePasseOublie;

  /// No description provided for @reinitialiserMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get reinitialiserMotDePasse;

  /// No description provided for @deconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get deconnexion;

  /// No description provided for @champObligatoire.
  ///
  /// In fr, this message translates to:
  /// **'À remplir'**
  String get champObligatoire;

  /// No description provided for @numeroInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro ivoirien attendu, 10 chiffres après +225'**
  String get numeroInvalide;

  /// No description provided for @emailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail attendue'**
  String get emailInvalide;

  /// No description provided for @conditionsRequises.
  ///
  /// In fr, this message translates to:
  /// **'Accepte les conditions pour continuer'**
  String get conditionsRequises;

  /// No description provided for @motDePasseFaible.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop simple'**
  String get motDePasseFaible;

  /// No description provided for @compteCree.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Vérifie ton identifiant.'**
  String get compteCree;

  /// No description provided for @motDePasseChange.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé. Connecte-toi.'**
  String get motDePasseChange;

  /// No description provided for @bonjour.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get bonjour;

  /// No description provided for @soldeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get soldeTitre;

  /// No description provided for @repasDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Ton repas du jour'**
  String get repasDuJour;

  /// No description provided for @aucunRepasDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as rien commandé pour aujourd\'hui'**
  String get aucunRepasDuJour;

  /// No description provided for @commanderRepas.
  ///
  /// In fr, this message translates to:
  /// **'Commander un repas'**
  String get commanderRepas;

  /// No description provided for @menuDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Le menu du jour'**
  String get menuDuJour;

  /// No description provided for @voirLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Voir la semaine'**
  String get voirLaSemaine;

  /// No description provided for @semaineTitre.
  ///
  /// In fr, this message translates to:
  /// **'Menu de la semaine'**
  String get semaineTitre;

  /// No description provided for @aujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aujourdhui;

  /// No description provided for @demain.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get demain;

  /// No description provided for @aucunMenu.
  ///
  /// In fr, this message translates to:
  /// **'Pas de menu publié ce jour'**
  String get aucunMenu;

  /// No description provided for @prixDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Repas du jour'**
  String get prixDuJour;

  /// No description provided for @partEnPlus.
  ///
  /// In fr, this message translates to:
  /// **'Part en plus {prix}'**
  String partEnPlus(String prix);

  /// No description provided for @allergeneAlerte.
  ///
  /// In fr, this message translates to:
  /// **'Contient {allergene}, déclaré dans ton profil'**
  String allergeneAlerte(String allergene);

  /// No description provided for @allergenes.
  ///
  /// In fr, this message translates to:
  /// **'Allergènes'**
  String get allergenes;

  /// No description provided for @regimes.
  ///
  /// In fr, this message translates to:
  /// **'Régimes'**
  String get regimes;

  /// No description provided for @calories.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @heureLimiteLe.
  ///
  /// In fr, this message translates to:
  /// **'Commande avant {heure}'**
  String heureLimiteLe(String heure);

  /// No description provided for @geleLaVeille.
  ///
  /// In fr, this message translates to:
  /// **'Modifiable jusqu à la veille {heure}'**
  String geleLaVeille(String heure);

  /// No description provided for @jourLundi.
  ///
  /// In fr, this message translates to:
  /// **'lundi'**
  String get jourLundi;

  /// No description provided for @jourMardi.
  ///
  /// In fr, this message translates to:
  /// **'mardi'**
  String get jourMardi;

  /// No description provided for @jourMercredi.
  ///
  /// In fr, this message translates to:
  /// **'mercredi'**
  String get jourMercredi;

  /// No description provided for @jourJeudi.
  ///
  /// In fr, this message translates to:
  /// **'jeudi'**
  String get jourJeudi;

  /// No description provided for @jourVendredi.
  ///
  /// In fr, this message translates to:
  /// **'vendredi'**
  String get jourVendredi;

  /// No description provided for @jourSamedi.
  ///
  /// In fr, this message translates to:
  /// **'samedi'**
  String get jourSamedi;

  /// No description provided for @jourDimanche.
  ///
  /// In fr, this message translates to:
  /// **'dimanche'**
  String get jourDimanche;

  /// No description provided for @donneesDemo.
  ///
  /// In fr, this message translates to:
  /// **'Données de démonstration'**
  String get donneesDemo;
}

class _TraductionsDelegate extends LocalizationsDelegate<Traductions> {
  const _TraductionsDelegate();

  @override
  Future<Traductions> load(Locale locale) {
    return SynchronousFuture<Traductions>(lookupTraductions(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_TraductionsDelegate old) => false;
}

Traductions lookupTraductions(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TraductionsEn();
    case 'fr':
      return TraductionsFr();
  }

  throw FlutterError(
    'Traductions.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
