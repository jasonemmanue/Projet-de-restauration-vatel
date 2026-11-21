-- Schéma initial, partie 4 : tables reservations, avis, file_scans.
-- Figé : une évolution passe par une nouvelle migration, jamais par ce fichier.
-- table reservations
CREATE TABLE reservations (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	convive_id UUID NOT NULL,
	menu_id UUID NOT NULL,
	creneau_id UUID NOT NULL,
	plat_id UUID NOT NULL,
	date_service DATE NOT NULL,
	prix_xof INTEGER NOT NULL,
	etat TEXT NOT NULL,
	code_ticket TEXT NOT NULL,
	servie_le TIMESTAMP WITH TIME ZONE,
	servie_par UUID,
	annulee_le TIMESTAMP WITH TIME ZONE,
	cle_unique TEXT NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_reservations PRIMARY KEY (id),
	CONSTRAINT ck_reservations_etat CHECK (etat in ('confirmee', 'servie', 'annulee', 'expiree')),
	CONSTRAINT ck_reservations_prix_positif CHECK (prix_xof >= 0),
	CONSTRAINT fk_reservations_convive_id_utilisateurs FOREIGN KEY(convive_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_reservations_menu_id_menus FOREIGN KEY(menu_id) REFERENCES menus (id),
	CONSTRAINT fk_reservations_creneau_id_creneaux FOREIGN KEY(creneau_id) REFERENCES creneaux (id),
	CONSTRAINT fk_reservations_plat_id_plats FOREIGN KEY(plat_id) REFERENCES plats (id),
	CONSTRAINT uq_reservations_code_ticket UNIQUE (code_ticket),
	CONSTRAINT fk_reservations_servie_par_utilisateurs FOREIGN KEY(servie_par) REFERENCES utilisateurs (id),
	CONSTRAINT uq_reservations_cle_unique UNIQUE (cle_unique)
);
CREATE INDEX ix_reservations_date_creneau ON reservations (date_service, creneau_id);
CREATE INDEX ix_reservations_menu_etat ON reservations (menu_id, etat);
CREATE UNIQUE INDEX uq_reservations_convive_jour_vivante ON reservations (convive_id, date_service) WHERE etat in ('confirmee', 'servie');
-- table avis
CREATE TABLE avis (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	auteur_id UUID NOT NULL,
	plat_id UUID NOT NULL,
	reservation_id UUID NOT NULL,
	note_gout INTEGER NOT NULL,
	note_quantite INTEGER NOT NULL,
	note_temperature INTEGER NOT NULL,
	note_attente INTEGER NOT NULL,
	commentaire TEXT DEFAULT '' NOT NULL,
	etat TEXT DEFAULT 'a_examiner' NOT NULL,
	motif_refus TEXT,
	reponse_cantine TEXT,
	repondu_par UUID,
	repondu_le TIMESTAMP WITH TIME ZONE,
	cle_unique TEXT NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_avis PRIMARY KEY (id),
	CONSTRAINT ck_avis_note_gout_entre_1_et_5 CHECK (note_gout between 1 and 5),
	CONSTRAINT ck_avis_note_quantite_entre_1_et_5 CHECK (note_quantite between 1 and 5),
	CONSTRAINT ck_avis_note_temperature_entre_1_et_5 CHECK (note_temperature between 1 and 5),
	CONSTRAINT ck_avis_note_attente_entre_1_et_5 CHECK (note_attente between 1 and 5),
	CONSTRAINT ck_avis_etat CHECK (etat in ('a_examiner', 'publie', 'refuse')),
	CONSTRAINT fk_avis_auteur_id_utilisateurs FOREIGN KEY(auteur_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_avis_plat_id_plats FOREIGN KEY(plat_id) REFERENCES plats (id),
	CONSTRAINT fk_avis_reservation_id_reservations FOREIGN KEY(reservation_id) REFERENCES reservations (id),
	CONSTRAINT fk_avis_repondu_par_utilisateurs FOREIGN KEY(repondu_par) REFERENCES utilisateurs (id),
	CONSTRAINT uq_avis_cle_unique UNIQUE (cle_unique)
);
CREATE INDEX ix_avis_plat_etat ON avis (plat_id, etat);
CREATE UNIQUE INDEX uq_avis_auteur_reservation ON avis (auteur_id, reservation_id);
-- table file_scans
CREATE TABLE file_scans (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	agent_id UUID NOT NULL,
	code_ticket TEXT NOT NULL,
	reservation_id UUID,
	scanne_le TIMESTAMP WITH TIME ZONE NOT NULL,
	recu_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cle_unique TEXT NOT NULL,
	resultat TEXT NOT NULL,
	detail TEXT DEFAULT '' NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_file_scans PRIMARY KEY (id),
	CONSTRAINT ck_file_scans_resultat CHECK (resultat in ('accepte', 'deja_servi', 'inconnu', 'mauvais_jour', 'annule')),
	CONSTRAINT fk_file_scans_agent_id_utilisateurs FOREIGN KEY(agent_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_file_scans_reservation_id_reservations FOREIGN KEY(reservation_id) REFERENCES reservations (id),
	CONSTRAINT uq_file_scans_cle_unique UNIQUE (cle_unique)
);
CREATE INDEX ix_file_scans_agent_recu_le ON file_scans (agent_id, recu_le desc);
CREATE INDEX ix_file_scans_code_ticket ON file_scans (code_ticket);
ALTER TABLE paiements ADD CONSTRAINT fk_paiements_lien_paiement_id_liens_paiement FOREIGN KEY(lien_paiement_id) REFERENCES liens_paiement (id);
