// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'traductions.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class TraductionsFr extends Traductions {
  TraductionsFr([String locale = 'fr']) : super(locale);

  @override
  String get nomApplication => 'Cantine Vatel';

  @override
  String get signatureMarque => 'Créneau · Repas · QR';

  @override
  String get accrocheBienvenue =>
      'Réserve ton repas, choisis ton créneau, montre ton QR au comptoir.';

  @override
  String get continuerAvecIdentifiant =>
      'Continuer avec mon numéro ou mon e-mail';

  @override
  String get continuerAvecGoogle => 'Continuer avec Google';

  @override
  String get continuerAvecApple => 'Continuer avec Apple';

  @override
  String get bientotDisponible => 'Bientôt disponible';

  @override
  String get ongletAccueil => 'Accueil';

  @override
  String get ongletMenu => 'Menu';

  @override
  String get ongletTicket => 'Ticket';

  @override
  String get ongletCompte => 'Compte';

  @override
  String get ongletFamille => 'Famille';

  @override
  String get ongletRecharge => 'Recharge';

  @override
  String get ongletMessages => 'Messages';

  @override
  String get ongletCollecte => 'Collecte';

  @override
  String get ongletManifeste => 'Manifeste';

  @override
  String get ongletReglages => 'Réglages';

  @override
  String get ongletTableauBord => 'Tableau de bord';

  @override
  String get ongletCuisine => 'Cuisine';

  @override
  String get ongletMenus => 'Menus';

  @override
  String get ongletProfil => 'Profil';

  @override
  String get ongletNotifications => 'Notifications';

  @override
  String get chargement => 'Chargement';

  @override
  String get etatVideTitre => 'Rien pour le moment';

  @override
  String get etatVideDetail => 'Ce que tu ajouteras apparaîtra ici.';

  @override
  String get erreurTitre => 'Une erreur est survenue';

  @override
  String get reessayer => 'Réessayer';

  @override
  String get bandeauHorsLigne =>
      'Hors ligne. Tu vois la dernière version chargée.';

  @override
  String majLe(String heure) {
    return 'Mis à jour à $heure';
  }

  @override
  String get actionImpossibleHorsLigne =>
      'Impossible hors ligne : réserver, recharger et payer demandent le réseau.';

  @override
  String get modeTest => 'Mode test';

  @override
  String get pleinEcran => 'Plein écran';

  @override
  String get quitterPleinEcran => 'Quitter le plein écran';

  @override
  String get theme => 'Thème';

  @override
  String get themeSysteme => 'Système';

  @override
  String get themeClair => 'Clair';

  @override
  String get themeSombre => 'Sombre';

  @override
  String get langue => 'Langue';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'Anglais';

  @override
  String get sessionExpiree => 'Ta session a expiré. Connecte-toi à nouveau.';

  @override
  String get erreurReseau =>
      'Le serveur est injoignable. Vérifie ta connexion.';

  @override
  String get pageIntrouvable => 'Cette page n\'existe pas.';

  @override
  String get retourAccueil => 'Revenir à l\'accueil';

  @override
  String get ecranEnConstruction => 'Écran en construction';

  @override
  String get connexionCodeQr => 'Se connecter avec un code QR';

  @override
  String get ouvrirSurWebPc => 'Ouvrir sur Web / PC';

  @override
  String get disponibleSur => 'Disponible sur';

  @override
  String get telechargerDans => 'Télécharger dans';

  @override
  String get lienPaiement => 'Lien de paiement';

  @override
  String get serviceEntree => 'Entrée';

  @override
  String get serviceResistance => 'Résistance';

  @override
  String get serviceSortie => 'Sortie';

  @override
  String get porteeJour => 'La journée';

  @override
  String get porteeSemaine => 'La semaine';

  @override
  String get porteeMois => 'Le mois';

  @override
  String get reserverPeriode => 'Réserver la période';

  @override
  String get totalPeriode => 'Total de la période';

  @override
  String get choisirParService => 'Choisis un plat par service';
}
