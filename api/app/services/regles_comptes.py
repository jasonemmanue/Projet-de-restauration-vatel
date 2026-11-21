"""Règles métier des comptes, en fonctions pures testées sans base.

Identifiants (numéro ou e-mail), force du mot de passe, génération et lecture des codes de vérification,
masquage des identifiants pour les journaux.
"""

import re
import secrets
from dataclasses import dataclass

CANAL_TELEPHONE = "telephone"
CANAL_EMAIL = "email"
INDICATIF_CI = "+225"
PREFIXES_MOBILES_CI = ("01", "05", "07")
ALPHABET_CODE_EMAIL = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
LONGUEUR_CODE = {CANAL_TELEPHONE: 6, CANAL_EMAIL: 5}

_EMAIL = re.compile(r"^[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$")
_INTERNATIONAL = re.compile(r"^\+[1-9][0-9]{7,14}$")
_SEPARATEURS = re.compile(r"[\s.\-()]")


class IdentifiantInvalideError(ValueError):
    """L'identifiant n'est ni un numéro valide ni une adresse e-mail valide."""


@dataclass(frozen=True)
class Identifiant:
    """Identifiant normalisé, avec le canal qui sert à le vérifier."""

    canal: str
    valeur: str


def normaliser_telephone(saisie: str) -> str:
    """Rend un numéro au format international ; un numéro ivoirien doit être un mobile en 01, 05 ou 07.

    Les autres indicatifs sont acceptés au format international. Un numéro à 10 chiffres sans indicatif est
    lu comme un numéro ivoirien.
    """
    brut = _SEPARATEURS.sub("", saisie.strip())
    if brut.startswith("00"):
        brut = "+" + brut[2:]
    if brut.isdigit() and len(brut) == 10:
        brut = INDICATIF_CI + brut
    if brut.startswith(INDICATIF_CI):
        national = brut[len(INDICATIF_CI) :]
        if len(national) == 10 and national.isdigit() and national.startswith(PREFIXES_MOBILES_CI):
            return brut
        raise IdentifiantInvalideError("numéro ivoirien invalide")
    if _INTERNATIONAL.match(brut):
        return brut
    raise IdentifiantInvalideError("numéro invalide")


def normaliser_email(saisie: str) -> str:
    """Rend l'adresse en minuscules, sans espaces autour, si elle est bien formée."""
    propre = saisie.strip().lower()
    if len(propre) > 254 or not _EMAIL.match(propre):
        raise IdentifiantInvalideError("e-mail invalide")
    return propre


def normaliser_identifiant(saisie: str, canal: str | None = None) -> Identifiant:
    """Normalise un identifiant ; sans canal donné, un « @ » désigne un e-mail, sinon c'est un numéro."""
    choisi = canal or (CANAL_EMAIL if "@" in saisie else CANAL_TELEPHONE)
    if choisi == CANAL_EMAIL:
        return Identifiant(CANAL_EMAIL, normaliser_email(saisie))
    if choisi == CANAL_TELEPHONE:
        return Identifiant(CANAL_TELEPHONE, normaliser_telephone(saisie))
    raise IdentifiantInvalideError("canal inconnu")


def _fragments_identifiant(identifiant: Identifiant) -> list[str]:
    if identifiant.canal == CANAL_EMAIL:
        local = identifiant.valeur.split("@", 1)[0]
        return [local] if len(local) >= 3 else []
    chiffres = identifiant.valeur.lstrip("+")
    # Les 8 derniers chiffres suffisent à reconnaître un numéro recopié dans le mot de passe.
    return [chiffres[-8:]]


def mot_de_passe_valide(mot_de_passe: str, identifiant: Identifiant | None = None) -> bool:
    """8 à 64 caractères, au moins une lettre et un chiffre, sans reprendre l'identifiant."""
    if not 8 <= len(mot_de_passe) <= 64:
        return False
    if not any(c.isalpha() for c in mot_de_passe) or not any(c.isdigit() for c in mot_de_passe):
        return False
    if identifiant is None:
        return True
    minuscule = mot_de_passe.lower()
    return not any(fragment in minuscule for fragment in _fragments_identifiant(identifiant))


def generer_code(canal: str) -> str:
    """Tire un code au hasard : 6 chiffres pour un numéro, 5 caractères sans ambiguïté pour un e-mail."""
    if canal == CANAL_TELEPHONE:
        return "".join(secrets.choice("0123456789") for _ in range(LONGUEUR_CODE[CANAL_TELEPHONE]))
    return "".join(secrets.choice(ALPHABET_CODE_EMAIL) for _ in range(LONGUEUR_CODE[CANAL_EMAIL]))


def normaliser_code(saisie: str) -> str:
    """Lit un code saisi sans tenir compte des minuscules ni des espaces."""
    return re.sub(r"\s", "", saisie).upper()


def masquer_identifiant(identifiant: Identifiant) -> str:
    """Masque un identifiant pour les journaux : +225 07 XX XX 12, j***@gmail.com."""
    if identifiant.canal == CANAL_EMAIL:
        local, domaine = identifiant.valeur.split("@", 1)
        return f"{local[:1]}***@{domaine}"
    valeur = identifiant.valeur
    if valeur.startswith(INDICATIF_CI):
        national = valeur[len(INDICATIF_CI) :]
        return f"{INDICATIF_CI} {national[:2]} XX XX {national[-2:]}"
    return f"{valeur[:4]} XX XX {valeur[-2:]}"
