-- i. Interrogation des groupes jouant un titre donné.
-- • Par exemple pour le titre « Detachable penis »
SELECT G.gro_nom AS "Nom du Groupe"
FROM CHANSON C
JOIN REPERTOIRE R ON C.cha_id = R.cha_id
JOIN GROUPE G ON R.gro_id = G.gro_id
WHERE C.cha_titre = 'Detachable penis';

-- ii. Interrogation des rencontres où un titre a été interprété et par qui.
-- • Par exemple pour le titre « The End »
SELECT REN.ren_nom AS "Nom de la Rencontre", G.gro_nom AS "Nom du Groupe"
FROM CHANSON C
JOIN REPRESENTATION R ON C.cha_id = R.cha_id
JOIN PASSAGE P ON R.pas_id = P.pas_id
JOIN RENCONTRE REN ON P.ren_id = REN.ren_id
JOIN GROUPE G ON P.gro_id = G.gro_id
WHERE C.cha_titre = 'The End';

-- iii. Interrogation des membres ayant une spécialité donnée pour une 
-- rencontre donnée. 
-- • Par exemple pour le festival « CAP FESTIVAL » et la spécialité « Soliste »
SELECT P.per_nom AS "Nom du Membre", P.per_prenom AS "Prénom du Membre", S.spe_nom AS "Spécialité"
FROM PERSONNE P
JOIN SPECIALISER SP ON P.per_id = SP.per_id
JOIN SPECIALITE S ON SP.spe_id = S.spe_id
JOIN RENCONTRE R ON SP.ren_id = R.ren_id
WHERE S.spe_nom = 'Soliste' AND R.ren_nom = 'CAP FESTIVAL';

-- iv. Interrogation des titres de plus de x minutes pour un pays ou une 
-- région donnée. 
-- • Par exemple pour la région « Bavière » et le pays « Royaume-Uni »
SELECT C.cha_titre AS "Titre", C.cha_tps AS "Durée"
FROM CHANSON C
JOIN REPERTOIRE R ON C.cha_id = R.cha_id
JOIN REPRESENTER RP ON R.gro_id = RP.gro_id
JOIN REGION REG ON RP.reg_id = REG.reg_id
JOIN PAYS P ON REG.pay_id = P.pay_id
WHERE (REG.reg_nom = 'Bavière' OR P.pay_nom = 'Royaume-Uni') AND TIME_TO_SEC(C.cha_tps) > 300;

-- v. Interrogation des rencontres ayant eu n groupes participants. 
-- • Test avec 1, 2, 3
SELECT REN.ren_nom AS "Nom de la Rencontre", COUNT(DISTINCT P.gro_id) AS "Nombre de Groupes"
FROM PASSAGE P
JOIN RENCONTRE REN ON P.ren_id = REN.ren_id
GROUP BY REN.ren_nom
HAVING COUNT(DISTINCT P.gro_id) IN (1, 2, 3);

-- vi. Interrogation des rencontres où on a joué d'un instrument donné
SELECT REN.ren_nom AS "Nom de la Rencontre", INS.ins_nom AS "Instrument Utilisé"
FROM NECESSITE N
JOIN INSTRUMENT INS ON N.ins_id = INS.ins_id
JOIN CHANSON C ON N.cha_id = C.cha_id
JOIN REPRESENTATION R ON C.cha_id = R.cha_id
JOIN PASSAGE P ON R.pas_id = P.pas_id
JOIN RENCONTRE REN ON P.ren_id = REN.ren_id
WHERE INS.ins_nom = 'Piano';

-- vii. Planning complet de la rencontre par lieu et groupe.
SELECT P.pas_date AS "Date", 
       P.pas_heuredeb AS "Heure de Début", 
       P.pas_heurefin AS "Heure de Fin", 
       P.pas_lieu AS "Lieu", 
       G.gro_nom AS "Nom du Groupe"
FROM PASSAGE P
JOIN RENCONTRE REN ON P.ren_id = REN.ren_id
JOIN GROUPE G ON P.gro_id = G.gro_id
WHERE REN.ren_nom LIKE '%Irlande%'
ORDER BY P.pas_date, P.pas_heuredeb;


--  Donner la séquence en SQL pour créer un compte utilisateur avec des droits 
-- de consultations (lecture et écriture) de la base de données mais sans les 
-- droits d’administrations de la base de données.

-- Dans le SGBD MySql
-- Créer un utilisateur avec un mot de passe

CREATE USER 'mevine'@'localhost' IDENTIFIED BY 'vine';

-- Donner les droits de lecture et écriture sur toutes les tables de la base de données
GRANT SELECT, INSERT, UPDATE, DELETE ON AirdeJava.* TO 'mevine'@'localhost';

