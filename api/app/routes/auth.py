"""Routes /api/v1/auth : inscription, connexion, vérification, mot de passe oublié, jetons, déconnexion."""

from fastapi import APIRouter, Request

from app.core.dependances import UtilisateurCourant, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Utilisateur
from app.schemas.comptes import (
    CodeEnvoyeSortie,
    CodeRequisSortie,
    ConfirmationConnexionEntree,
    ConfirmationEntree,
    ConnexionEntree,
    DemandeCodeEntree,
    InscriptionEntree,
    InscriptionSortie,
    JetonsSortie,
    OubliEntree,
    RafraichissementEntree,
    ReinitialisationEntree,
    SessionSortie,
    UtilisateurSortie,
)
from app.services import comptes, sessions, verification

routeur = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def vue_utilisateur(utilisateur: Utilisateur) -> UtilisateurSortie:
    """Construit la vue d'un compte rendue au client."""
    return UtilisateurSortie(
        id=utilisateur.id,
        prenom=utilisateur.prenom,
        nom=utilisateur.nom,
        nom_complet=utilisateur.nom_complet,
        role=utilisateur.role,
        statut_convive=utilisateur.statut_convive,
        langue=utilisateur.langue,
        email=utilisateur.email,
        telephone=utilisateur.telephone,
        verifie=comptes.est_verifie(utilisateur),
        canal_a_verifier=comptes.canal_a_verifier(utilisateur),  # type: ignore[arg-type]
    )


@routeur.post("/inscription", response_model=InscriptionSortie, status_code=201)
async def inscrire(corps: InscriptionEntree, request: Request, session: SessionBase) -> InscriptionSortie:
    """Crée un compte convive ou parent, à vérifier, et ouvre sa session."""
    if not corps.conditions_acceptees:
        raise ErreurApi("conditions_requises", 422)
    if (corps.role == "convive") != (corps.statut_convive is not None):
        raise ErreurApi("validation", 422)
    config = request.app.state.config
    identifiant = comptes.lire_identifiant(corps.identifiant, corps.type)
    donnees = comptes.NouveauCompte(
        identifiant=identifiant,
        mot_de_passe=corps.mot_de_passe,
        prenom=corps.prenom.strip(),
        nom=corps.nom.strip(),
        role=corps.role,
        statut_convive=corps.statut_convive,
    )
    utilisateur = await comptes.creer_compte(session, config, donnees, verifie=False, consentement=True)
    appareil = sessions.Appareil(corps.appareil.nom, corps.appareil.plateforme)
    jetons = await sessions.ouvrir_session(session, config, utilisateur, appareil, adresse_client(request))
    return InscriptionSortie(
        utilisateur_id=utilisateur.id,
        canal=identifiant.canal,  # type: ignore[arg-type]
        jeton=jetons.jeton,
        jeton_rafraichissement=jetons.jeton_rafraichissement,
        expire_dans=jetons.expire_dans,
        utilisateur=vue_utilisateur(utilisateur),
    )


@routeur.post("/connexion", response_model=SessionSortie | CodeRequisSortie, response_model_exclude_none=True)
async def connecter(
    corps: ConnexionEntree, request: Request, session: SessionBase
) -> SessionSortie | CodeRequisSortie:
    """Ouvre une session, ou demande un code si le compte revient après plus de 5 jours d'absence."""
    appareil = sessions.Appareil(corps.appareil.nom, corps.appareil.plateforme)
    resultat = await comptes.connecter(
        session,
        request.app.state.config,
        corps.identifiant,
        corps.mot_de_passe,
        appareil,
        adresse_client(request),
    )
    if resultat.code is not None:
        return CodeRequisSortie(
            canal=resultat.code.canal,  # type: ignore[arg-type]
            mode_livraison=resultat.code.mode_livraison,  # type: ignore[arg-type]
            expire_le=resultat.code.expire_le,
            code_demo=resultat.code.code_demo,
        )
    if resultat.jetons is None:
        raise ErreurApi("erreur_serveur", 500)
    return _sortie_session(resultat.utilisateur, resultat.jetons)


