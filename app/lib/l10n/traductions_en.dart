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
  String get signatureMarque => 'Order · Meal · QR';

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

  @override
  String get creerCompte => 'Create an account';

  @override
  String get jaiUnCompte => 'I already have an account';

  @override
  String get seConnecter => 'Sign in';

  @override
  String get identifiantNumero => 'Number';

  @override
  String get identifiantEmail => 'Email';

  @override
  String get champNumero => 'Phone number';

  @override
  String get champEmail => 'Email address';

  @override
  String get prenom => 'First name';

  @override
  String get nom => 'Last name';

  @override
  String get motDePasse => 'Password';

  @override
  String get nouveauMotDePasse => 'New password';

  @override
  String get regleHuitCaracteres => 'At least 8 characters';

  @override
  String get regleUneLettre => 'One letter';

  @override
  String get regleUnChiffre => 'One digit';

  @override
  String get jeSuis => 'I am';

  @override
  String get roleConvive => 'A diner';

  @override
  String get roleParent => 'A parent';

  @override
  String get profilTarifaire => 'Price profile';

  @override
  String get statutEleve => 'Pupil';

  @override
  String get statutEtudiant => 'Student';

  @override
  String get statutEmploye => 'Employee';

  @override
  String get statutAutre => 'Other';

  @override
  String get accepterConditions => 'I accept the terms of use';

  @override
  String get continuer => 'Continue';

  @override
  String get valider => 'Confirm';

  @override
  String get retour => 'Back';

  @override
  String get titreCode => 'Enter the code';

  @override
  String sousTitreCodeTelephone(String identifiant) {
    return '6-digit code sent to $identifiant';
  }

  @override
  String sousTitreCodeEmail(String identifiant) {
    return '5-character code sent to $identifiant';
  }

  @override
  String get modeDemoCodeRempli => 'Demo mode: code filled in automatically';

  @override
  String get penseAuxIndesirables =>
      'Check your spam folder if you see nothing.';

  @override
  String renvoyerDans(int secondes) {
    return 'Resend the code in ${secondes}s';
  }

  @override
  String get renvoyerLeCode => 'Resend the code';

  @override
  String get motDePasseOublie => 'Forgot password';

  @override
  String get reinitialiserMotDePasse => 'Reset password';

  @override
  String get deconnexion => 'Sign out';

  @override
  String get champObligatoire => 'Required';

  @override
  String get numeroInvalide => 'Ivorian number expected, 10 digits after +225';

  @override
  String get emailInvalide => 'Email address expected';

  @override
  String get conditionsRequises => 'Accept the terms to continue';

  @override
  String get motDePasseFaible => 'Password too simple';

  @override
  String get compteCree => 'Account created. Verify your identifier.';

  @override
  String get motDePasseChange => 'Password changed. Sign in.';

  @override
  String get bonjour => 'Hello';

  @override
  String get soldeTitre => 'Balance';

  @override
  String get repasDuJour => 'Your meal today';

  @override
  String get aucunRepasDuJour => 'You have not ordered anything for today';

  @override
  String get commanderRepas => 'Order a meal';

  @override
  String get menuDuJour => 'Today\'s menu';

  @override
  String get voirLaSemaine => 'See the week';

  @override
  String get semaineTitre => 'Menu of the week';

  @override
  String get aujourdhui => 'Today';

  @override
  String get demain => 'Tomorrow';

  @override
  String get aucunMenu => 'No menu published that day';

  @override
  String get prixDuJour => 'Meal of the day';

  @override
  String partEnPlus(String prix) {
    return 'Extra portion $prix';
  }

  @override
  String allergeneAlerte(String allergene) {
    return 'Contains $allergene, listed in your profile';
  }

  @override
  String get allergenes => 'Allergens';

  @override
  String get regimes => 'Diets';

  @override
  String get calories => 'Calories';

  @override
  String get note => 'Rating';

  @override
  String heureLimiteLe(String heure) {
    return 'Order before $heure';
  }

  @override
  String geleLaVeille(String heure) {
    return 'Editable until the day before $heure';
  }

  @override
  String get jourLundi => 'Monday';

  @override
  String get jourMardi => 'Tuesday';

  @override
  String get jourMercredi => 'Wednesday';

  @override
  String get jourJeudi => 'Thursday';

  @override
  String get jourVendredi => 'Friday';

  @override
  String get jourSamedi => 'Saturday';

  @override
  String get jourDimanche => 'Sunday';

  @override
  String get donneesDemo => 'Demonstration data';

  @override
  String get commandeTitre => 'Order';

  @override
  String get choisirPortee => 'For which period?';

  @override
  String get totalApayer => 'Total';

  @override
  String get soldeApres => 'Balance after';

  @override
  String get confirmerCommande => 'Confirm the order';

  @override
  String get soldeInsuffisant => 'Balance too low for this order';

  @override
  String get commandeEnregistree => 'Order saved';

  @override
  String get mesCommandes => 'My orders';

  @override
  String get aVenir => 'Upcoming';

  @override
  String get passees => 'Past';

  @override
  String get annulerCommande => 'Cancel';

  @override
  String get supprimerSansRemboursement => 'Delete, no refund';

  @override
  String get aucuneCommande => 'No order yet';

  @override
  String get mouvementsTitre => 'Transactions';

  @override
  String joursChoisis(int jours) {
    return '$jours day(s) selected';
  }

  @override
  String get rienChoisiCeJour => 'Nothing selected that day';

  @override
  String get commandeGeleeInfo =>
      'Frozen since the day before, cannot be changed';

  @override
  String get publierMenu => 'Publish';

  @override
  String get etatBrouillon => 'Draft';

  @override
  String get etatPublie => 'Published';

  @override
  String get creerMenuJour => 'Create that day menu';

  @override
  String get catalogue => 'Catalogue';

  @override
  String get platsDuMenu => 'Dishes on the menu';

  @override
  String get nouveauPlat => 'New dish';

  @override
  String get enregistrer => 'Save';

  @override
  String get supprimer => 'Delete';

  @override
  String get tarifsTitre => 'Prices by profile';

  @override
  String get nomDuPlat => 'Dish name';

  @override
  String get descriptionPlat => 'Description';

  @override
  String get supplementPrix => 'Extra portion price';

  @override
  String get aucunPlatAuMenu => 'No dish on the menu that day';

  @override
  String get menusTitre => 'Menus of the week';

  @override
  String get platsTitre => 'Dishes';

  @override
  String get repasServis => 'Meals served';

  @override
  String get nonReclames => 'Unclaimed';

  @override
  String get recettesBrutes => 'Gross revenue';

  @override
  String get fraisGeniusPay => 'GeniusPay fees';

  @override
  String get netAttendu => 'Expected net';

  @override
  String get platsLesPlusReserves => 'Most ordered dishes';

  @override
  String get septDerniersJours => 'Last seven days';

  @override
  String get aPreparer => 'To prepare';

  @override
  String partsServies(int servies, int parts) {
    return '$servies of $parts served';
  }

  @override
  String get ajusterSolde => 'Adjust a balance';

  @override
  String get montant => 'Amount';

  @override
  String get motif => 'Reason';

  @override
  String get motDePasseActions => 'Actions password';

  @override
  String get appliquer => 'Apply';

  @override
  String get crediter => 'Credit';

  @override
  String get debiter => 'Debit';

  @override
  String get ajustementFait => 'Adjustment saved';

  @override
  String get identifiantConvive => 'Diner identifier';

  @override
  String actualiseA(String heure) {
    return 'Updated at $heure';
  }

  @override
  String get budgetTitre => 'Budget and finances';

  @override
  String get soldeGlobal => 'Overall balance';

  @override
  String get totalEntrees => 'Total in';

  @override
  String get totalSorties => 'Total out';

  @override
  String get soldeCeMois => 'Balance this month';

  @override
  String get entreesCeMois => 'In this month';

  @override
  String get sortiesCeMois => 'Out this month';

  @override
  String get nouvelleEntree => 'New entry';

  @override
  String get calendrierBudget => 'Budget calendar';

  @override
  String get evolutionMensuelle => 'Monthly trend';

  @override
  String get repartitionSorties => 'Spending breakdown';

  @override
  String get ligneAutomatique => 'Automatic';

  @override
  String get entree => 'In';

  @override
  String get sortie => 'Out';

  @override
  String get budgetExplication =>
      'Real money: confirmed payments and their fees post themselves, the rest is entered by hand.';

  @override
  String get jaccepteLes => 'I accept the';

  @override
  String get conditionsUtilisation => 'terms of use';

  @override
  String get confirmerMotDePasse => 'Confirm the password';

  @override
  String get motsDePasseDifferents => 'The two passwords do not match';

  @override
  String get scanAccepte => 'Served';

  @override
  String get scanDejaServi => 'Already served';

  @override
  String get scanInconnu => 'Unknown ticket';

  @override
  String get scanMauvaisJour => 'Not for today';

  @override
  String get scanAnnule => 'Order cancelled';

  @override
  String get saisieManuelle => 'Enter the code by hand';

  @override
  String get codeDuTicket => 'Ticket code';

  @override
  String get modeComptoir => 'Counter mode';

  @override
  String get serviceEnCours => 'Service in progress';

  @override
  String scansAEnvoyer(int nombre) {
    return 'Offline, $nombre scan(s) to send';
  }

  @override
  String get attendus => 'Expected';

  @override
  String get servis => 'Served';

  @override
  String get restants => 'Remaining';

  @override
  String get toucherPourContinuer => 'Tap to continue';
}
