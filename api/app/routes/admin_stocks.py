"""Routes /api/v1/admin/ingredients, /admin/stocks et /admin/rapports : stocks et rapports de la cantine.

Un mouvement de stock est écrit sous verrou de l'ingrédient, avec la quantité après ; une sortie qui ferait
passer sous zéro est refusée. Les rapports se calculent sur une période : CSV au format français
(séparateur point-virgule, dates jj/mm/aaaa) et PDF à mise en page fixe.
"""

import csv
import io
import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.dependances import Admin, adresse_client
from app.core.erreurs import ErreurApi
from app.db.session import SessionBase
from app.models import Ingredient, MouvementStock, Paiement
from app.services.journal import ecrire_journal
from app.services.tableau_bord import tableau_de_bord

routeur = APIRouter(prefix="/api/v1/admin", tags=["admin"])


class IngredientEntree(BaseModel):
    """Corps de POST /admin/ingredients."""

    nom: str = Field(min_length=2, max_length=80)
    unite: Literal["kg", "g", "l", "cl", "piece"]
    seuil_alerte: Decimal = Field(default=Decimal(0), ge=0, max_digits=12, decimal_places=3)


class MouvementEntree(BaseModel):
    """Corps de POST /admin/stocks/mouvement."""

    ingredient_id: uuid.UUID
    sens: Literal["entree", "sortie", "perte", "inventaire"]
    quantite: Decimal = Field(gt=0, max_digits=12, decimal_places=3)
    commentaire: str = Field(default="", max_length=300)


def _vue(ingredient: Ingredient) -> dict[str, Any]:
    return {
        "id": str(ingredient.id),
        "nom": ingredient.nom,
        "unite": ingredient.unite,
        "quantite_actuelle": str(ingredient.quantite_actuelle),
        "seuil_alerte": str(ingredient.seuil_alerte),
        "sous_le_seuil": ingredient.quantite_actuelle < ingredient.seuil_alerte,
    }


@routeur.get("/ingredients")
async def lister(admin: Admin, session: SessionBase) -> list[dict[str, Any]]:
    """Tous les ingrédients actifs, par nom."""
    lignes = await session.scalars(
        select(Ingredient).where(Ingredient.actif).order_by(func.lower(Ingredient.nom))
    )
    return [_vue(i) for i in lignes.all()]


@routeur.post("/ingredients", status_code=201)
async def creer(
    corps: IngredientEntree, admin: Admin, request: Request, session: SessionBase
) -> dict[str, Any]:
    """Ajoute un ingrédient au stock, à zéro."""
    ingredient = Ingredient(nom=corps.nom.strip(), unite=corps.unite, seuil_alerte=corps.seuil_alerte)
    session.add(ingredient)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise ErreurApi("conflit", 409) from exc
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "creation_ingredient",
        "ingredient",
        ingredient.id,
        None,
        {"nom": ingredient.nom},
        adresse_client(request),
    )
    return _vue(ingredient)


@routeur.post("/stocks/mouvement", status_code=201)
async def mouvement(
    corps: MouvementEntree, admin: Admin, request: Request, session: SessionBase
) -> dict[str, Any]:
    """Entrée, sortie, perte, ou inventaire (qui fixe la quantité comptée) ; jamais sous zéro."""
    ingredient = await session.get(Ingredient, corps.ingredient_id, with_for_update=True)
    if ingredient is None or not ingredient.actif:
        raise ErreurApi("introuvable", 404)
    avant = ingredient.quantite_actuelle
    if corps.sens == "entree":
        apres = avant + corps.quantite
    elif corps.sens == "inventaire":
        apres = corps.quantite
    else:
        apres = avant - corps.quantite
    if apres < 0:
        raise ErreurApi("stock_insuffisant", 409)
    ingredient.quantite_actuelle = apres
    session.add(
        MouvementStock(
            ingredient_id=ingredient.id,
            sens=corps.sens,
            quantite=corps.quantite,
            quantite_apres=apres,
            reference_type="achat" if corps.sens == "entree" else None,
            commentaire=corps.commentaire,
            cree_par=admin.utilisateur.id,
        )
    )
    ecrire_journal(
        session,
        admin.utilisateur.id,
        "mouvement_stock",
        "ingredient",
        ingredient.id,
        {"quantite": str(avant)},
        {"quantite": str(apres), "sens": corps.sens},
        adresse_client(request),
    )
    return _vue(ingredient) | {"seuil_franchi": avant >= ingredient.seuil_alerte > apres}


@routeur.get("/stocks/alertes")
async def alertes(admin: Admin, session: SessionBase) -> list[dict[str, Any]]:
    """Ingrédients passés sous leur seuil d'alerte."""
    lignes = await session.scalars(
        select(Ingredient).where(Ingredient.actif, Ingredient.quantite_actuelle < Ingredient.seuil_alerte)
    )
    return [_vue(i) for i in lignes.all()]