@routeur.post("/connexion/confirmer", response_model=SessionSortie)
async def confirmer_connexion(
    corps: ConfirmationConnexionEntree, request: Request, session: SessionBase
) -> SessionSortie:
    """Contrôle le code reçu après le mot de passe et ouvre la session."""
    utilisateur_trouve = await comptes.trouver(session, comptes.lire_identifiant(corps.identifiant))
    if utilisateur_trouve is None:
        raise ErreurApi("code_invalide", 400)
    utilisateur, jetons = await comptes.confirmer_retour(
        session,
        request.app.state.config,
        comptes.identifiant_du_compte(utilisateur_trouve),
        corps.code,
        sessions.Appareil(corps.appareil.nom, corps.appareil.plateforme),
        adresse_client(request),
    )
    return _sortie_session(utilisateur, jetons)


def _sortie_session(utilisateur: Utilisateur, jetons: sessions.Jetons) -> SessionSortie:
    return SessionSortie(
        jeton=jetons.jeton,
        jeton_rafraichissement=jetons.jeton_rafraichissement,
        expire_dans=jetons.expire_dans,
        utilisateur=vue_utilisateur(utilisateur),
    )


def _sortie_code(envoi: verification.CodeEnvoye) -> CodeEnvoyeSortie:
    return CodeEnvoyeSortie(
        mode_livraison=envoi.mode_livraison,  # type: ignore[arg-type]
        expire_le=envoi.expire_le,
        code_demo=envoi.code_demo,
    )


@routeur.post("/verification/envoyer", response_model=CodeEnvoyeSortie, response_model_exclude_none=True)
async def envoyer_code(corps: DemandeCodeEntree, request: Request, session: SessionBase) -> CodeEnvoyeSortie:
    """Tire un code de vérification ; même réponse que le compte existe ou non."""
    identifiant = comptes.lire_identifiant(corps.identifiant, corps.canal)
    envoi = await comptes.demander_code_compte(
        session, request.app.state.config, identifiant, corps.usage, adresse_client(request)
    )
    return _sortie_code(envoi)


@routeur.post("/verification/confirmer")
async def confirmer_code(
    corps: ConfirmationEntree, request: Request, session: SessionBase
) -> dict[str, bool]:
    """Contrôle le code et marque l'identifiant comme vérifié ; la session déjà ouverte reste valable."""
    identifiant = comptes.lire_identifiant(corps.identifiant, corps.canal)
    await comptes.confirmer_identifiant(
        session, request.app.state.config, identifiant, corps.code, adresse_client(request)
    )
    return {"verifie": True}


@routeur.post("/mot-de-passe/oublie", response_model=CodeEnvoyeSortie, response_model_exclude_none=True)
async def oublier_mot_de_passe(
    corps: OubliEntree, request: Request, session: SessionBase
) -> CodeEnvoyeSortie:
    """Tire un code de réinitialisation ; aucun code_demo pour un identifiant sans compte."""
    identifiant = comptes.lire_identifiant(corps.identifiant, corps.canal)
    envoi = await comptes.demander_code_compte(
        session,
        request.app.state.config,
        identifiant,
        verification.USAGE_REINITIALISATION,
        adresse_client(request),
    )
    return _sortie_code(envoi)


@routeur.post("/mot-de-passe/reinitialiser")
async def reinitialiser(
    corps: ReinitialisationEntree, request: Request, session: SessionBase
) -> dict[str, bool]:
    """Remplace le mot de passe après contrôle du code ; toutes les sessions sont fermées."""
    identifiant = comptes.lire_identifiant(corps.identifiant, corps.canal)
    await comptes.reinitialiser_mot_de_passe(
        session,
        request.app.state.config,
        identifiant,
        corps.code,
        corps.nouveau_mot_de_passe,
        adresse_client(request),
    )
    return {"reinitialise": True}


@routeur.post("/rafraichir", response_model=JetonsSortie)
async def rafraichir(corps: RafraichissementEntree, request: Request, session: SessionBase) -> JetonsSortie:
    """Échange le jeton de rafraîchissement contre de nouveaux jetons."""
    jetons = await sessions.rafraichir(session, request.app.state.config, corps.jeton_rafraichissement)
    return JetonsSortie(
        jeton=jetons.jeton,
        jeton_rafraichissement=jetons.jeton_rafraichissement,
        expire_dans=jetons.expire_dans,
    )


@routeur.post("/deconnexion")
async def deconnecter(connecte: UtilisateurCourant, session: SessionBase) -> dict[str, bool]:
    """Ferme la session courante, celle du jeton présenté."""
    await sessions.revoquer_session(session, connecte.session_id)
    return {"deconnecte": True}
