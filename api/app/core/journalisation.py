"""Journalisation de l'API : une ligne par événement sur la sortie standard, lue par Railway."""

import logging
import sys
import time

FORMAT = "%(asctime)s %(levelname)s %(name)s %(message)s"


def configurer_journaux(niveau: str) -> None:
    """Configure les journaux de l'application au niveau demandé, en UTC."""
    gestionnaire = logging.StreamHandler(sys.stdout)
    formateur = logging.Formatter(FORMAT, datefmt="%Y-%m-%dT%H:%M:%SZ")
    # Les heures restent en UTC partout, journaux compris.
    formateur.converter = time.gmtime
    gestionnaire.setFormatter(formateur)
    racine = logging.getLogger("vatel")
    racine.handlers = [gestionnaire]
    racine.setLevel(niveau.upper())
    racine.propagate = False
