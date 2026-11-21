-- Schéma initial, partie 1 : tables ingredients, journal_verifications, plats, utilisateurs, avatars, codes_verification, journal_admin.
-- Figé : une évolution passe par une nouvelle migration, jamais par ce fichier.
-- table ingredients
CREATE TABLE ingredients (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	nom TEXT NOT NULL,
	unite TEXT NOT NULL,
	quantite_actuelle NUMERIC(12, 3) DEFAULT 0 NOT NULL,
	seuil_alerte NUMERIC(12, 3) DEFAULT 0 NOT NULL,
	actif BOOLEAN DEFAULT true NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_ingredients PRIMARY KEY (id),
	CONSTRAINT ck_ingredients_unite CHECK (unite in ('kg', 'g', 'l', 'cl', 'piece')),
	CONSTRAINT ck_ingredients_quantite_positive CHECK (quantite_actuelle >= 0),
	CONSTRAINT ck_ingredients_seuil_positif CHECK (seuil_alerte >= 0)
);
CREATE INDEX ix_ingredients_sous_seuil ON ingredients (id) WHERE quantite_actuelle < seuil_alerte;
CREATE UNIQUE INDEX uq_ingredients_nom_minuscule ON ingredients (lower(nom));
-- table journal_verifications
CREATE TABLE journal_verifications (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	identifiant_masque TEXT NOT NULL,
	canal TEXT NOT NULL,
	etape TEXT NOT NULL,
	raison TEXT,
	adresse_ip INET,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_journal_verifications PRIMARY KEY (id),
	CONSTRAINT ck_journal_verifications_canal CHECK (canal in ('telephone', 'email')),
	CONSTRAINT ck_journal_verifications_etape CHECK (etape in ('demande', 'envoye', 'verifie', 'echec')),
	CONSTRAINT ck_journal_verifications_raison CHECK (raison in ('code_faux', 'expire', 'trop_essais', 'envoi_impossible'))
);
CREATE INDEX ix_journal_verifications_canal_etape ON journal_verifications (canal, etape);
CREATE INDEX ix_journal_verifications_cree_le ON journal_verifications (cree_le desc);
-- table plats
CREATE TABLE plats (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	nom_fr TEXT NOT NULL,
	nom_en TEXT NOT NULL,
	description_fr TEXT DEFAULT '' NOT NULL,
	description_en TEXT DEFAULT '' NOT NULL,
	categorie TEXT NOT NULL,
	image_url TEXT,
	allergenes TEXT[] DEFAULT '{}'::text[] NOT NULL,
	regimes TEXT[] DEFAULT '{}'::text[] NOT NULL,
	calories INTEGER,
	actif BOOLEAN DEFAULT true NOT NULL,
	supprime_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_plats PRIMARY KEY (id),
	CONSTRAINT ck_plats_categorie CHECK (categorie in ('entree', 'plat', 'accompagnement', 'dessert', 'boisson')),
	CONSTRAINT ck_plats_regimes CHECK (regimes <@ array['sans_porc', 'sans_gluten', 'vegetarien', 'halal']::text[]),
	CONSTRAINT ck_plats_calories_positives CHECK (calories >= 0)
);
CREATE INDEX ix_plats_actif ON plats (actif);
CREATE INDEX ix_plats_categorie ON plats (categorie);
CREATE UNIQUE INDEX uq_plats_nom_fr_minuscule ON plats (lower(nom_fr)) WHERE supprime_le is null;
-- table utilisateurs
CREATE TABLE utilisateurs (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	nom_complet TEXT NOT NULL,
	telephone TEXT,
	email TEXT,
	mot_de_passe_hache TEXT NOT NULL,
	role TEXT NOT NULL,
	statut_convive TEXT,
	langue TEXT DEFAULT 'fr' NOT NULL,
	pin_hache TEXT,
	pin_essais INTEGER DEFAULT 0 NOT NULL,
	pin_bloque_jusqua TIMESTAMP WITH TIME ZONE,
	email_verifie_le TIMESTAMP WITH TIME ZONE,
	telephone_verifie_le TIMESTAMP WITH TIME ZONE,
	google_id TEXT,
	apple_id TEXT,
	profil_complet BOOLEAN DEFAULT true NOT NULL,
	allergies TEXT[] DEFAULT '{}'::text[] NOT NULL,
	seuil_alerte_solde INTEGER,
	actif BOOLEAN DEFAULT true NOT NULL,
	supprime_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_utilisateurs PRIMARY KEY (id),
	CONSTRAINT ck_utilisateurs_role CHECK (role in ('convive', 'parent', 'agent', 'admin')),
	CONSTRAINT ck_utilisateurs_statut_convive CHECK (statut_convive in ('eleve', 'etudiant', 'employe')),
	CONSTRAINT ck_utilisateurs_langue CHECK (langue in ('fr', 'en')),
	CONSTRAINT ck_utilisateurs_identifiant_present CHECK (telephone is not null or email is not null),
	CONSTRAINT ck_utilisateurs_statut_selon_role CHECK ((role = 'convive') = (statut_convive is not null)),
	CONSTRAINT ck_utilisateurs_telephone_format CHECK (telephone ~ '^\+225[0-9]{10}$'),
	CONSTRAINT ck_utilisateurs_seuil_positif CHECK (seuil_alerte_solde >= 0),
	CONSTRAINT uq_utilisateurs_telephone UNIQUE (telephone),
	CONSTRAINT uq_utilisateurs_google_id UNIQUE (google_id),
	CONSTRAINT uq_utilisateurs_apple_id UNIQUE (apple_id)
);
CREATE INDEX ix_utilisateurs_role ON utilisateurs (role);
CREATE INDEX ix_utilisateurs_statut_convive ON utilisateurs (statut_convive);
CREATE UNIQUE INDEX uq_utilisateurs_email_minuscule ON utilisateurs (lower(email));
-- table avatars
CREATE TABLE avatars (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	utilisateur_id UUID,
	type TEXT NOT NULL,
	url TEXT NOT NULL,
	actif BOOLEAN DEFAULT true NOT NULL,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_avatars PRIMARY KEY (id),
	CONSTRAINT ck_avatars_type CHECK (type in ('catalogue', 'envoye')),
	CONSTRAINT fk_avatars_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id)
);
CREATE UNIQUE INDEX uq_avatars_utilisateur_envoye_actif ON avatars (utilisateur_id) WHERE type = 'envoye' and actif;
-- table codes_verification
CREATE TABLE codes_verification (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	utilisateur_id UUID,
	identifiant_vise TEXT NOT NULL,
	canal TEXT NOT NULL,
	code_hache TEXT NOT NULL,
	origine TEXT NOT NULL,
	usage TEXT NOT NULL,
	mode_livraison TEXT NOT NULL,
	essais INTEGER DEFAULT 0 NOT NULL,
	essais_max INTEGER DEFAULT 5 NOT NULL,
	expire_le TIMESTAMP WITH TIME ZONE NOT NULL,
	utilise_le TIMESTAMP WITH TIME ZONE,
	modifie_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_codes_verification PRIMARY KEY (id),
	CONSTRAINT ck_codes_verification_canal CHECK (canal in ('telephone', 'email')),
	CONSTRAINT ck_codes_verification_origine CHECK (origine in ('api', 'admin', 'parent')),
	CONSTRAINT ck_codes_verification_usage CHECK (usage in ('verification_compte', 'reinitialisation_mot_de_passe', 'secours', 'changement_identifiant')),
	CONSTRAINT ck_codes_verification_mode_livraison CHECK (mode_livraison in ('demo', 'reel')),
	CONSTRAINT fk_codes_verification_utilisateur_id_utilisateurs FOREIGN KEY(utilisateur_id) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_codes_verification_expire_le ON codes_verification (expire_le);
CREATE INDEX ix_codes_verification_identifiant_canal_usage ON codes_verification (identifiant_vise, canal, usage);
-- table journal_admin
CREATE TABLE journal_admin (
	id UUID DEFAULT gen_random_uuid() NOT NULL,
	admin_id UUID NOT NULL,
	action TEXT NOT NULL,
	cible_type TEXT NOT NULL,
	cible_id UUID,
	avant JSONB,
	apres JSONB,
	adresse_ip INET,
	cree_le TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	CONSTRAINT pk_journal_admin PRIMARY KEY (id),
	CONSTRAINT fk_journal_admin_admin_id_utilisateurs FOREIGN KEY(admin_id) REFERENCES utilisateurs (id)
);
CREATE INDEX ix_journal_admin_admin_cree_le ON journal_admin (admin_id, cree_le desc);
CREATE INDEX ix_journal_admin_cible ON journal_admin (cible_type, cible_id);
