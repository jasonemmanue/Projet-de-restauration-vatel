"""Tests de la base : écriture validée puis relue, annulation sur erreur, schéma conforme aux modèles."""

import uuid

from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from fastapi import FastAPI
from sqlalchemy import select

from app.db.base import Base
from app.db.session import SessionBase
from app.models import Parametre
from tests.conftest import client_pour, exige_base


def _brancher_routes_ecriture(application: FastAPI) -> None:
    @application.post("/essai/ecrire/{cle}")
    async def _ecrire(cle: str, session: SessionBase) -> dict[str, str]:
        session.add(
            Parametre(
                cle=cle,
                valeur={"essai": True},
                type_valeur="objet",
                libelle_fr="Essai",
                libelle_en="Test",
                groupe="general",
            )
        )
        return {"cle": cle}

    @application.post("/essai/ecrire-puis-echouer/{cle}")
    async def _ecrire_puis_echouer(cle: str, session: SessionBase) -> None:
        session.add(
            Parametre(
                cle=cle,
                valeur=1,
                type_valeur="entier",
                libelle_fr="Essai",
                libelle_en="Test",
                groupe="general",
            )
        )
        await session.flush()
        raise RuntimeError("échec après écriture")


async def _relire(application: FastAPI, cle: str) -> Parametre | None:
    async with application.state.fabrique_sessions() as session:
        return (await session.execute(select(Parametre).where(Parametre.cle == cle))).scalar_one_or_none()


@exige_base
async def test_ecriture_relue_apres_validation(application_base: FastAPI) -> None:
    _brancher_routes_ecriture(application_base)
    cle = f"essai_{uuid.uuid4().hex}"
    async with client_pour(application_base) as client:
        reponse = await client.post(f"/essai/ecrire/{cle}")
    assert reponse.status_code == 200
    relu = await _relire(application_base, cle)
    assert relu is not None
    assert relu.valeur == {"essai": True}


@exige_base
async def test_ecriture_annulee_si_la_route_echoue(application_base: FastAPI) -> None:
    _brancher_routes_ecriture(application_base)
    cle = f"essai_{uuid.uuid4().hex}"
    async with client_pour(application_base) as client:
        reponse = await client.post(f"/essai/ecrire-puis-echouer/{cle}")
    assert reponse.status_code == 500
    assert await _relire(application_base, cle) is None


@exige_base
async def test_parametres_de_depart_presents(application_base: FastAPI) -> None:
    gel = await _relire(application_base, "heure_gel_commandes")
    assert gel is not None
    assert gel.valeur == "18:00"
    assert await _relire(application_base, "remise_anti_gaspillage_pourcent") is None


@exige_base
async def test_base_migree_conforme_aux_modeles(application_base: FastAPI) -> None:
    def _differences(connexion):
        contexte = MigrationContext.configure(connexion, opts={"compare_type": True})
        return compare_metadata(contexte, Base.metadata)

    async with application_base.state.moteur.connect() as connexion:
        differences = await connexion.run_sync(_differences)
    assert differences == []
