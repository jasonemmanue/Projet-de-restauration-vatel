"""Configuration technique de l'API, lue dans les variables d'environnement.

Les réglages métier (heure limite, seuils, modes) vivent dans la table `parametres`, pas ici.
L'application refuse de démarrer si une variable obligatoire manque ou garde une valeur d'exemple :
mieux vaut un déploiement qui échoue qu'une API qui tourne avec un secret connu de tous.
"""

from functools import lru_cache
from typing import Annotated

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

# Fragments qu'on retrouve dans les modèles de fichiers .env et les tutoriels.
FRAGMENTS_EXEMPLE = (
    "changeme",
    "change-me",
    "change_me",
    "remplacer",
    "a_definir",
    "exemple",
    "example",
    "votre",
    "your",
    "xxx",
    "<",
    ">",
    "user:password@",
    "@host:",
)

PREFIXES_POSTGRES = ("postgres://", "postgresql://")
PREFIXE_ASYNCPG = "postgresql+asyncpg://"


def est_valeur_exemple(valeur: str) -> bool:
    """Dit si une valeur est vide ou ressemble à une valeur d'exemple laissée telle quelle."""
    propre = valeur.strip().lower()
    if not propre:
        return True
    return any(fragment in propre for fragment in FRAGMENTS_EXEMPLE)


def normaliser_url_base(url: str) -> str:
    """Convertit l'URL fournie par Railway (postgres:// ou postgresql://) vers le pilote asyncpg."""
    propre = url.strip()
    for prefixe in PREFIXES_POSTGRES:
        if propre.startswith(prefixe):
            return PREFIXE_ASYNCPG + propre[len(prefixe) :]
    if propre.startswith(PREFIXE_ASYNCPG):
        return propre
    raise ValueError("DATABASE_URL doit désigner une base PostgreSQL")


def raccourcir_commit(sha: str | None) -> str:
    """Rend les 7 premiers caractères du commit déployé, ou « local » s'il est inconnu."""
    propre = (sha or "").strip()
    return propre[:7] if propre else "local"


def lire_origines(valeur: str | list[str]) -> list[str]:
    """Découpe la liste CORS séparée par des virgules et refuse le joker et les origines mal formées."""
    morceaux = valeur if isinstance(valeur, list) else valeur.split(",")
    origines = [m.strip().rstrip("/") for m in morceaux if m.strip()]
    if not origines:
        raise ValueError("CORS_ORIGINS est vide")
    for origine in origines:
        if origine == "*" or "*" in origine:
            raise ValueError("CORS_ORIGINS n'accepte pas de joker")
        if not origine.startswith(("https://", "http://")):
            raise ValueError("Chaque origine CORS commence par http:// ou https://")
    return origines


class Configuration(BaseSettings):
    """Ensemble des variables d'environnement lues au démarrage de l'API."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    # Obligatoires : aucun défaut, le démarrage échoue sans elles.
    database_url: str = Field(validation_alias="DATABASE_URL")
    secret_key: str = Field(validation_alias=AliasChoices("SECRET_KEY", "JWT_SECRET"), min_length=32)
    admin_actions_password: str = Field(validation_alias="ADMIN_ACTIONS_PASSWORD", min_length=12)
    cors_origins: Annotated[list[str], NoDecode] = Field(
        validation_alias=AliasChoices("CORS_ORIGINS", "CORS_ORIGINES")
    )

    # Facultatives, avec un défaut technique sûr.
    app_env: str = Field(default="local", validation_alias="APP_ENV")
    commit_brut: str | None = Field(
        default=None, validation_alias=AliasChoices("RAILWAY_GIT_COMMIT_SHA", "APP_COMMIT")
    )
    docs_enabled: bool = Field(default=True, validation_alias="DOCS_ENABLED")
    log_niveau: str = Field(default="info", validation_alias="LOG_NIVEAU")
    pool_taille: int = Field(default=5, ge=1, le=50, validation_alias="DATABASE_POOL_TAILLE")
    lock_timeout_ms: int = Field(default=5000, ge=100, validation_alias="DB_LOCK_TIMEOUT_MS")
    statement_timeout_ms: int = Field(default=15000, ge=1000, validation_alias="DB_STATEMENT_TIMEOUT_MS")
    taille_requete_max_ko: int = Field(default=1024, ge=1, validation_alias="TAILLE_REQUETE_MAX_KO")
    limite_debit_defaut: str = Field(default="120/minute", validation_alias="LIMITE_DEBIT_DEFAUT")
    proxies_de_confiance: int = Field(default=1, ge=0, le=5, validation_alias="PROXIES_DE_CONFIANCE")

    @field_validator("database_url")
    @classmethod
    def _valider_url(cls, valeur: str) -> str:
        if est_valeur_exemple(valeur):
            raise ValueError("DATABASE_URL garde une valeur d'exemple")
        return normaliser_url_base(valeur)

    @field_validator("secret_key", "admin_actions_password")
    @classmethod
    def _valider_secret(cls, valeur: str) -> str:
        if est_valeur_exemple(valeur):
            raise ValueError("un secret garde une valeur d'exemple")
        return valeur

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _valider_origines(cls, valeur: str | list[str]) -> list[str]:
        return lire_origines(valeur)

    @field_validator("log_niveau")
    @classmethod
    def _valider_niveau(cls, valeur: str) -> str:
        niveau = valeur.strip().lower()
        if niveau not in {"debug", "info", "warning", "error"}:
            raise ValueError("LOG_NIVEAU vaut debug, info, warning ou error")
        return niveau

    @property
    def commit(self) -> str:
        """Commit déployé sur 7 caractères, « local » hors de Railway."""
        return raccourcir_commit(self.commit_brut)

    @property
    def taille_requete_max_octets(self) -> int:
        """Taille maximale d'un corps de requête, en octets."""
        return self.taille_requete_max_ko * 1024


@lru_cache
def lire_configuration() -> Configuration:
    """Lit la configuration une seule fois par processus."""
    return Configuration()  # type: ignore[call-arg]