async def _donnees(session: SessionBase, du: date, au: date) -> dict[str, Any]:
    chiffres = await tableau_de_bord(session, du, au)
    debut = datetime.combine(du, datetime.min.time(), tzinfo=UTC)
    fin = datetime.combine(au + timedelta(days=1), datetime.min.time(), tzinfo=UTC)
    paiements = (
        await session.execute(
            select(
                func.count(),
                func.coalesce(func.sum(Paiement.montant_xof), 0),
                func.coalesce(func.sum(Paiement.frais_xof), 0),
            ).where(Paiement.etat == "reussi", Paiement.confirme_le >= debut, Paiement.confirme_le < fin)
        )
    ).one()
    return chiffres | {
        "recharges": int(paiements[0]),
        "recharges_xof": int(paiements[1]),
        "frais_xof": int(paiements[2]),
    }


def _date_fr(valeur: str) -> str:
    return date.fromisoformat(valeur).strftime("%d/%m/%Y")


def _csv(donnees: dict[str, Any]) -> bytes:
    tampon = io.StringIO()
    ecrivain = csv.writer(tampon, delimiter=";")
    ecrivain.writerow(["Période", f"{_date_fr(donnees['du'])} au {_date_fr(donnees['au'])}"])
    for libelle, cle in (
        ("Commandes", "commandes"),
        ("Servies", "servies"),
        ("Non réclamées", "non_reclamees"),
        ("Annulées", "annulees"),
        ("Recettes XOF", "recettes_xof"),
        ("Recharges", "recharges"),
        ("Recharges XOF", "recharges_xof"),
        ("Frais GeniusPay XOF", "frais_xof"),
    ):
        ecrivain.writerow([libelle, donnees[cle]])
    ecrivain.writerow([])
    ecrivain.writerow(["Date", "Commandes", "Recettes XOF"])
    for jour in donnees["courbe"]:
        ecrivain.writerow([_date_fr(jour["date"]), jour["commandes"], jour["recettes_xof"]])
    ecrivain.writerow([])
    ecrivain.writerow(["Plat", "Parts"])
    for plat in donnees["plats_les_plus_commandes"]:
        ecrivain.writerow([plat["nom_fr"], plat["parts"]])
    # Le BOM permet à Excel d'ouvrir les accents correctement.
    return ("﻿" + tampon.getvalue()).encode("utf-8")


def _pdf(donnees: dict[str, Any]) -> bytes:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas

    tampon = io.BytesIO()
    page = canvas.Canvas(tampon, pagesize=A4)
    _, hauteur = A4
    y = hauteur - 60
    page.setFont("Helvetica-Bold", 16)
    page.drawString(50, y, "CANTINE VATEL - Rapport")
    y -= 24
    page.setFont("Helvetica", 11)
    page.drawString(50, y, f"Période : {_date_fr(donnees['du'])} au {_date_fr(donnees['au'])}")
    y -= 30
    for libelle, cle in (
        ("Commandes", "commandes"),
        ("Servies", "servies"),
        ("Non réclamées", "non_reclamees"),
        ("Annulées", "annulees"),
        ("Recettes", "recettes_xof"),
        ("Recharges", "recharges_xof"),
        ("Frais GeniusPay", "frais_xof"),
    ):
        valeur = f"{donnees[cle]:,}".replace(",", " ")
        page.drawString(50, y, libelle)
        page.drawRightString(300, y, valeur + (" XOF" if cle.endswith("xof") else ""))
        y -= 18
    y -= 12
    page.setFont("Helvetica-Bold", 11)
    page.drawString(50, y, "Plats les plus commandés")
    page.setFont("Helvetica", 11)
    for plat in donnees["plats_les_plus_commandes"]:
        y -= 18
        page.drawString(60, y, plat["nom_fr"][:60])
        page.drawRightString(300, y, str(plat["parts"]))
    page.showPage()
    page.save()
    return tampon.getvalue()


@routeur.get("/rapports/{format_}")
async def rapport(
    format_: Literal["csv", "pdf"],
    admin: Admin,
    session: SessionBase,
    du: Annotated[date, Query()],
    au: Annotated[date, Query()],
) -> Response:
    """Rapport d'une période, en CSV ou en PDF."""
    if du > au or (au - du).days > 366:
        raise ErreurApi("validation", 422)
    donnees = await _donnees(session, du, au)
    nom = f"rapport-{du.isoformat()}-{au.isoformat()}.{format_}"
    if format_ == "csv":
        return Response(
            _csv(donnees),
            media_type="text/csv; charset=utf-8",
            headers={"Content-Disposition": f'attachment; filename="{nom}"'},
        )
    return Response(
        _pdf(donnees),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{nom}"'},
    )
