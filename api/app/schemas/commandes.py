"""Schémas des commandes et du porte-monnaie."""

import uuid
from datetime import date, datetime
from typing import Generic, Literal, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class PlatCommandeEntree(BaseModel):
    """Un plat commandé un jour, avec sa quantité."""

    plat_id: uuid.UUID
    quantite: int = Field(default=1, ge=1, le=10)


class JourCommandeEntree(BaseModel):
    """Les plats commandés pour un jour : au moins un."""

    date_service: date
    plats: list[PlatCommandeEntree] = Field(max_length=20)


class CommandeEntree(BaseModel):
    """Corps de POST /reservations : une période et ses jours."""

    portee: Literal["jour", "semaine", "mois"]
    debut: date
    jours: list[JourCommandeEntree] = Field(min_length=1, max_length=31)


class LigneSortie(BaseModel):
    """Un plat d'une commande."""

    plat_id: uuid.UUID
    nom_fr: str
    nom_en: str
    service: str
    quantite: int
    supplement_xof: int


class ReservationSortie(BaseModel):
    """La commande d'un jour, avec son ticket."""

    id: uuid.UUID
    lot_id: uuid.UUID
    date_service: date
    etat: str
    total_xof: int
    code_ticket: str
    gele_le: datetime
    plats: list[LigneSortie]


class LotSortie(BaseModel):
    """Un lot de commandes sur une période."""

    id: uuid.UUID
    portee: str
    debut: date
    fin: date
    jours_reserves: int
    total_xof: int
    etat: str
    reservations: list[ReservationSortie] = Field(default_factory=list)


class AnnulationSortie(BaseModel):
    """Résultat d'une annulation : remboursée avant le gel, supprimée sans remboursement après."""

    etat: Literal["annulee", "supprimee"]
    rembourse_xof: int


class PorteMonnaieSortie(BaseModel):
    """Solde du porte-monnaie, lu depuis ses mouvements."""

    solde_xof: int
    devise: str
    gele: bool
    a_jour_le: datetime


class MouvementSortie(BaseModel):
    """Un mouvement du porte-monnaie."""

    id: uuid.UUID
    sens: str
    montant_xof: int
    motif: str
    solde_apres_xof: int
    cree_le: datetime


class Page(BaseModel, Generic[T]):
    """Page d'une liste, au format commun du contrat."""

    elements: list[T]
    page: int
    taille: int
    total: int


class AjustementEntree(BaseModel):
    """Corps de POST /admin/utilisateurs/{id}/ajustement."""

    sens: Literal["credit", "debit"]
    montant_xof: int = Field(ge=1, le=10_000_000)
    motif: str = Field(min_length=3, max_length=300)
