"""Commande sans créneau, en trois services, gelée la veille ; frais GeniusPay ; plus d'anti-gaspillage.

Aligne la base sur docs/MODELE_DONNEES.md après les décisions de l'exploitant du 21 novembre :
- plus de créneaux ni d'heure limite du jour : le gel de la veille (heure_gel_commandes) est la seule limite ;
- un repas en trois services (entrée, résistance, sortie), commandé sur une période par lot ;
- le prix est celui du menu du jour pour un profil, plus d'éventuels suppléments ;
- les frais GeniusPay et le net de chaque paiement sont gardés ;
- l'anti-gaspillage est abandonné : la commande engage, il n'y a pas de restes à revendre.

Exception assumée à la règle « jamais de DROP » : les tables et colonnes retirées sont vides, aucune route
métier ne les ayant encore remplies. Décision de l'exploitant du 21 novembre.

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-21
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

INSTRUCTIONS = (
    # Réservations : plus de créneau, plus de plat unique ni de prix par plat.
    "ALTER TABLE reservations DROP COLUMN creneau_id",
    "ALTER TABLE reservations DROP COLUMN plat_id",
    "ALTER TABLE reservations DROP COLUMN prix_xof",
    "ALTER TABLE reservations DROP COLUMN cle_unique",
    "DROP TABLE creneaux",
    "ALTER TABLE menus DROP COLUMN heure_limite",
    """CREATE TABLE lots_reservation (
        id UUID DEFAULT gen_random_uuid() NOT NULL,
        convive_id UUID NOT NULL,
        portee TEXT NOT NULL,
        debut DATE NOT NULL,
        fin DATE NOT NULL,
        jours_reserves INTEGER NOT NULL,
        total_xof INTEGER NOT NULL,
        etat TEXT NOT NULL,
        cle_unique TEXT NOT NULL,
        modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        CONSTRAINT pk_lots_reservation PRIMARY KEY (id),
        CONSTRAINT fk_lots_reservation_convive_id_utilisateurs FOREIGN KEY (convive_id) REFERENCES utilisateurs (id),
        CONSTRAINT uq_lots_reservation_cle_unique UNIQUE (cle_unique),
        CONSTRAINT ck_lots_reservation_portee CHECK (portee in ('jour', 'semaine', 'mois')),
        CONSTRAINT ck_lots_reservation_etat CHECK (etat in ('confirme', 'partiellement_annule', 'annule')),
        CONSTRAINT ck_lots_reservation_periode_valide CHECK (fin >= debut),
        CONSTRAINT ck_lots_reservation_jours_positifs CHECK (jours_reserves > 0),
        CONSTRAINT ck_lots_reservation_total_positif CHECK (total_xof >= 0)
    )""",
    "CREATE INDEX ix_lots_reservation_convive_debut ON lots_reservation (convive_id, debut desc)",
    "ALTER TABLE reservations ADD COLUMN lot_id UUID NOT NULL",
    "ALTER TABLE reservations ADD CONSTRAINT fk_reservations_lot_id_lots_reservation "
    "FOREIGN KEY (lot_id) REFERENCES lots_reservation (id)",
    "ALTER TABLE reservations ADD COLUMN total_xof INTEGER NOT NULL",
    "ALTER TABLE reservations ADD CONSTRAINT ck_reservations_total_positif CHECK (total_xof >= 0)",
    "ALTER TABLE reservations DROP CONSTRAINT ck_reservations_etat",
    "ALTER TABLE reservations ADD CONSTRAINT ck_reservations_etat "
    "CHECK (etat in ('confirmee', 'servie', 'annulee', 'supprimee', 'non_reclamee'))",
    "CREATE INDEX ix_reservations_date_etat ON reservations (date_service, etat)",
    "CREATE INDEX ix_reservations_lot_id ON reservations (lot_id)",
    """CREATE TABLE lignes_reservation (
        id UUID DEFAULT gen_random_uuid() NOT NULL,
        reservation_id UUID NOT NULL,
        plat_id UUID NOT NULL,
        service TEXT NOT NULL,
        quantite INTEGER DEFAULT 1 NOT NULL,
        supplement_xof INTEGER DEFAULT 0 NOT NULL,
        cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
        CONSTRAINT pk_lignes_reservation PRIMARY KEY (id),
        CONSTRAINT fk_lignes_reservation_reservation_id_reservations FOREIGN KEY (reservation_id)
            REFERENCES reservations (id) ON DELETE CASCADE,
        CONSTRAINT fk_lignes_reservation_plat_id_plats FOREIGN KEY (plat_id) REFERENCES plats (id),
        CONSTRAINT ck_lignes_reservation_service CHECK (service in ('entree', 'resistance', 'sortie')),
        CONSTRAINT ck_lignes_reservation_quantite_positive CHECK (quantite > 0),
        CONSTRAINT ck_lignes_reservation_supplement_positif CHECK (supplement_xof >= 0)
    )""",
    "CREATE UNIQUE INDEX uq_lignes_reservation_reservation_plat ON lignes_reservation (reservation_id, plat_id)",
    "CREATE INDEX ix_lignes_reservation_plat_id ON lignes_reservation (plat_id)",
    "CREATE INDEX ix_lignes_reservation_plat_service ON lignes_reservation (plat_id, service)",
    # Plats : trois services et un prix de part supplémentaire.
    "ALTER TABLE plats DROP CONSTRAINT ck_plats_categorie",
    "ALTER TABLE plats ADD CONSTRAINT ck_plats_categorie CHECK (categorie in ('entree', 'resistance', 'sortie'))",
    "ALTER TABLE plats ADD COLUMN prix_supplement_xof INTEGER DEFAULT 0 NOT NULL",
    "ALTER TABLE plats ADD CONSTRAINT ck_plats_supplement_positif CHECK (prix_supplement_xof >= 0)",
    # Tarifs : prix du menu par profil, éventuellement propre à un jour ; NULLS NOT DISTINCT pour qu'un
    # tarif général (sans menu) ne puisse pas exister deux fois à la même date.
    "ALTER TABLE tarifs DROP COLUMN plat_id",
    "ALTER TABLE tarifs ADD COLUMN menu_id UUID",
    "ALTER TABLE tarifs ADD CONSTRAINT fk_tarifs_menu_id_menus FOREIGN KEY (menu_id) REFERENCES menus (id)",
    "CREATE UNIQUE INDEX uq_tarifs_profil_menu_debut ON tarifs (profil, menu_id, actif_du) NULLS NOT DISTINCT",
    "CREATE INDEX ix_tarifs_profil_debut ON tarifs (profil, actif_du desc)",
    # Argent : plus de motif anti-gaspillage, un supplément, un débit rattaché à un lot ; frais GeniusPay.
    "ALTER TABLE mouvements DROP CONSTRAINT ck_mouvements_motif",
    "ALTER TABLE mouvements ADD CONSTRAINT ck_mouvements_motif CHECK (motif in ('recharge', 'reservation', "
    "'supplement', 'annulation', 'remboursement', 'ajustement_admin'))",
    "ALTER TABLE mouvements DROP CONSTRAINT ck_mouvements_reference_type",
    "ALTER TABLE mouvements ADD CONSTRAINT ck_mouvements_reference_type "
    "CHECK (reference_type in ('lot_reservation', 'reservation', 'paiement', 'lien_paiement'))",
    "ALTER TABLE paiements ADD COLUMN frais_xof INTEGER DEFAULT 0 NOT NULL",
    "ALTER TABLE paiements ADD COLUMN net_xof INTEGER DEFAULT 0 NOT NULL",
    "ALTER TABLE paiements ADD CONSTRAINT ck_paiements_frais_positifs CHECK (frais_xof >= 0)",
    "ALTER TABLE paiements ADD CONSTRAINT ck_paiements_net_positif CHECK (net_xof >= 0)",
    # Notifications : rappel du gel à la place du rappel d'heure limite, plus d'anti-gaspillage.
    "ALTER TABLE notifications DROP CONSTRAINT ck_notifications_type",
    "ALTER TABLE notifications ADD CONSTRAINT ck_notifications_type CHECK (type in ('menu_publie', 'rappel_gel', "
    "'solde_bas', 'paiement_recu', 'repas_servi', 'message_admin'))",
    # Paramètres : les anciennes clés sortent, les nouvelles entrent.
    "DELETE FROM parametres WHERE cle IN ('heure_limite_defaut', 'delai_annulation_minutes', "
    "'capacite_creneau_defaut', 'remise_anti_gaspillage_pourcent')",
    """INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
        ('gel_jours_avant_service', '1', 'entier', 'Gel des commandes : jours avant le service (1 = la veille)',
         'Order freeze: days before service (1 = the day before)', 'service'),
        ('heure_gel_commandes', '"18:00"', 'heure', 'Heure de gel des commandes, le jour du gel',
         'Order freeze time, on the freeze day', 'service'),
        ('heure_ouverture_service', '"07:00"', 'heure', 'Ouverture du réfectoire (affichage)',
         'Dining hall opening time (display)', 'service'),
        ('heure_fermeture_service', '"20:00"', 'heure', 'Fermeture du réfectoire (affichage)',
         'Dining hall closing time (display)', 'service'),
        ('frais_geniuspay_pourcent', '3', 'entier', 'Frais GeniusPay par encaissement, en pourcentage (estimation)',
         'GeniusPay fee per payment, in percent (estimate)', 'paiement'),
        ('frais_geniuspay_fixe_xof', '0', 'entier', 'Frais GeniusPay fixes par encaissement',
         'GeniusPay fixed fee per payment', 'paiement'),
        ('frais_retrait_pourcent', '0', 'entier', 'Frais GeniusPay au retrait, en pourcentage',
         'GeniusPay withdrawal fee, in percent', 'paiement')
    ON CONFLICT (cle) DO NOTHING""",
)


def upgrade() -> None:
    """Applique le passage à la commande sans créneau."""
    for instruction in INSTRUCTIONS:
        op.execute(instruction)


def downgrade() -> None:
    """Refusé : l'ancien schéma des créneaux est abandonné."""
    raise NotImplementedError("Cette migration ne se défait pas.")
