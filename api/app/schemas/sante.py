"""Schéma de la réponse de santé."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel


class EtatSante(BaseModel):
    """État de l'API et de sa base, avec la version et le commit déployés."""

    etat: Literal["ok", "degrade"]
    version: str
    commit: str
    base: Literal["ok", "indisponible"]
    heure: datetime
