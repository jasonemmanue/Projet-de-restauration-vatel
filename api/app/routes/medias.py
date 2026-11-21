"""Route publique /medias/{chemin} : sert les images du volume (photos des plats, images de démo).

Publique par choix : une photo de plat ne dit rien de personne et s'affiche sans jeton dans une balise
d'image. Seuls les types d'image connus sont servis, et jamais un chemin hors du dossier des médias.
"""

from fastapi import APIRouter, Request
from fastapi.responses import FileResponse

from app.core.erreurs import ErreurApi
from app.services.stockage import CheminInterditError, resoudre, type_par_extension

routeur = APIRouter(tags=["medias"])


@routeur.get("/medias/{chemin:path}")
async def servir(chemin: str, request: Request) -> FileResponse:
    """Une image du volume, mise en cache une journée."""
    try:
        fichier = resoudre(request.app.state.config.stockage_dossier, chemin)
    except CheminInterditError as exc:
        raise ErreurApi("introuvable", 404) from exc
    type_mime = type_par_extension(fichier)
    if type_mime is None or not fichier.is_file():
        raise ErreurApi("introuvable", 404)
    return FileResponse(fichier, media_type=type_mime, headers={"Cache-Control": "public, max-age=86400"})
