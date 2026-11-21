"""Schémas des menus : écriture par l'admin, lecture de la semaine par les convives."""

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field

from app.schemas.catalogue import Service


class PlatDuMenuEntree(BaseModel):
    """Plat proposé un jour, avec les portions prévues."""

    plat_id: uuid.UUID
    quantite_prevue: int = Field(ge=0, le=100_000)
    ordre: int = Field(default=0, ge=0, le=1000)


class MenuEntree(BaseModel):
    """Corps de création d'un menu : le gel suit les réglages, aucune heure n'est propre au menu."""

    date_service: date
    plats: list[PlatDuMenuEntree] = Field(default_factory=list, max_length=60)


class MenuModification(BaseModel):
    """Corps de modification d'un menu : la liste des plats remplace l'ancienne."""

    plats: list[PlatDuMenuEntree] = Field(max_length=60)


class DuplicationEntree(BaseModel):
    """Corps de copie d'un menu vers un autre jour."""

    vers_date: date


class DuplicationSemaineEntree(BaseModel):
    """Corps de copie d'une semaine entière : du lundi `de` vers le lundi `vers`."""

    de: date
    vers: date


class AnnulationEntree(BaseModel):
    """Corps d'annulation d'un menu."""

    motif: str = Field(min_length=1, max_length=300)


class PlatDuJourSortie(BaseModel):
    """Plat d'un menu, vu par un convive ou par l'admin."""

    plat_id: uuid.UUID
    nom_fr: str
    nom_en: str
    description_fr: str
    description_en: str
    allergenes: list[str]
    regimes: list[str]
    calories: int | None
    prix_supplement_xof: int
    image_url: str | None
    quantite_prevue: int
    portions_restantes: int
    allergenes_declares: list[str]
    contient_allergene: bool
    note_moyenne: float | None


class JourSortie(BaseModel):
    """Un jour de la semaine : son menu publié, ou rien."""

    date_service: date
    menu_id: uuid.UUID | None
    etat: str | None
    gele_le: datetime
    gele: bool
    prix_xof: int | None
    services: dict[Service, list[PlatDuJourSortie]]


class SemaineSortie(BaseModel):
    """Sept jours à partir du lundi demandé."""

    du: date
    jours: list[JourSortie]


class MenuAdminSortie(BaseModel):
    """Vue d'un menu pour l'admin."""

    id: uuid.UUID
    date_service: date
    etat: str
    publie_le: datetime | None
    plats: list[PlatDuMenuEntree]


class DuplicationSemaineSortie(BaseModel):
    """Résultat d'une copie de semaine : jours créés et jours déjà pris, laissés tels quels."""

    crees: list[date]
    ignores: list[date]