-- Supprimer les droits administratifs
REVOKE CREATE, DROP, ALTER, INDEX, LOCK TABLES, CREATE TEMPORARY TABLES, EVENT, TRIGGER ON AirdeJava.* FROM 'mevine'@'localhost';

-- Appliquer les modifications de droits
FLUSH PRIVILEGES;

-- Dans la table Login
CREATE TABLE IF NOT EXISTS login (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'utilisateur',
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Augmenter la taille de la colonne log_pass
ALTER TABLE LOGIN MODIFY log_pass CHAR(64);

DELIMITER //

CREATE PROCEDURE AjouterUtilisateur(
    IN nom_utilisateur VARCHAR(50),
    IN motdepasse VARCHAR(50),
    IN role VARCHAR(20)
)
BEGIN
    -- Déclaration de la variable pour le profil ID
    DECLARE profil_id INT;

    -- Vérification si l'utilisateur existe déjà
    IF (SELECT COUNT(*) FROM mysql.user WHERE user = nom_utilisateur AND host = 'localhost') = 0 THEN
        -- Création de l'utilisateur dans MySQL avec un mot de passe
        SET @create_user_query = CONCAT("CREATE USER '", nom_utilisateur, "'@'localhost' IDENTIFIED BY '", motdepasse, "';");
        PREPARE stmt FROM @create_user_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Attribution des droits
    SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE, DELETE ON AirdeJava.* TO '", nom_utilisateur, "'@'localhost';");
    PREPARE stmt FROM @grant_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Détermination de l'ID de profil en fonction du rôle
    IF role = 'Administrateur' THEN
        SET profil_id = 1;
    ELSEIF role = 'Utilisateur' THEN
        SET profil_id = 2;
    ELSEIF role = 'Consultation' THEN
        SET profil_id = 3;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rôle invalide';
    END IF;

    -- Enregistrement des informations de l'utilisateur dans la table LOGIN
    INSERT INTO LOGIN (pro_id, log_nom, log_pass)
    VALUES (profil_id, nom_utilisateur, SHA2(motdepasse, 256));

    -- Appliquer les modifications de droits
    FLUSH PRIVILEGES;
END //

DELIMITER ;

CALL AjouterUtilisateur('Meivn', 'moil', 'Utilisateur');


-- Sans hashage
DELIMITER //

CREATE PROCEDURE AjouterUtilisateur(
    IN nom_utilisateur VARCHAR(50),
    IN motdepasse VARCHAR(50),
    IN role VARCHAR(20)
)
BEGIN
    -- Déclaration de la variable pour le profil ID
    DECLARE profil_id INT;

    -- Vérification si l'utilisateur existe déjà
    IF (SELECT COUNT(*) FROM mysql.user WHERE user = nom_utilisateur AND host = 'localhost') = 0 THEN
        -- Création de l'utilisateur dans MySQL avec un mot de passe
        SET @create_user_query = CONCAT("CREATE USER '", nom_utilisateur, "'@'localhost' IDENTIFIED BY '", motdepasse, "';");
        PREPARE stmt FROM @create_user_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Attribution des droits (ajustez les droits selon vos besoins)
    SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE, DELETE ON AirdeJava.* TO '", nom_utilisateur, "'@'localhost';");
    PREPARE stmt FROM @grant_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Détermination de l'ID de profil en fonction du rôle
    IF role = 'Administrateur' THEN
        SET profil_id = 1;
    ELSEIF role = 'Utilisateur' THEN
        SET profil_id = 2;
    ELSEIF role = 'Consultation' THEN
        SET profil_id = 3;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rôle invalide';
    END IF;

    -- Enregistrement des informations de l'utilisateur dans la table LOGIN
    INSERT INTO LOGIN (pro_id, log_nom, log_pass)
    VALUES (profil_id, nom_utilisateur, motdepasse);

    -- Appliquer les modifications de droits
    FLUSH PRIVILEGES;
END //

DELIMITER ;

CALL AjouterUtilisateur('Mevin', 'loim', 'Consultation');

REVOKE INSERT, UPDATE, DELETE ON AirdeJava.* FROM 'Mevin'@'localhost';

GRANT INSERT, UPDATE, DELETE ON AirdeJava.AUTEUR TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.CHANSON TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.CIVILITE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.GROUPE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.INSTRUMENT TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.JOUER TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.MEMBRE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.NECESSITE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.OCCUPER TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.PASSAGE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.PAYS TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.PERIODICITE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.PERSONNE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.REGION TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.RENCONTRE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.REPERTOIRE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.REPRESENTATION TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.REPRESENTER TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.RESPONSABILITE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.SPECIALISER TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.SPECIALITE TO 'Mevin'@'localhost';
GRANT INSERT, UPDATE, DELETE ON AirdeJava.TYPEOEUVRE TO 'Mevin'@'localhost';

-- Permission d'accès
GRANT SELECT ON AirdeJava.Profil TO 'Mevin'@'localhost';
GRANT SELECT ON AirdeJava.Acces TO 'Mevin'@'localhost';
GRANT SELECT ON AirdeJava.Menu TO 'Mevin'@'localhost';
GRANT SELECT ON AirdeJava.Login TO 'Mevin'@'localhost';

-- Restriction d'accès
-- Retirer les droits d'écriture pour l'utilisateur sur les tables spécifiques
REVOKE INSERT, UPDATE, DELETE ON AirdeJava.Profil FROM 'Mevin'@'localhost';
REVOKE INSERT, UPDATE, DELETE ON AirdeJava.Acces FROM 'Mevin'@'localhost';
REVOKE INSERT, UPDATE, DELETE ON AirdeJava.Menu FROM 'Mevin'@'localhost';
REVOKE INSERT, UPDATE, DELETE ON AirdeJava.Login FROM 'Mevin'@'localhost';

-- Appliquer les modifications de droits
-- FLUSH PRIVILEGES;


--  Créez une fonction permettant de contrôler qu’une date de rencontre est bien 
-- un vendredi soir, un samedi ou un dimanche en matinée. Exception : du 15 
-- juin au 15 septembre, les rencontres peuvent se dérouler n’importe quel jour.

DROP FUNCTION IF EXISTS VerifierDateRencontre;
DELIMITER //

CREATE FUNCTION VerifierDateRencontre(date_rencontre DATETIME) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE mois INT;
    DECLARE jour INT;
    DECLARE jour_semaine INT;
    DECLARE heure TIME;

    -- Extraire le mois et le jour
    SET mois = MONTH(date_rencontre);
    SET jour = DAY(date_rencontre);
    SET jour_semaine = DAYOFWEEK(date_rencontre);
    SET heure = TIME(date_rencontre);

    -- Vérifier si la date est entre le 15 juin et le 15 septembre
    IF (mois = 6 AND jour >= 15) OR
       (mois = 7) OR
       (mois = 8) OR
       (mois = 9 AND jour <= 15) THEN
        RETURN TRUE;
    END IF;

    -- Sinon, vérifier les conditions pour le reste de l'année
    -- Vendredi soir (après 18:00), samedi (toute la journée) ou dimanche matin (jusqu'à 12:00)
    IF (jour_semaine = 6 AND heure >= '18:00:00') OR    -- Vendredi soir
       (jour_semaine = 7) OR                            -- Samedi
       (jour_semaine = 1 AND heure <= '12:00:00') THEN  -- Dimanche matin
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //

DELIMITER ;

-- Utilisation de la fonction
SELECT VerifierDateRencontre('2024-04-19 10:00:00'); 
SELECT VerifierDateRencontre('2024-06-20 15:00:00');
SELECT VerifierDateRencontre('2024-11-15 19:00:00'); 


-- Mettez en place les triggers liées à la suppression d’un groupe et à la 
-- suppression d’une œuvre.
-- Groupe
DELIMITER //

CREATE TRIGGER avant_suppression_groupe
BEFORE DELETE ON GROUPE
FOR EACH ROW
BEGIN
    -- Supprimer les membres du groupe
    DELETE FROM MEMBRE WHERE GRO_ID = OLD.GRO_ID;

    -- Supprimer les représentations de ce groupe
    DELETE FROM REPRESENTER WHERE GRO_ID = OLD.GRO_ID;

    -- Supprimer les répertoires associés au groupe
    DELETE FROM REPERTOIRE WHERE GRO_ID = OLD.GRO_ID;

    -- Supprimer les responsabilités occupées par le groupe
    DELETE FROM OCCUPER WHERE GRO_ID = OLD.GRO_ID;

    -- Supprimer les passages de ce groupe
    DELETE FROM PASSAGE WHERE GRO_ID = OLD.GRO_ID;
END //

DELIMITER ;

-- Oeuvre
DELIMITER //

CREATE TRIGGER avant_suppression_oeuvre
BEFORE DELETE ON CHANSON
FOR EACH ROW
BEGIN
    -- Supprimer l'œuvre du répertoire
    DELETE FROM REPERTOIRE WHERE CHA_ID = OLD.CHA_ID;

    -- Supprimer les représentations de cette œuvre
    DELETE FROM REPRESENTATION WHERE CHA_ID = OLD.CHA_ID;

    -- Supprimer les informations d'auteur de cette œuvre
    DELETE FROM AUTEUR WHERE CHA_ID = OLD.CHA_ID;

    -- Supprimer les besoins d'instruments pour cette œuvre
    DELETE FROM NECESSITE WHERE CHA_ID = OLD.CHA_ID;
END //

DELIMITER ;

-- Créez une procédure stockée qui sélectionne les groupes qui ne participent 
-- pas à une rencontre donnée, puis une autre qui renvoie le dernier numéro de 
-- rencontre insérée.
--  Groupes qui ne participent pas à une rencontre donnée

DELIMITER //

CREATE PROCEDURE GroupesNonParticipants(rencontre_id INT)
BEGIN
    SELECT GROUPE.GRO_ID, GROUPE.GRO_NOM
    FROM GROUPE
    WHERE GROUPE.GRO_ID NOT IN (
        SELECT GRO_ID 
        FROM PASSAGE 
        WHERE REN_ID = rencontre_id
    );
END //

DELIMITER ;

CALL GroupesNonParticipants(3);


 -- Obtenir le dernier numéro de rencontre inséré
 
 DELIMITER //

CREATE PROCEDURE DernierNumeroRencontre()
BEGIN
    DECLARE dernier_id INT;

    -- Récupère le plus grand REN_ID dans la table RENCONTRE
    SELECT MAX(REN_ID) INTO dernier_id FROM RENCONTRE;

    -- Retourne le dernier ID trouvé
    SELECT dernier_id AS DernierNumeroRencontre;
END //

DELIMITER ;

CALL DernierNumeroRencontre();


--  Créez un objet du SGDB qui permet de générer sept rencontres ayant les 
-- mêmes caractéristiques sauf le jour de la rencontre qui varie d’une journée à 
-- chaque fois. 
-- • Vous devez vous assurer que la date de rencontre est correcte sinon 
-- aucune des rencontres ne doit être insérée (transaction) – réutiliser la 
-- fonction crée précédemment.

DELIMITER //

CREATE PROCEDURE GenererRencontres(
    IN per_id INT,
    IN peri_id INT,
    IN reg_id INT,
    IN nom_rencontre VARCHAR(20),
    IN lieu_rencontre VARCHAR(20),
    IN date_debut DATETIME,
    IN date_fin DATETIME,
    IN nb_pers INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE date_rencontre DATE;
    DECLARE toutes_les_dates_valides BOOLEAN DEFAULT TRUE;

    -- Démarre une transaction
    START TRANSACTION;

    -- Nomme le bloc pour pouvoir quitter la boucle si une date est invalide
    validation: BEGIN
        -- Vérifie que chaque date respecte les critères
        WHILE i < 7 DO
            SET date_rencontre = DATE_ADD(date_debut, INTERVAL i DAY);
            
            -- Appelle la fonction VerifierDateRencontre pour vérifier la validité de la date
            IF VerifierDateRencontre(date_rencontre) = FALSE THEN
                SET toutes_les_dates_valides = FALSE;
                LEAVE validation;
            END IF;
            
            SET i = i + 1;
        END WHILE;
    END validation;

    -- Si toutes les dates sont valides, insère les rencontres
    IF toutes_les_dates_valides THEN
        SET i = 0;
        WHILE i < 7 DO
            SET date_rencontre = DATE_ADD(date_debut, INTERVAL i DAY);

            INSERT INTO RENCONTRE (
                PER_ID, PERI_ID, REG_ID, REN_NOM, REN_LIEU, REN_DATEDEBUT, REN_DATEFIN, REN_NBPERS
            ) VALUES (
                per_id, peri_id, reg_id, nom_rencontre, lieu_rencontre, date_rencontre, DATE_ADD(date_rencontre, INTERVAL TIMESTAMPDIFF(DAY, date_debut, date_fin) DAY), nb_pers
            );
            
            SET i = i + 1;
        END WHILE;
        
        -- Si tout est bon, valide la transaction
        COMMIT;
    ELSE
        -- Annule la transaction si une date est invalide
        ROLLBACK;
    END IF;
END //

DELIMITER ;

CALL GenererRencontres(
    1,              -- PER_ID
    6,              -- PERI_ID
    25,             -- REG_ID
    'Festival Test', -- Nom de la rencontre
    'Paris',        -- Lieu de la rencontre
    '2024-04-19 10:00:00', -- Date de début de la première rencontre
    '2024-04-19 18:00:00', -- Date de fin de la première rencontre
    200             -- Nombre de personnes
);