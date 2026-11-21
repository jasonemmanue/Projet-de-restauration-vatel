"""Comptes M1 : prénom, nom et consentement, statut « autre », numéros internationaux, compteur de tentatives,
mode de livraison au journal des vérifications, paramètres des limites et du rythme des menus.

Les contraintes check modifiées sont remplacées sous le même nom : PostgreSQL ne sait pas modifier une
contrainte check en place, d'où le retrait puis l'ajout dans la même transaction.

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    "ALTER TABLE utilisateurs ADD COLUMN prenom TEXT DEFAULT '' NOT NULL",
    "ALTER TABLE utilisateurs ADD COLUMN nom TEXT DEFAULT '' NOT NULL",
    "ALTER TABLE utilisateurs ADD COLUMN conditions_acceptees_le TIMESTAMP WITH TIME ZONE",
    "ALTER TABLE utilisateurs DROP CONSTRAINT ck_utilisateurs_statut_convive",
    "ALTER TABLE utilisateurs ADD CONSTRAINT ck_utilisateurs_statut_convive "
    "CHECK (statut_convive in ('eleve', 'etudiant', 'employe', 'autre'))",
    "ALTER TABLE utilisateurs DROP CONSTRAINT ck_utilisateurs_telephone_format",
    "ALTER TABLE utilisateurs ADD CONSTRAINT ck_utilisateurs_telephone_format "
    "CHECK (telephone ~ '^\\+[1-9][0-9]{7,14}$')",
    "ALTER TABLE tarifs DROP CONSTRAINT ck_tarifs_profil",
    "ALTER TABLE tarifs ADD CONSTRAINT ck_tarifs_profil "
    "CHECK (profil in ('eleve', 'etudiant', 'employe', 'autre', 'visiteur'))",
    "ALTER TABLE journal_verifications ADD COLUMN mode_livraison TEXT",
    "ALTER TABLE journal_verifications ADD CONSTRAINT ck_journal_verifications_mode_livraison "
    "CHECK (mode_livraison in ('demo', 'reel'))",
    "CREATE INDEX ix_journal_verifications_adresse_ip_cree_le ON journal_verifications (adresse_ip, cree_le)",
    """CREATE TABLE tentatives (
        cle TEXT NOT NULL,
        echecs INTEGER DEFAULT 0 NOT NULL,
        dernier_echec_le TIMESTAMP WITH TIME ZONE,
        bloque_jusqua TIMESTAMP WITH TIME ZONE,
        modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        CONSTRAINT pk_tentatives PRIMARY KEY (cle),
        CONSTRAINT ck_tentatives_echecs_positifs CHECK (echecs >= 0)
    )""",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('duree_code_email_minutes', '15', 'entier', 'Durée de validité d''un code par e-mail',
         'E-mail code validity duration', 'verification'),
        ('intervalle_codes_secondes', '60', 'entier', 'Délai minimal entre deux codes',
         'Minimum delay between two codes', 'verification'),
        ('codes_par_jour_max', '5', 'entier', 'Codes par identifiant et par jour',
         'Codes per identifier per day', 'verification'),
        ('demandes_codes_ip_jour_max', '200', 'entier', 'Demandes de code par adresse IP et par jour',
         'Code requests per IP address per day', 'verification'),
        ('blocage_codes_minutes', '15', 'entier', 'Blocage après trop de codes faux',
         'Lockout after too many wrong codes', 'verification'),
        ('connexion_essais_max', '5', 'entier', 'Échecs de connexion permis par compte',
         'Failed sign-ins allowed per account', 'general'),
        ('connexion_essais_ip_max', '30', 'entier', 'Échecs de connexion permis par adresse IP',
         'Failed sign-ins allowed per IP address', 'general'),
        ('connexion_blocage_minutes', '15', 'entier', 'Blocage après trop d''échecs de connexion',
         'Lockout after too many failed sign-ins', 'general'),
        ('jour_publication_menu', '4', 'entier', 'Jour habituel de publication du menu de la semaine (1 = lundi)',
         'Usual weekly menu publication day (1 = Monday)', 'service'),
        ('semaines_preparees_a_l_avance', '1', 'entier', 'Semaines de menus préparées à l''avance',
         'Weeks of menus prepared ahead', 'service'),
        ('portees_reservation', '["jour", "semaine", "mois"]', 'liste', 'Périodes de réservation proposées',
         'Booking periods offered', 'service'),
        ('services_obligatoires', '[]', 'liste', 'Services obligatoires dans un repas',
         'Mandatory courses in a meal', 'service')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Applique les changements des comptes M1."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : défaire retirerait des colonnes remplies, ce que le projet interdit."""
    raise NotImplementedError("Cette migration ne se défait pas.")
