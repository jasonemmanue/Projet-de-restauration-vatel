// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'traductions.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TraductionsEn extends Traductions {
  TraductionsEn([String locale = 'en']) : super(locale);

  @override
  String get nomApplication => 'Cantine Vatel';

  @override
  String get signatureMarque => 'Slot · Meal · QR';

  @override
  String get accrocheBienvenue =>
      'Book your meal, pick your slot, show your QR at the counter.';

  @override
  String get continuerAvecIdentifiant => 'Continue with my number or email';

  @override
  String get continuerAvecGoogle => 'Continue with Google';

  @override
  String get continuerAvecApple => 'Continue with Apple';

  @override
  String get bientotDisponible => 'Coming soon';

  @override
  String get ongletAccueil => 'Home';

  @override
  String get ongletMenu => 'Menu';

  @override
  String get ongletTicket => 'Ticket';

  @override
  String get ongletCompte => 'Account';

  @override
  String get ongletFamille => 'Family';

  @override
  String get ongletRecharge => 'Top up';

  @override
  String get ongletMessages => 'Messages';

  @override
  String get ongletCollecte => 'Scan';

  @override
  String get ongletManifeste => 'Manifest';

  @override
  String get ongletReglages => 'Settings';

  @override
  String get ongletTableauBord => 'Dashboard';

  @override
  String get ongletCuisine => 'Kitchen';

  @override
  String get ongletMenus => 'Menus';

  @override
  String get ongletProfil => 'Profile';

  @override
  String get ongletNotifications => 'Notifications';

  @override
  String get chargement => 'Loading';

  @override
  String get etatVideTitre => 'Nothing yet';

  @override
  String get etatVideDetail => 'What you add will show up here.';

  @override
  String get erreurTitre => 'Something went wrong';

  @override
  String get reessayer => 'Try again';

  @override
  String get bandeauHorsLigne =>
      'Offline. You are seeing the last loaded version.';

  @override
  String majLe(String heure) {
    return 'Updated at $heure';
  }

  @override
  String get actionImpossibleHorsLigne =>
      'Not available offline: booking, top-ups and payments need the network.';

  @override
  String get modeTest => 'Test mode';

  @override
  String get pleinEcran => 'Full screen';

  @override
  String get quitterPleinEcran => 'Exit full screen';

  @override
  String get theme => 'Theme';

  @override
  String get themeSysteme => 'System';

  @override
  String get themeClair => 'Light';

  @override
  String get themeSombre => 'Dark';

  @override
  String get langue => 'Language';

  @override
  String get francais => 'French';

  @override
  String get anglais => 'English';

  @override
  String get sessionExpiree =>
      'Your session has expired. Please sign in again.';

  @override
  String get erreurReseau =>
      'The server is unreachable. Check your connection.';

  @override
  String get pageIntrouvable => 'This page does not exist.';

  @override
  String get retourAccueil => 'Back to home';

  @override
  String get ecranEnConstruction => 'Screen under construction';

  @override
  String get connexionCodeQr => 'Sign in with a QR code';

  @override
  String get ouvrirSurWebPc => 'Open on Web / PC';

  @override
  String get disponibleSur => 'Available on';

  @override
  String get telechargerDans => 'Download on';

  @override
  String get lienPaiement => 'Payment link';

  @override
  String get serviceEntree => 'Starter';

  @override
  String get serviceResistance => 'Main course';

  @override
  String get serviceSortie => 'Dessert';

  @override
  String get porteeJour => 'The day';

  @override
  String get porteeSemaine => 'The week';

  @override
  String get porteeMois => 'The month';

  @override
  String get reserverPeriode => 'Book the period';

  @override
  String get totalPeriode => 'Period total';

  @override
  String get choisirParService => 'Pick one dish per course';
}
