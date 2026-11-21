-- Schéma initial, partie 5 : valeurs de départ de la table parametres, toutes modifiables au back office.
-- Heure limite et remise reprises du tableau des valeurs connues et de la maquette ; heures en UTC.
INSERT INTO parametres (cle, valeur, type_valeur, libelle_fr, libelle_en, groupe) VALUES
	('heure_limite_defaut', '"11:00"', 'heure', 'Heure limite de réservation par défaut', 'Default booking cut-off time', 'service'),
	('delai_annulation_minutes', '0', 'entier', 'Minutes avant l''heure limite pour annuler', 'Minutes before cut-off to cancel', 'service'),
	('capacite_creneau_defaut', '40', 'entier', 'Places par créneau par défaut', 'Default seats per slot', 'service'),
	('mode_paiement', '"test"', 'texte', 'Mode de paiement', 'Payment mode', 'paiement'),
	('livraison_verification_telephone', '"demo"', 'texte', 'Livraison des codes par téléphone', 'Phone code delivery', 'verification'),
	('livraison_verification_email', '"demo"', 'texte', 'Livraison des codes par e-mail', 'E-mail code delivery', 'verification'),
	('duree_code_verification_minutes', '10', 'entier', 'Durée de validité d''un code', 'Code validity duration', 'verification'),
	('essais_code_max', '5', 'entier', 'Essais permis par code', 'Attempts allowed per code', 'verification'),
	('seuil_alerte_solde_defaut', '1500', 'entier', 'Seuil d''alerte de solde bas par défaut', 'Default low balance threshold', 'notification'),
	('remise_anti_gaspillage_pourcent', '50', 'entier', 'Remise anti-gaspillage en pourcentage', 'Anti-waste discount percentage', 'service'),
	('langues_actives', '["fr", "en"]', 'liste', 'Langues actives', 'Active languages', 'general')
ON CONFLICT (cle) DO NOTHING;
