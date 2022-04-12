-- Script prepared by Giulio Criscoli
-- Wed 14/04/2020 15:42
-- Model:	piggybank 	Version: 0.3

-- NOTES
-- Release 0.3
-- Some DEMO users, with different roles.
-- DO NOT FORGET WHEN SWITCHING TO PRODUCTION TO CHANGE NAMES AND DETAILS
DROP USER IF EXISTS 'giulio.criscoli'@'localhost';
CREATE USER IF NOT EXISTS 'giulio.criscoli'@'localhost' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r' DEFAULT ROLE 'COMMUNITY ADMINISTRATOR';

DROP USER IF EXISTS 'irene.satariano'@'localhost';
CREATE USER IF NOT EXISTS 'irene.satariano'@'localhost' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r' DEFAULT ROLE 'COMMUNITY ACCOUNTANT';
CREATE USER IF NOT EXISTS 'elena.merlo'@'localhost' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r' DEFAULT ROLE 'COMMUNITY APPLICANT';

DROP USER IF EXISTS 'francesco.criscoli'@'localhost';
CREATE USER IF NOT EXISTS 'francesco.criscoli'@'localhost' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r' DEFAULT ROLE 'COMMUNITY ADMINISTRATOR';

DROP USER IF EXISTS 'maddalena.giusti'@'localhost';
CREATE USER IF NOT EXISTS 'maddalena.giusti'@'localhost' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r' DEFAULT ROLE 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communities
-- -----------------------------------------------------
START TRANSACTION;

INSERT INTO ops_communities (community, sharingMethod, firstAccountingDay, lastAccountingDay) VALUE ('Famiglia Criscoli Satariano Merlo', 2, DEFAULT, DEFAULT);
INSERT INTO ops_communities (community, sharingMethod, firstAccountingDay, lastAccountingDay) VALUE ('Famiglia Criscoli Giusti', 0, DEFAULT, DEFAULT);

COMMIT;

-- -----------------------------------------------------
-- Table ops_users
-- -----------------------------------------------------
START TRANSACTION;

INSERT INTO ops_users (id, username, hostname, firstName, familyName, email) VALUE (1, 'giulio.criscoli', 'localhost', 'Giulio', 'Criscoli', 'giulio.criscoli@gmail.com');
INSERT INTO ops_users (id, username, hostname, firstName, familyName, email) VALUE (2, 'irene.satariano', 'localhost', 'Maria Irene', 'Satariano', 'irene.satariano@gmail.com');
INSERT INTO ops_users (id, username, hostname, firstName, familyName, email) VALUE (3, 'elena.merlo', 'localhost', 'Elena', 'Merlo', 'elenamerlo96@gmail.com');
INSERT INTO ops_users (id, username, hostname, firstName, familyName, email) VALUE (4, 'francesco.criscoli', 'localhost', 'Francesco', 'Criscoli', 'francesco.criscoli@libero.it');
INSERT INTO ops_users (id, username, hostname, firstName, familyName, email) VALUE (5, 'maddalena.giusti', 'localhost', 'Maddalena', 'Giusti', 'maddalena.giusti@libero.it');

COMMIT;

-- -----------------------------------------------------
-- Table ops_communityMembers
-- -----------------------------------------------------
START TRANSACTION;

INSERT INTO ops_communityMembers (id, community, communityMember, weight) VALUE (1, 'Famiglia Criscoli Satariano Merlo', 1, 2.5);
INSERT INTO ops_communityMembers (id, community, communityMember, weight) VALUE (2, 'Famiglia Criscoli Satariano Merlo', 2, 2.5);
INSERT INTO ops_communityMembers (id, community, communityMember, weight) VALUE (3, 'Famiglia Criscoli Satariano Merlo', 3, 0);
INSERT INTO ops_communityMembers (id, community, communityMember, weight) VALUE (4, 'Famiglia Criscoli Giusti', 4, 1);
INSERT INTO ops_communityMembers (id, community, communityMember, weight) VALUE (5, 'Famiglia Criscoli Giusti', 5, 1);

COMMIT;
