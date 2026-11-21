"""Schémas des routes de comptes : inscription, connexion, vérification, mot de passe, jetons."""

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

Canal = Literal["telephone", "email"]
# Même liste que STATUTS_CONVIVE du modèle ; un test vérifie qu'elles restent égales.
StatutConvive = Literal["eleve", "etudiant", "employe", "autre"]


class AppareilEntree(BaseModel):
    """Appareil déclaré à l'ouverture d'une session."""

    nom: str = Field(default="Appareil", min_length=1, max_length=80)
    plateforme: Literal["android", "ios", "web"] = "web"


class InscriptionEntree(BaseModel):
    """Corps de POST /auth/inscription."""

    type: Canal
    identifiant: str = Field(min_length=3, max_length=254)
    mot_de_passe: str = Field(min_length=1, max_length=128)
    prenom: str = Field(min_length=1, max_length=60)
    nom: str = Field(min_length=1, max_length=60)
    role: Literal["convive", "parent"]
    statut_convive: StatutConvive | None = None
    conditions_acceptees: bool
    appareil: AppareilEntree = Field(default_factory=AppareilEntree)


class ConnexionEntree(BaseModel):
    """Corps de POST /auth/connexion."""

    identifiant: str = Field(min_length=1, max_length=254)
    mot_de_passe: str = Field(min_length=1, max_length=128)
    appareil: AppareilEntree = Field(default_factory=AppareilEntree)


class DemandeCodeEntree(BaseModel):
    """Corps de POST /auth/verification/envoyer."""

    identifiant: str = Field(min_length=3, max_length=254)
    canal: Canal
    usage: Literal["verification_compte"] = "verification_compte"


class ConfirmationEntree(BaseModel):
    """Corps de POST /auth/verification/confirmer."""

    identifiant: str = Field(min_length=3, max_length=254)
    canal: Canal
    usage: Literal["verification_compte"] = "verification_compte"
    code: str = Field(min_length=1, max_length=20)


class OubliEntree(BaseModel):
    """Corps de POST /auth/mot-de-passe/oublie."""

    identifiant: str = Field(min_length=3, max_length=254)
    canal: Canal


class ReinitialisationEntree(BaseModel):
    """Corps de POST /auth/mot-de-passe/reinitialiser."""

    identifiant: str = Field(min_length=3, max_length=254)
    canal: Canal | None = None
    code: str = Field(min_length=1, max_length=20)
    nouveau_mot_de_passe: str = Field(min_length=1, max_length=128)


class RafraichissementEntree(BaseModel):
    """Corps de POST /auth/rafraichir."""

    jeton_rafraichissement: str = Field(min_length=10, max_length=200)


class UtilisateurSortie(BaseModel):
    """Vue d'un compte rendue au client."""

    id: uuid.UUID
    prenom: str
    nom: str
    nom_complet: str
    role: str
    statut_convive: str | None
    langue: str
    email: str | None
    telephone: str | None
    verifie: bool
    canal_a_verifier: Canal


class SessionSortie(BaseModel):
    """Jetons d'une session ouverte et compte concerné."""

    jeton: str
    jeton_rafraichissement: str
    expire_dans: int
    utilisateur: UtilisateurSortie


class InscriptionSortie(SessionSortie):
    """Réponse de l'inscription : le compte est créé à vérifier et sa session est ouverte."""

    utilisateur_id: uuid.UUID
    etat: Literal["a_verifier"] = "a_verifier"
    canal: Canal


class JetonsSortie(BaseModel):
    """Réponse du rafraîchissement."""

    jeton: str
    jeton_rafraichissement: str
    expire_dans: int


class CodeEnvoyeSortie(BaseModel):
    """Réponse d'une demande de code ; `code_demo` seulement en livraison démo."""

    mode_livraison: Literal["demo", "reel"]
    expire_le: datetime
    code_demo: str | None = None
