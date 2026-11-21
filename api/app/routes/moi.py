"""Route /api/v1/moi : le profil du compte connecté, lisible même avant la vérification.

Version minimale de M1 ; le profil complet (préférences, avatar, chiffres) arrive à l'étape A3c.
"""

from fastapi import APIRouter

from app.core.dependances import UtilisateurCourant
from app.routes.auth import vue_utilisateur
from app.schemas.comptes import UtilisateurSortie

routeur = APIRouter(prefix="/api/v1", tags=["profil"])


@routeur.get("/moi", response_model=UtilisateurSortie)
async def lire_moi(connecte: UtilisateurCourant) -> UtilisateurSortie:
    """Rend le compte du jeton présenté."""
    return vue_utilisateur(connecte.utilisateur)
