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
  /// **'Créneau · Repas · QR'**
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
