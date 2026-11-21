-- Schéma initial, partie 2 : tables liens_parent_enfant, menus, mouvements_stock, notifications, paiements, parametres, porte_monnaie, sessions.
-- Figé : une évolution passe par une nouvelle migration, jamais par ce fichier.
-- table liens_parent_enfant
CREATE TABLE liens_parent_enfant (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	parent_id UUID NOT NULL,
	enfant_id UUID NOT NULL,
	code_liaison TEXT NOT NULL,
	etat TEXT NOT NULL,
	cree_par UUID NOT NULL,
	valide_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_liens_parent_enfant PRIMARY KEY (id),
	CONSTRAINT ck_liens_parent_enfant_etat CHECK (etat in ('en_attente', 'actif', 'revoque')),
	CONSTRAINT ck_liens_parent_enfant_code_huit_caracteres CHECK (char_length(code_liaison) = 8),
	CONSTRAINT ck_liens_parent_enfant_parent_different CHECK (parent_id <> enfant_id),
	CONSTRAINT fk_liens_parent_enfant_parent_id_utilisateurs FOREIGN KEY(parent_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_liens_parent_enfant_enfant_id_utilisateurs FOREIGN KEY(enfant_id) REFERENCES utilisateurs (id),
	CONSTRAINT uq_liens_parent_enfant_code_liaison UNIQUE (code_liaison),
	CONSTRAINT fk_liens_parent_enfant_cree_par_utilisateurs FOREIGN KEY(cree_par) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_liens_parent_enfant_enfant_id ON liens_parent_enfant (enfant_id);
CREATE UNIQUE INDEX uq_liens_parent_enfant_parent_enfant ON liens_parent_enfant (parent_id, enfant_id);
-- table menus
CREATE TABLE menus (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	date_service DATE NOT NULL,
	etat TEXT NOT NULL,
	heure_limite TIME WITHOUT TIME ZONE NOT NULL,
	publie_le TIMESTAMP WITH TIME ZONE,
	publie_par UUID,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_menus PRIMARY KEY (id),
	CONSTRAINT ck_menus_etat CHECK (etat in ('brouillon', 'publie', 'annule')),
	CONSTRAINT uq_menus_date_service UNIQUE (date_service),
	CONSTRAINT fk_menus_publie_par_utilisateurs FOREIGN KEY(publie_par) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_menus_etat ON menus (etat);
-- table mouvements_stock
CREATE TABLE mouvements_stock (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	ingredient_id UUID NOT NULL,
	sens TEXT NOT NULL,
	quantite NUMERIC(12, 3) NOT NULL,
	quantite_apres NUMERIC(12, 3) NOT NULL,
	reference_type TEXT,
	reference_id UUID,
	commentaire TEXT DEFAULT '' NOT NULL,
	cree_par UUID NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_mouvements_stock PRIMARY KEY (id),
	CONSTRAINT ck_mouvements_stock_sens CHECK (sens in ('entree', 'sortie', 'perte', 'inventaire')),
	CONSTRAINT ck_mouvements_stock_reference_type CHECK (reference_type in ('reservation', 'service', 'achat')),
	CONSTRAINT ck_mouvements_stock_quantite_positive CHECK (quantite > 0),
	CONSTRAINT ck_mouvements_stock_quantite_apres_positive CHECK (quantite_apres >= 0),
	CONSTRAINT fk_mouvements_stock_ingredient_id_ingredients FOREIGN KEY(ingredient_id) REFERENCES ingredients (id),
	CONSTRAINT fk_mouvements_stock_cree_par_utilisateurs FOREIGN KEY(cree_par) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_mouvements_stock_ingredient_cree_le ON mouvements_stock (ingredient_id, cree_le desc);
-- table notifications
CREATE TABLE notifications (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	destinataire_id UUID NOT NULL,
	type TEXT NOT NULL,
	titre TEXT NOT NULL,
	corps TEXT NOT NULL,
	donnees JSONB DEFAULT '{}'::jsonb NOT NULL,
	lue_le TIMESTAMP WITH TIME ZONE,
	envoi_push TEXT DEFAULT 'non_demande' NOT NULL,
	envoye_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_notifications PRIMARY KEY (id),
	CONSTRAINT ck_notifications_type CHECK (type in ('menu_publie', 'rappel_limite', 'solde_bas', 'paiement_recu', 'repas_servi', 'anti_gaspillage', 'message_admin')),
	CONSTRAINT ck_notifications_envoi_push CHECK (envoi_push in ('non_demande', 'en_attente', 'envoye', 'echoue')),
	CONSTRAINT fk_notifications_destinataire_id_utilisateurs FOREIGN KEY(destinataire_id) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_notifications_destinataire_cree_le ON notifications (destinataire_id, cree_le desc);
CREATE INDEX ix_notifications_non_lues ON notifications (destinataire_id) WHERE lue_le is null;
-- table paiements
CREATE TABLE paiements (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	payeur_id UUID,
	beneficiaire_id UUID NOT NULL,
	lien_paiement_id UUID,
	montant_xof INTEGER NOT NULL,
	operateur TEXT NOT NULL,
	telephone_payeur TEXT NOT NULL,
	mode TEXT NOT NULL,
	etat TEXT NOT NULL,
	reference_geniuspay TEXT,
	cle_geste TEXT NOT NULL,
	charge_utile_webhook JSONB,
	motif_echec TEXT,
	confirme_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_paiements PRIMARY KEY (id),
	CONSTRAINT ck_paiements_operateur CHECK (operateur in ('orange', 'mtn', 'moov', 'wave')),
	CONSTRAINT ck_paiements_mode CHECK (mode in ('test', 'reel')),
	CONSTRAINT ck_paiements_etat CHECK (etat in ('initie', 'en_attente', 'reussi', 'echoue', 'expire')),
	CONSTRAINT ck_paiements_montant_positif CHECK (montant_xof > 0),
	CONSTRAINT fk_paiements_payeur_id_utilisateurs FOREIGN KEY(payeur_id) REFERENCES utilisateurs (id),
	CONSTRAINT fk_paiements_beneficiaire_id_utilisateurs FOREIGN KEY(beneficiaire_id) REFERENCES utilisateurs (id),
	CONSTRAINT uq_paiements_reference_geniuspay UNIQUE (reference_geniuspay),
	CONSTRAINT uq_paiements_cle_geste UNIQUE (cle_geste)
);
CREATE INDEX ix_paiements_beneficiaire_cree_le ON paiements (beneficiaire_id, cree_le desc);
CREATE INDEX ix_paiements_etat ON paiements (etat);
CREATE INDEX ix_paiements_mode ON paiements (mode);
-- table parametres
CREATE TABLE parametres (
	cle TEXT NOT NULL,
	valeur JSONB NOT NULL,
	type_valeur TEXT NOT NULL,
	libelle_fr TEXT NOT NULL,
	libelle_en TEXT NOT NULL,
	groupe TEXT NOT NULL,
	modifiable BOOLEAN DEFAULT true NOT NULL,
	modifie_par UUID,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_parametres PRIMARY KEY (cle),
	CONSTRAINT ck_parametres_type_valeur CHECK (type_valeur in ('texte', 'entier', 'booleen', 'heure', 'liste', 'objet')),
	CONSTRAINT ck_parametres_groupe CHECK (groupe in ('service', 'paiement', 'verification', 'notification', 'general')),
	CONSTRAINT fk_parametres_modifie_par_utilisateurs FOREIGN KEY(modifie_par) REFERENCES utilisateurs (id)
);
-- table porte_monnaie
CREATE TABLE porte_monnaie (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	utilisateur_id UUID NOT NULL,
	devise TEXT DEFAULT 'XOF' NOT NULL,
	gele BOOLEAN DEFAULT false NOT NULL,
	solde_cache_xof INTEGER DEFAULT 0 NOT NULL,
	recalcule_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_porte_monnaie PRIMARY KEY (id),
	CONSTRAINT ck_porte_monnaie_devise_xof CHECK (devise = 'XOF'),
	CONSTRAINT uq_porte_monnaie_utilisateur_id UNIQUE (utilisateur_id),
	CONSTRAINT fk_porte_monnaie_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id)
);
-- table sessions
CREATE TABLE sessions (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	utilisateur_id UUID NOT NULL,
	jeton_rafraichissement_hache TEXT NOT NULL,
	appareil_nom TEXT NOT NULL,
	plateforme TEXT NOT NULL,
	adresse_ip INET,
	derniere_activite TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	expire_le TIMESTAMP WITH TIME ZONE NOT NULL,
	revoquee_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_sessions PRIMARY KEY (id),
	CONSTRAINT ck_sessions_plateforme CHECK (plateforme in ('android', 'ios', 'web')),
	CONSTRAINT fk_sessions_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id) ON DELETE CASCADE,
	CONSTRAINT uq_sessions_jeton_rafraichissement_hache UNIQUE (jeton_rafraichissement_hache)
);
CREATE INDEX ix_sessions_expire_le ON sessions (expire_le);
CREATE INDEX ix_sessions_utilisateur_id ON sessions (utilisateur_id);
