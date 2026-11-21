-- Schéma initial, partie 3 : tables signalements, tarifs, appareils, connexions_qr, creneaux, liens_paiement, menus_plats, mouvements.
-- Figé : une évolution passe par une nouvelle migration, jamais par ce fichier.
-- table signalements
CREATE TABLE signalements (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	auteur_id UUID NOT NULL,
	sujet TEXT NOT NULL,
	message TEXT NOT NULL,
	reference_type TEXT,
	reference_id UUID,
	etat TEXT DEFAULT 'ouvert' NOT NULL,
	reponse TEXT,
	traite_par UUID,
	traite_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_signalements PRIMARY KEY (id),
	CONSTRAINT ck_signalements_sujet CHECK (sujet in ('repas', 'paiement', 'compte', 'application', 'autre')),
	CONSTRAINT ck_signalements_reference_type CHECK (reference_type in ('reservation', 'paiement', 'avis')),
	CONSTRAINT ck_signalements_etat CHECK (etat in ('ouvert', 'en_cours', 'clos')),
	CONSTRAINT fk_signalements_auteur_id_utilisateurs FOREIGN KEY(auteur_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_signalements_traite_par_utilisateurs FOREIGN KEY(traite_par) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_signalements_auteur_id ON signalements (auteur_id);
CREATE INDEX ix_signalements_etat_cree_le ON signalements (etat, cree_le desc);
-- table tarifs
CREATE TABLE tarifs (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	plat_id UUID NOT NULL,
	profil TEXT NOT NULL,
	prix_xof INTEGER NOT NULL,
	actif_du TIMESTAMP WITH TIME ZONE NOT NULL,
	actif_au TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_tarifs PRIMARY KEY (id),
	CONSTRAINT ck_tarifs_profil CHECK (profil in ('eleve', 'etudiant', 'employe', 'visiteur')),
	CONSTRAINT ck_tarifs_prix_positif CHECK (prix_xof >= 0),
	CONSTRAINT ck_tarifs_periode_valide CHECK (actif_au is null or actif_au > actif_du),
	CONSTRAINT fk_tarifs_plat_id_plats FOREIGN KEY(plat_id) REFERENCES plats (id)
);
CREATE INDEX ix_tarifs_plat_profil ON tarifs (plat_id, profil);
CREATE UNIQUE INDEX uq_tarifs_plat_profil_debut ON tarifs (plat_id, profil, actif_du);
-- table appareils
CREATE TABLE appareils (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	utilisateur_id UUID NOT NULL,
	session_id UUID,
	jeton_fcm TEXT,
	plateforme TEXT NOT NULL,
	modele TEXT DEFAULT '' NOT NULL,
	version_app TEXT DEFAULT '' NOT NULL,
	secret_biometrique_hache TEXT,
	biometrie_active BOOLEAN DEFAULT false NOT NULL,
	derniere_vue_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_appareils PRIMARY KEY (id),
	CONSTRAINT ck_appareils_plateforme CHECK (plateforme in ('android', 'ios', 'web')),
	CONSTRAINT fk_appareils_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id) ON DELETE CASCADE,
	CONSTRAINT fk_appareils_session_id_sessions FOREIGN KEY(session_id) REFERENCES sessions (id),
	CONSTRAINT uq_appareils_jeton_fcm UNIQUE (jeton_fcm)
);
CREATE INDEX ix_appareils_utilisateur_id ON appareils (utilisateur_id);
-- table connexions_qr
CREATE TABLE connexions_qr (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	jeton_demande TEXT NOT NULL,
	etat TEXT NOT NULL,
	appareil_demandeur TEXT NOT NULL,
	adresse_ip_demandeur INET,
	utilisateur_id UUID,
	session_id UUID,
	lu_le TIMESTAMP WITH TIME ZONE,
	confirme_le TIMESTAMP WITH TIME ZONE,
	expire_le TIMESTAMP WITH TIME ZONE NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_connexions_qr PRIMARY KEY (id),
	CONSTRAINT ck_connexions_qr_etat CHECK (etat in ('en_attente', 'lu', 'confirme', 'refuse', 'expire')),
	CONSTRAINT uq_connexions_qr_jeton_demande UNIQUE (jeton_demande),
	CONSTRAINT fk_connexions_qr_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_connexions_qr_session_id_sessions FOREIGN KEY(session_id) REFERENCES sessions (id)
);
CREATE INDEX ix_connexions_qr_expire_le ON connexions_qr (expire_le);
-- table creneaux
CREATE TABLE creneaux (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	menu_id UUID NOT NULL,
	debut TIME WITHOUT TIME ZONE NOT NULL,
	fin TIME WITHOUT TIME ZONE NOT NULL,
	capacite INTEGER NOT NULL,
	actif BOOLEAN DEFAULT true NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_creneaux PRIMARY KEY (id),
	CONSTRAINT ck_creneaux_fin_apres_debut CHECK (fin > debut),
	CONSTRAINT ck_creneaux_capacite_positive CHECK (capacite >= 0),
	CONSTRAINT fk_creneaux_menu_id_menus FOREIGN KEY(menu_id) REFERENCES menus (id) ON DELETE CASCADE
);
CREATE INDEX ix_creneaux_menu_id ON creneaux (menu_id);
CREATE UNIQUE INDEX uq_creneaux_menu_debut ON creneaux (menu_id, debut);
-- table liens_paiement
CREATE TABLE liens_paiement (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	createur_id UUID NOT NULL,
	beneficiaire_id UUID NOT NULL,
	jeton_public TEXT NOT NULL,
	montant_xof INTEGER,
	message TEXT DEFAULT '' NOT NULL,
	etat TEXT NOT NULL,
	expire_le TIMESTAMP WITH TIME ZONE NOT NULL,
	paiement_id UUID,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_liens_paiement PRIMARY KEY (id),
	CONSTRAINT ck_liens_paiement_etat CHECK (etat in ('actif', 'paye', 'expire', 'annule')),
	CONSTRAINT ck_liens_paiement_montant_positif CHECK (montant_xof > 0),
	CONSTRAINT fk_liens_paiement_createur_id_utilisateurs FOREIGN KEY(createur_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_liens_paiement_beneficiaire_id_utilisateurs FOREIGN KEY(beneficiaire_id) REFERENCES utilisateurs (id),
	CONSTRAINT uq_liens_paiement_jeton_public UNIQUE (jeton_public),
	CONSTRAINT fk_liens_paiement_paiement_id_paiements FOREIGN KEY(paiement_id) REFERENCES paiements (id)
);
CREATE INDEX ix_liens_paiement_createur_cree_le ON liens_paiement (createur_id, cree_le desc);
CREATE INDEX ix_liens_paiement_etat ON liens_paiement (etat);
-- table menus_plats
CREATE TABLE menus_plats (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	menu_id UUID NOT NULL,
	plat_id UUID NOT NULL,
	quantite_prevue INTEGER NOT NULL,
	ordre INTEGER DEFAULT 0 NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_menus_plats PRIMARY KEY (id),
	CONSTRAINT ck_menus_plats_quantite_positive CHECK (quantite_prevue >= 0),
	CONSTRAINT fk_menus_plats_menu_id_menus FOREIGN KEY(menu_id) REFERENCES menus (id) ON DELETE CASCADE,
	CONSTRAINT fk_menus_plats_plat_id_plats FOREIGN KEY(plat_id) REFERENCES plats (id)
);
CREATE INDEX ix_menus_plats_menu_id ON menus_plats (menu_id);
CREATE UNIQUE INDEX uq_menus_plats_menu_plat ON menus_plats (menu_id, plat_id);
-- table mouvements
CREATE TABLE mouvements (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	porte_monnaie_id UUID NOT NULL,
	sens TEXT NOT NULL,
	montant_xof INTEGER NOT NULL,
	motif TEXT NOT NULL,
	reference_type TEXT,
	reference_id UUID,
	solde_apres_xof INTEGER NOT NULL,
	cle_unique TEXT NOT NULL,
	cree_par UUID,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_mouvements PRIMARY KEY (id),
	CONSTRAINT ck_mouvements_sens CHECK (sens in ('credit', 'debit')),
	CONSTRAINT ck_mouvements_motif CHECK (motif in ('recharge', 'reservation', 'annulation', 'remboursement', 'ajustement_admin', 'anti_gaspillage')),
	CONSTRAINT ck_mouvements_reference_type CHECK (reference_type in ('reservation', 'paiement', 'lien_paiement')),
	CONSTRAINT ck_mouvements_montant_positif CHECK (montant_xof > 0),
	CONSTRAINT ck_mouvements_solde_positif CHECK (solde_apres_xof >= 0),
	CONSTRAINT fk_mouvements_porte_monnaie_id_porte_monnaie FOREIGN KEY(porte_monnaie_id) REFERENCES porte_monnaie (id),
	CONSTRAINT uq_mouvements_cle_unique UNIQUE (cle_unique),
	CONSTRAINT fk_mouvements_cree_par_utilisateurs FOREIGN KEY(cree_par) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_mouvements_porte_monnaie_cree_le ON mouvements (porte_monnaie_id, cree_le desc);
CREATE INDEX ix_mouvements_reference ON mouvements (reference_type, reference_id);
