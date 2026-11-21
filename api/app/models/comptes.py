"""Modèles des comptes : utilisateurs, sessions, codes et journal de vérification, connexions par QR."""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Integer, Text, func, text
from sqlalchemy.dialects.postgresql import ARRAY, INET, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import DateTime

from app.db.base import AvecCreation, AvecModification, Base, choix, cle_primaire

UTILISATEUR_FK = "utilisateurs.id"
PLATEFORMES = ("android", "ios", "web")
CANAUX = ("telephone", "email")
ROLES = ("convive", "parent", "agent", "admin")
STATUTS_CONVIVE = ("eleve", "etudiant", "employe", "autre")


class Utilisateur(AvecModification, Base):
    """Compte de tout rôle. Propriétaire : A3."""

    __tablename__ = "utilisateurs"
    __table_args__ = (
        choix("role", *ROLES),
        choix("statut_convive", *STATUTS_CONVIVE),
        choix("langue", "fr", "en"),
        CheckConstraint("telephone is not null or email is not null", name="identifiant_present"),
        CheckConstraint("(role = 'convive') = (statut_convive is not null)", name="statut_selon_role"),
        CheckConstraint("telephone ~ '^\\+[1-9][0-9]{7,14}$'", name="telephone_format"),
        CheckConstraint("seuil_alerte_solde >= 0", name="seuil_positif"),
        CheckConstraint(
            "allergies <@ array['arachide', 'poisson', 'crustaces', 'gluten', 'lait', 'oeuf', 'soja', "
            "'sesame', 'fruits_a_coque', 'celeri', 'moutarde']::text[]",
            name="allergies",
        ),
        Index("uq_utilisateurs_email_minuscule", func.lower(text("email")), unique=True),
        Index("ix_utilisateurs_role", "role"),
        Index("ix_utilisateurs_statut_convive", "statut_convive"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    nom_complet: Mapped[str] = mapped_column(Text, nullable=False)
    prenom: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    nom: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("''"))
    conditions_acceptees_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    telephone: Mapped[str | None] = mapped_column(Text, unique=True)
    email: Mapped[str | None] = mapped_column(Text)
    mot_de_passe_hache: Mapped[str] = mapped_column(Text, nullable=False)
    role: Mapped[str] = mapped_column(Text, nullable=False)
    statut_convive: Mapped[str | None] = mapped_column(Text)
    langue: Mapped[str] = mapped_column(Text, nullable=False, server_default=text("'fr'"))
    pin_hache: Mapped[str | None] = mapped_column(Text)
    pin_essais: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    pin_bloque_jusqua: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    email_verifie_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    telephone_verifie_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    google_id: Mapped[str | None] = mapped_column(Text, unique=True)
    apple_id: Mapped[str | None] = mapped_column(Text, unique=True)
    profil_complet: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    allergies: Mapped[list[str]] = mapped_column(
        ARRAY(Text), nullable=False, server_default=text("'{}'::text[]")
    )
    seuil_alerte_solde: Mapped[int | None] = mapped_column(Integer)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    supprime_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class SessionAppareil(AvecModification, Base):
    """Session ouverte sur un appareil, pour la déconnexion à distance. Propriétaire : A3."""

    __tablename__ = "sessions"
    __table_args__ = (
        choix("plateforme", *PLATEFORMES),
        Index("ix_sessions_utilisateur_id", "utilisateur_id"),
        Index("ix_sessions_expire_le", "expire_le"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    utilisateur_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK, ondelete="CASCADE"), nullable=False
    )
    jeton_rafraichissement_hache: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    appareil_nom: Mapped[str] = mapped_column(Text, nullable=False)
    plateforme: Mapped[str] = mapped_column(Text, nullable=False)
    adresse_ip: Mapped[str | None] = mapped_column(INET)
    derniere_activite: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    expire_le: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoquee_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class CodeVerification(AvecModification, Base):
    """Code de vérification haché, pour un numéro ou un e-mail. Propriétaire : A3."""

    __tablename__ = "codes_verification"
    __table_args__ = (
        choix("canal", *CANAUX),
        choix("origine", "api", "admin", "parent"),
        choix(
            "usage",
            "verification_compte",
            "reinitialisation_mot_de_passe",
            "secours",
            "changement_identifiant",
        ),
        choix("mode_livraison", "demo", "reel"),
        Index("ix_codes_verification_identifiant_canal_usage", "identifiant_vise", "canal", "usage"),
        Index("ix_codes_verification_expire_le", "expire_le"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    utilisateur_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    identifiant_vise: Mapped[str] = mapped_column(Text, nullable=False)
    canal: Mapped[str] = mapped_column(Text, nullable=False)
    code_hache: Mapped[str] = mapped_column(Text, nullable=False)
    origine: Mapped[str] = mapped_column(Text, nullable=False)
    usage: Mapped[str] = mapped_column(Text, nullable=False)
    mode_livraison: Mapped[str] = mapped_column(Text, nullable=False)
    essais: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    essais_max: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("5"))
    expire_le: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    utilise_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class JournalVerification(AvecCreation, Base):
    """Trace des vérifications, sans identifiant en clair. Ajout seul. Propriétaire : A3."""

    __tablename__ = "journal_verifications"
    __table_args__ = (
        choix("canal", *CANAUX),
        choix("etape", "demande", "envoye", "verifie", "echec"),
        choix("raison", "code_faux", "expire", "trop_essais", "envoi_impossible"),
        choix("mode_livraison", "demo", "reel"),
        Index("ix_journal_verifications_adresse_ip_cree_le", "adresse_ip", "cree_le"),
        Index("ix_journal_verifications_cree_le", text("cree_le desc")),
        Index("ix_journal_verifications_canal_etape", "canal", "etape"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    identifiant_masque: Mapped[str] = mapped_column(Text, nullable=False)
    canal: Mapped[str] = mapped_column(Text, nullable=False)
    etape: Mapped[str] = mapped_column(Text, nullable=False)
    raison: Mapped[str | None] = mapped_column(Text)
    mode_livraison: Mapped[str | None] = mapped_column(Text)
    adresse_ip: Mapped[str | None] = mapped_column(INET)


class ConnexionQr(AvecModification, Base):
    """Demande de connexion d'un autre appareil par QR code. Propriétaire : A3b."""

    __tablename__ = "connexions_qr"
    __table_args__ = (
        choix("etat", "en_attente", "lu", "confirme", "refuse", "expire"),
        Index("ix_connexions_qr_expire_le", "expire_le"),
    )

    id: Mapped[uuid.UUID] = cle_primaire()
    jeton_demande: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    etat: Mapped[str] = mapped_column(Text, nullable=False)
    appareil_demandeur: Mapped[str] = mapped_column(Text, nullable=False)
    adresse_ip_demandeur: Mapped[str | None] = mapped_column(INET)
    utilisateur_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey(UTILISATEUR_FK))
    session_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("sessions.id"))
    lu_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    confirme_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    expire_le: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Tentative(AvecModification, Base):
    """Compteur d'échecs qui mène à un blocage temporaire : connexion par compte ou par adresse IP, codes
    faux par identifiant. La clé dit ce qui est compté, par exemple « connexion:compte:<identifiant> »."""

    __tablename__ = "tentatives"
    __table_args__ = (CheckConstraint("echecs >= 0", name="echecs_positifs"),)

    cle: Mapped[str] = mapped_column(Text, primary_key=True)
    echecs: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    dernier_echec_le: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    bloque_jusqua: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
