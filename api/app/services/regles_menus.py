"""Règles métier des menus, en fonctions pures testées sans base.

Prix du menu du jour pour un profil, détection des allergènes, portions restantes, moment du gel d'un repas,
semaine de travail, et reconnaissance du type d'une photo par ses premiers octets.
"""

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta


@dataclass(frozen=True)
class TarifLu:
    """Tarif tel que lu en base, réduit à ce qu'il faut pour choisir le prix d'un jour."""

    profil: str
    prix_xof: int
    menu_id: object | None
    actif_du: datetime
    actif_au: datetime | None


def prix_du_jour(tarifs: Iterable[TarifLu], profil: str, menu_id: object, instant: datetime) -> int | None:
    """Prix du menu d'un jour pour un profil : le tarif propre à ce menu s'il existe, sinon le tarif général
    en vigueur à cet instant. Rend None quand aucun tarif ne s'applique : la commande doit alors être refusée.
    """
    en_vigueur = [
        t
        for t in tarifs
        if t.profil == profil and t.actif_du <= instant and (t.actif_au is None or instant < t.actif_au)
    ]
    propres = [t for t in en_vigueur if t.menu_id is not None and t.menu_id == menu_id]
    generaux = [t for t in en_vigueur if t.menu_id is None]
    choisis = propres or generaux
    if not choisis:
        return None
    # Le plus récent l'emporte : un nouveau tarif remplace l'ancien sans avoir à le clore.
    return max(choisis, key=lambda t: t.actif_du).prix_xof


def allergenes_en_commun(allergenes_plat: Sequence[str], allergies: Sequence[str]) -> list[str]:
    """Allergènes du plat que le convive a déclarés, dans l'ordre du plat."""
    declares = set(allergies)
    return [a for a in allergenes_plat if a in declares]


def portions_restantes(prevues: int, commandees: int) -> int:
    """Portions encore commandables ; jamais négatif, même si l'admin a baissé la prévision après coup."""
    return max(prevues - commandees, 0)


def moment_du_gel(date_service: date, jours_avant: int, heure_gel: time) -> datetime:
    """Instant UTC où la commande d'un jour se gèle : `jours_avant` jours avant, à l'heure de gel."""
    jour = date_service - timedelta(days=jours_avant)
    return datetime.combine(jour, heure_gel, tzinfo=UTC)


def lire_heure(valeur: str) -> time:
    """Lit une heure « HH:MM » rangée dans les paramètres."""
    heures, minutes = valeur.split(":", 1)
    return time(int(heures), int(minutes))


def lundi_de(jour: date) -> date:
    """Lundi de la semaine qui contient ce jour."""
    return jour - timedelta(days=jour.weekday())


def semaine(debut: date) -> list[date]:
    """Les sept jours qui commencent à `debut`."""
    return [debut + timedelta(days=i) for i in range(7)]


SIGNATURES_PHOTO = (
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
)


def type_de_photo(contenu: bytes) -> str | None:
    """Reconnaît une photo JPEG, PNG ou WebP par ses premiers octets, sans se fier à l'extension annoncée."""
    for signature, type_mime in SIGNATURES_PHOTO:
        if contenu.startswith(signature):
            return type_mime
    if len(contenu) >= 12 and contenu[:4] == b"RIFF" and contenu[8:12] == b"WEBP":
        return "image/webp"
    return None
