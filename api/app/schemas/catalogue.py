"""Schémas du catalogue : plats et tarifs, côté admin et côté convive."""

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

Service = Literal["entree", "resistance", "sortie"]
# Mêmes listes que ALLERGENES et REGIMES du modèle ; un test vérifie qu'elles restent égales.
Allergene = Literal[
    "arachide",
    "poisson",
    "crustaces",
    "gluten",
    "lait",
    "oeuf",
    "soja",
    "sesame",
    "fruits_a_coque",
    "celeri",
    "moutarde",
]
Regime = Literal["sans_porc", "sans_gluten", "vegetarien", "halal"]
Profil = Literal["eleve", "etudiant", "employe", "autre", "visiteur"]


class PlatEntree(BaseModel):
    """Corps de création d'un plat."""

    nom_fr: str = Field(min_length=1, max_length=120)
    nom_en: str = Field(min_length=1, max_length=120)
    description_fr: str = Field(default="", max_length=1000)
    description_en: str = Field(default="", max_length=1000)
    categorie: Service
    allergenes: list[Allergene] = Field(default_factory=list)
    regimes: list[Regime] = Field(default_factory=list)
    calories: int | None = Field(default=None, ge=0, le=5000)
    prix_supplement_xof: int = Field(default=0, ge=0, le=100000)


class PlatModification(BaseModel):
    """Corps de modification d'un plat : seuls les champs envoyés changent."""

    nom_fr: str | None = Field(default=None, min_length=1, max_length=120)
    nom_en: str | None = Field(default=None, min_length=1, max_length=120)
    description_fr: str | None = Field(default=None, max_length=1000)
    description_en: str | None = Field(default=None, max_length=1000)
    categorie: Service | None = None
    allergenes: list[Allergene] | None = None
    regimes: list[Regime] | None = None
    calories: int | None = Field(default=None, ge=0, le=5000)
    prix_supplement_xof: int | None = Field(default=None, ge=0, le=100000)
    actif: bool | None = None


class PlatSortie(BaseModel):
    """Vue d'un plat."""

    id: uuid.UUID
    nom_fr: str
    nom_en: str
    description_fr: str
    description_en: str
    categorie: Service
    allergenes: list[str]
    regimes: list[str]
    calories: int | None
    prix_supplement_xof: int
    image_url: str | None
    actif: bool


class TarifEntree(BaseModel):
    """Corps de création d'un tarif : prix du menu d'un profil, général ou propre à un menu."""

    profil: Profil
    prix_xof: int = Field(ge=0, le=1_000_000)
    actif_du: datetime
    menu_id: uuid.UUID | None = None


class TarifSortie(BaseModel):
    """Vue d'un tarif."""

    id: uuid.UUID
    profil: str
    prix_xof: int
    actif_du: datetime
    actif_au: datetime | None
    menu_id: uuid.UUID | None
