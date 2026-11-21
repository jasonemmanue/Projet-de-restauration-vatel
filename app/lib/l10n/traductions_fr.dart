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
  String get signatureMarque => 'Commande · Repas · QR';

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

  @override
  String get creerCompte => 'Créer un compte';

  @override
  String get jaiUnCompte => 'J\'ai déjà un compte';

  @override
  String get seConnecter => 'Se connecter';

  @override
  String get identifiantNumero => 'Numéro';

  @override
  String get identifiantEmail => 'E-mail';

  @override
  String get champNumero => 'Numéro de téléphone';

  @override
  String get champEmail => 'Adresse e-mail';

  @override
  String get prenom => 'Prénom';

  @override
  String get nom => 'Nom';

  @override
  String get motDePasse => 'Mot de passe';

  @override
  String get nouveauMotDePasse => 'Nouveau mot de passe';

  @override
  String get regleHuitCaracteres => '8 caractères au moins';

  @override
  String get regleUneLettre => 'Une lettre';

  @override
  String get regleUnChiffre => 'Un chiffre';

  @override
  String get jeSuis => 'Je suis';

  @override
  String get roleConvive => 'Un convive';

  @override
  String get roleParent => 'Un parent';

  @override
  String get profilTarifaire => 'Profil tarifaire';

  @override
  String get statutEleve => 'Élève';

  @override
  String get statutEtudiant => 'Étudiant';

  @override
  String get statutEmploye => 'Employé';

  @override
  String get statutAutre => 'Autre';

  @override
  String get accepterConditions => 'J\'accepte les conditions d\'utilisation';

  @override
  String get continuer => 'Continuer';

  @override
  String get valider => 'Valider';

  @override
  String get retour => 'Retour';

  @override
  String get titreCode => 'Entre le code';

  @override
  String sousTitreCodeTelephone(String identifiant) {
    return 'Code à 6 chiffres envoyé au $identifiant';
  }

  @override
  String sousTitreCodeEmail(String identifiant) {
    return 'Code de 5 caractères envoyé à $identifiant';
  }

  @override
  String get modeDemoCodeRempli => 'Mode démo : code rempli automatiquement';

  @override
  String get penseAuxIndesirables =>
      'Pense à regarder dans les indésirables si tu ne vois rien.';

  @override
  String renvoyerDans(int secondes) {
    return 'Renvoyer le code dans $secondes s';
  }

  @override
  String get renvoyerLeCode => 'Renvoyer le code';

  @override
  String get motDePasseOublie => 'Mot de passe oublié';

  @override
  String get reinitialiserMotDePasse => 'Réinitialiser le mot de passe';

  @override
  String get deconnexion => 'Se déconnecter';

  @override
  String get champObligatoire => 'À remplir';

  @override
  String get numeroInvalide =>
      'Numéro ivoirien attendu, 10 chiffres après +225';

  @override
  String get emailInvalide => 'Adresse e-mail attendue';

  @override
  String get conditionsRequises => 'Accepte les conditions pour continuer';

  @override
  String get motDePasseFaible => 'Mot de passe trop simple';

  @override
  String get compteCree => 'Compte créé. Vérifie ton identifiant.';

  @override
  String get motDePasseChange => 'Mot de passe changé. Connecte-toi.';

  @override
  String get bonjour => 'Bonjour';

  @override
  String get soldeTitre => 'Solde';

  @override
  String get repasDuJour => 'Ton repas du jour';

  @override
  String get aucunRepasDuJour => 'Tu n\'as rien commandé pour aujourd\'hui';

  @override
  String get commanderRepas => 'Commander un repas';

  @override
  String get menuDuJour => 'Le menu du jour';

  @override
  String get voirLaSemaine => 'Voir la semaine';

  @override
  String get semaineTitre => 'Menu de la semaine';

  @override
  String get aujourdhui => 'Aujourd\'hui';

  @override
  String get demain => 'Demain';

  @override
  String get aucunMenu => 'Pas de menu publié ce jour';

  @override
  String get prixDuJour => 'Repas du jour';

  @override
  String partEnPlus(String prix) {
    return 'Part en plus $prix';
  }

  @override
  String allergeneAlerte(String allergene) {
    return 'Contient $allergene, déclaré dans ton profil';
  }

  @override
  String get allergenes => 'Allergènes';

  @override
  String get regimes => 'Régimes';

  @override
  String get calories => 'Calories';

  @override
  String get note => 'Note';

  @override
  String heureLimiteLe(String heure) {
    return 'Commande avant $heure';
  }

  @override
  String geleLaVeille(String heure) {
    return 'Modifiable jusqu à la veille $heure';
  }

  @override
  String get jourLundi => 'lundi';

  @override
  String get jourMardi => 'mardi';

  @override
  String get jourMercredi => 'mercredi';

  @override
  String get jourJeudi => 'jeudi';

  @override
  String get jourVendredi => 'vendredi';

  @override
  String get jourSamedi => 'samedi';

  @override
  String get jourDimanche => 'dimanche';

  @override
  String get donneesDemo => 'Données de démonstration';

  @override
  String get commandeTitre => 'Commander';

  @override
  String get choisirPortee => 'Pour quelle période ?';

  @override
  String get totalApayer => 'Total';

  @override
  String get soldeApres => 'Solde après';

  @override
  String get confirmerCommande => 'Confirmer la commande';

  @override
  String get soldeInsuffisant => 'Solde insuffisant pour cette commande';

  @override
  String get commandeEnregistree => 'Commande enregistrée';

  @override
  String get mesCommandes => 'Mes commandes';

  @override
  String get aVenir => 'À venir';

  @override
  String get passees => 'Passées';

  @override
  String get annulerCommande => 'Annuler';

  @override
  String get supprimerSansRemboursement => 'Supprimer, sans remboursement';

  @override
  String get aucuneCommande => 'Aucune commande pour le moment';

  @override
  String get mouvementsTitre => 'Mouvements';

  @override
  String joursChoisis(int jours) {
    return '$jours jour(s) choisi(s)';
  }

  @override
  String get rienChoisiCeJour => 'Rien choisi ce jour';

  @override
  String get commandeGeleeInfo =>
      'Figée depuis la veille, modification impossible';

  @override
  String get publierMenu => 'Publier';

  @override
  String get etatBrouillon => 'Brouillon';

  @override
  String get etatPublie => 'Publié';

  @override
  String get creerMenuJour => 'Créer le menu de ce jour';

  @override
  String get catalogue => 'Catalogue';

  @override
  String get platsDuMenu => 'Plats du menu';

  @override
  String get nouveauPlat => 'Nouveau plat';

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get supprimer => 'Supprimer';

  @override
  String get tarifsTitre => 'Tarifs par profil';

  @override
  String get nomDuPlat => 'Nom du plat';

  @override
  String get descriptionPlat => 'Description';

  @override
  String get supplementPrix => 'Prix de la part en plus';

  @override
  String get aucunPlatAuMenu => 'Aucun plat au menu ce jour';

  @override
  String get menusTitre => 'Menus de la semaine';

  @override
  String get platsTitre => 'Plats';

  @override
  String get repasServis => 'Repas servis';

  @override
  String get nonReclames => 'Non réclamés';

  @override
  String get recettesBrutes => 'Recettes brutes';

  @override
  String get fraisGeniusPay => 'Frais GeniusPay';

  @override
  String get netAttendu => 'Net attendu';

  @override
  String get platsLesPlusReserves => 'Plats les plus commandés';

  @override
  String get septDerniersJours => 'Sept derniers jours';

  @override
  String get aPreparer => 'À préparer';

  @override
  String partsServies(int servies, int parts) {
    return '$servies sur $parts servies';
  }

  @override
  String get ajusterSolde => 'Ajuster un solde';

  @override
  String get montant => 'Montant';

  @override
  String get motif => 'Motif';

  @override
  String get motDePasseActions => 'Mot de passe des actions';

  @override
  String get appliquer => 'Appliquer';

  @override
  String get crediter => 'Créditer';

  @override
  String get debiter => 'Débiter';

  @override
  String get ajustementFait => 'Ajustement enregistré';

  @override
  String get identifiantConvive => 'Identifiant du convive';

  @override
  String actualiseA(String heure) {
    return 'Actualisé à $heure';
  }

  @override
  String get budgetTitre => 'Budget et finances';

  @override
  String get soldeGlobal => 'Solde global';

  @override
  String get totalEntrees => 'Total entrées';

  @override
  String get totalSorties => 'Total sorties';

  @override
  String get soldeCeMois => 'Solde ce mois';

  @override
  String get entreesCeMois => 'Entrées ce mois';

  @override
  String get sortiesCeMois => 'Sorties ce mois';

  @override
  String get nouvelleEntree => 'Nouvelle entrée';

  @override
  String get calendrierBudget => 'Calendrier budgétaire';

  @override
  String get evolutionMensuelle => 'Évolution mensuelle';

  @override
  String get repartitionSorties => 'Répartition des sorties';

  @override
  String get ligneAutomatique => 'Automatique';

  @override
  String get entree => 'Entrée';

  @override
  String get sortie => 'Sortie';

  @override
  String get budgetExplication =>
      'Argent réel : paiements confirmés et leurs frais s\'inscrivent seuls, le reste se saisit à la main.';

  @override
  String get jaccepteLes => 'J\'accepte les';

  @override
  String get conditionsUtilisation => 'conditions d\'utilisation';

  @override
  String get confirmerMotDePasse => 'Confirmer le mot de passe';

  @override
  String get motsDePasseDifferents =>
      'Les deux mots de passe ne sont pas les mêmes';
}
