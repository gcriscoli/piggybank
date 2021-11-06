-- Script prepared by Giulio Criscoli
-- Wed 08/04/2020 16:30
-- Model:	piggybank 	Version: 0.1


SET @OLD_UK_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

/*
 * The database is meant to hold information about one or more communities whose members partly or entirely
 * share, according to some agreements, their expenditures.
 * Additionally, it also stores some global and community-related configuration parameters for the web
 * application, and activity log information.
 * The DB tables that store operational information are prefixed by ops_; those that store configuration
 * parameters are prefixed by cnf_; and, last, those that store log information are prefixed by log_.
 */

-- -----------------------------------------------------
-- Schema piggybank
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS piggybank;

CREATE SCHEMA IF NOT EXISTS piggybank DEFAULT CHARACTER SET latin1 COLLATE latin1_bin;

USE piggybank;

/*
 * A global administrator has full control over the database, whilst community administrators, accountants,
 * members and applicants have progressively more limited privileges on the community they belong to.
 *
 * Community administrators act as the CEO of the community. They are allowed to:
 * -	found a community;
 * -	grant access to new applicants;
 * -	assign and revoke roles to the other community members;
 * -	visualize and modify their own and the other community members data other than those labeled as "private":
 * 	-	profile information, including the password;
 * 	-	transactions;
 * 	-	estimates and predictions;
 * 	-	...
 *
 * Community accountants only have limited access to the community and the other members data. They are allowed to:
 * -	manage expenditure causals, invoices, items, activities and projects;
 * -	select transactions from the members accounts to build final balances;
 * -	make estimates and predictions for the community as a whole;
 * -	manage their own account, including their profile.
 *
 * Community members are only allowed to manage their own account, including their profile.
 *
 * Community applicants do not have any privileges at all. On the contrary, they are locked out until any
 * community administrator grants them access by promoting their role to member, accountant or administrator.
 *
 * Any community must have an administrator, and may have more than one.
 * Any user may be the member of more than one community.
 */

-- -----------------------------------------------------
-- Roles
-- -----------------------------------------------------
DROP ROLE IF EXISTS 'GLOBAL ADMINISTRATOR';
DROP ROLE IF EXISTS 'COMMUNITY ADMINISTRATOR';
DROP ROLE IF EXISTS 'COMMUNITY ACCOUNTANT';
DROP ROLE IF EXISTS 'COMMUNITY MEMBER';
DROP ROLE IF EXISTS 'COMMUNITY APPLICANT';

CREATE ROLE IF NOT EXISTS 'GLOBAL ADMINISTRATOR';
CREATE ROLE IF NOT EXISTS 'COMMUNITY ADMINISTRATOR';
CREATE ROLE IF NOT EXISTS 'COMMUNITY ACCOUNTANT';
CREATE ROLE IF NOT EXISTS 'COMMUNITY MEMBER';
CREATE ROLE IF NOT EXISTS 'COMMUNITY APPLICANT';

GRANT ALL ON piggybank.* TO 'GLOBAL ADMINISTRATOR' WITH GRANT OPTION;

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, SHOW VIEW ON
	piggybank.expenditureInvoices,
	piggybank.expenditureItems,
	piggybank.expenditureCausals,
	piggybank.typesOfPaymentInstruments,
	piggybank.paymentInstruments,
	piggybank.accounts,
	piggybank.bankAccountHolders,
	piggybank.users,
	piggybank.communityBalance,
	piggybank.userBalance,
	piggybank.activities,
	piggybank.directions,
	piggybank.sharingMethods,
	piggybank.communities,
	piggybank.communityMembers
TO 'COMMUNITY ADMINISTRATOR';

GRANT SELECT SELECT, INSERT, UPDATE, EXECUTE, SHOW VIEW ON
	piggybank.expenditureInvoices,
	piggybank.expenditureItems,
	piggybank.expenditureCausals,
	piggybank.typesOfPaymentInstruments,
	piggybank.paymentInstruments,
	piggybank.accounts,
	piggybank.bankAccountHolders,
	piggybank.users,
	piggybank.communityBalance,
	piggybank.userBalance,
	piggybank.activities
TO 'COMMUNITY ACCOUNTANT';

GRANT SELECT ON
	piggybank.directions,
	piggybank.sharingMethods,
	piggybank.communities,
	piggybank.communityMembers
TO 'COMMUNITY ACCOUNTANT';

GRANT SELECT SELECT, INSERT, UPDATE, EXECUTE, SHOW VIEW ON
	piggybank.expenditureInvoices,
	piggybank.expenditureItems,
	piggybank.expenditureCausals,
	piggybank.paymentInstruments,
	piggybank.accounts,
	piggybank.bankAccountHolders,
	piggybank.users,
	piggybank.userBalance
TO 'COMMUNITY ACCOUNTANT';

GRANT SELECT ON
	piggybank.typesOfPaymentInstruments,
	piggybank.directions,
	piggybank.sharingMethods,
	piggybank.communities,
	piggybank.communityMembers,
	piggybank.communityBalance,
	piggybank.activities
TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- DATABASE USERS (... and I mean DATABASE,
-- not APPLICATION users, that are defined later on)
-- -----------------------------------------------------

-- The ONE and ONLY global administrator
DROP USER IF EXISTS 'piggybank_admin';

CREATE USER IF NOT EXISTS 'piggybank_admin' DEFAULT ROLE 'GLOBAL ADMINISTRATOR' IDENTIFIED WITH mysql_native_password BY 'piggybank_admin';
GRANT ALL ON * TO 'piggybank_admin' WITH GRANT OPTION;

-- Some DEMO users, with different roles.
-- DO NOT FORGET WHEN SWITCHING TO PRODUCTION TO CHANGE NAMES AND DETAILS
DROP USER IF EXISTS 'giulio.criscoli'@'localhost';
CREATE USER IF NOT EXISTS 'giulio.criscoli'@'localhost' DEFAULT ROLE 'COMMUNITY_ADMINISTRATOR' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r';

DROP USER IF EXISTS 'irene.satariano'@'localhost';
CREATE USER IF NOT EXISTS 'irene.satariano'@'localhost' DEFAULT ROLE 'COMMUNITY ACCOUNTANT' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r';
CREATE USER IF NOT EXISTS 'elena.merlo'@'localhost' DEFAULT ROLE 'COMMUNITY APPLICANT' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r';

DROP USER IF EXISTS 'francesco.criscoli'@'localhost';
CREATE USER IF NOT EXISTS 'francesco.criscoli'@'localhost' DEFAULT ROLE 'COMMUNITY_ADMINISTRATOR' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r';

DROP USER IF EXISTS 'maddalena.giusti'@'localhost';
CREATE USER IF NOT EXISTS 'maddalena.giusti'@'localhost' DEFAULT ROLE 'COMMUNITY MEMBER' IDENTIFIED WITH mysql_native_password BY '1q2w3e4r';


-- -----------------------------------------------------
-- TABELLE
-- -----------------------------------------------------


-- -----------------------------------------------------
-- Table expenditureInvoices
-- -----------------------------------------------------
DROP TABLE IF EXISTS expenditureInvoices;

CREATE TABLE IF NOT EXISTS expenditureInvoices (
  id INT NOT NULL AUTO_INCREMENT,
  expenditureInvoice VARCHAR(50) NOT NULL COMMENT 'Invoices to account expenses against',
  CONSTRAINT expenditureInvoices_PK PRIMARY KEY expenditureInvoices_PK_indx (id),
  CONSTRAINT expenditureInvoices_UK UNIQUE KEY expenditureInvoices_UK_indx (expenditureInvoice ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure invoices';

START TRANSACTION;

INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (1, 'Purchase');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (2, 'Leasing');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (3, 'Rental');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (4, 'Fuel');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (5, 'Insurance');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (6, 'Servicing');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (7, 'Maintenance');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (8, 'Morgage');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (9, 'Sale');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (10, 'Tax returns');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (11, 'Professional order');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (12, 'Condominium cleanings');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (13, 'Condominium lightning');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (14, 'Condominium gardening');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (15, 'Condominium facade');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (16, 'Condominium plants');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (17, 'Condominium roof');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (18, 'Refurbishing and improvement');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (19, 'Standardization and law compliance');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (20, 'Water');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (21, 'Lightning');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (22, 'Gas');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (23, 'Telephone');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (24, 'Internet');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (25, 'Mobile phone');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (26, 'Garbage disposal');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (27, 'Registration and tuition fee');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (28, 'Stationery');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (29, 'Books / Photocopies / Notes');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (30, 'Other...');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (31, 'Public transport means');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (32, 'Hotel / Accomodation');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (33, 'Supermarket');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (34, 'Backery / Grocery / Green Grocery');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (35, 'Consortium');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (36, 'Restaurant / Pizza shop');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (37, 'Cinema / Theatre');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (39, 'Redecorating');
INSERT INTO expenditureInvoices (id, expenditureInvoice) VALUE (40, 'Shoes');

COMMIT;

-- -----------------------------------------------------
-- Table expenditureItems
-- -----------------------------------------------------
DROP TABLE IF EXISTS expenditureItems;

CREATE TABLE IF NOT EXISTS expenditureItems (
  id INT NOT NULL AUTO_INCREMENT,
  expenditureItem VARCHAR(25) NOT NULL COMMENT 'Expenditure items',
  CONSTRAINT expenditureItems_PK PRIMARY KEY expenditureItems_PK_indx (id),
  CONSTRAINT expenditureItems_UK UNIQUE KEY expenditureItems_UK_indx (expenditureItem ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure items';

START TRANSACTION;

INSERT INTO expenditureItems (id, expenditureItem) VALUES (1, 'Vehicles');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (2, 'Home');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (3, 'Condominium');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (4, 'Bills');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (5, 'Education');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (6, 'Travels & Holidays');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (7, 'Taxes');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (8, 'Recreation');
INSERT INTO expenditureItems (id, expenditureItem) VALUES (9, 'Shopping');

COMMIT;
-- -----------------------------------------------------
-- Table expenditureCausals
-- -----------------------------------------------------
DROP TABLE IF EXISTS expenditureCausals;

CREATE TABLE IF NOT EXISTS expenditureCausals (
  id INT NOT NULL AUTO_INCREMENT,
  expenditureItem INT NOT NULL,
  expenditureInvoice INT NULL,
  CONSTRAINT expenditureCausals_PK PRIMARY KEY expenditureCausals_PK_indx (id),
  CONSTRAINT expenditureCausals_UK UNIQUE KEY expenditureCausals_UK_indx (expenditureItem ASC, expenditureInvoice ASC),
  CONSTRAINT expenditureCausal_HAS_Item FOREIGN KEY expenditureCausal_HAS_Item_indx (expenditureItem) REFERENCES expenditureItems (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT expenditureCausal_HAS_Invoice FOREIGN KEY expenditureCausal_HAS_Invoice_indx (expenditureInvoice) REFERENCES expenditureInvoices (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure causals';

START TRANSACTION;

INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (1, 1, 1);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (2, 1, 2);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (3, 1, 4);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (4, 1, 5);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (5, 1, 6);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (6, 1, 7);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (7, 1, 9);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (8, 1, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (9, 2, 1);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (10, 2, 3);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (11, 2, 5);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (12, 2, 6);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (13, 2, 7);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (14, 2, 8);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (15, 2, 9);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (16, 2, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (17, 2, 39);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (18, 2, 12);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (19, 2, 13);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (20, 2, 14);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (21, 2, 15);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (22, 2, 16);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (23, 2, 17);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (24, 2, 18);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (25, 2, 19);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (26, 3, 5);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (27, 3, 6);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (28, 3, 7);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (29, 3, 12);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (30, 3, 13);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (31, 3, 14);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (32, 3, 15);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (33, 3, 16);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (34, 3, 17);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (35, 3, 18);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (36, 3, 19);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (37, 3, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (38, 3, 20);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (39, 3, 21);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (40, 3, 22);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (41, 4, 20);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (42, 4, 21);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (43, 4, 22);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (44, 4, 23);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (45, 4, 24);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (46, 4, 25);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (47, 5, 27);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (48, 5, 28);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (49, 5, 29);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (50, 5, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (51, 6, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (52, 6, 31);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (53, 6, 32);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (54, 7, 26);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (55, 7, 35);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (56, 7, 10);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (57, 7, 11);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (58, 7, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (59, 8, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (60, 8, 36);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (61, 8, 37);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (62, 9, NULL);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (63, 9, 30);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (64, 9, 34);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (65, 9, NULL);
INSERT INTO expenditureCausals (id, expenditureItem, expenditureInvoice) VALUE (66, 9, 40);

COMMIT;

-- -----------------------------------------------------
-- Table directions
-- -----------------------------------------------------
DROP TABLE IF EXISTS directions;

CREATE TABLE IF NOT EXISTS directions (
  id INT NOT NULL COMMENT 'The actual transaction directions: -1, 0, or 1',
  direction VARCHAR(5) NULL DEFAULT NULL COMMENT 'The descriptions of transaction directions: income, no transaction, or outflow, respectively',
  synonym VARCHAR(7) NULL DEFAULT NULL COMMENT 'Any synonym for the transacion direction descriptions',
  CONSTRAINT directions_PK PRIMARY KEY directions_PK_indx (id),
  CONSTRAINT directions_UK UNIQUE KEY directions_UK_indx (direction ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Transaction directions';

CREATE UNIQUE INDEX synonym_UK ON directions (synonym ASC);
START TRANSACTION;

INSERT INTO directions (id, direction, synonym) VALUE (0, NULL, NULL);
INSERT INTO directions (id, direction, synonym) VALUE (-1, 'give', 'outflow');
INSERT INTO directions (id, direction, synonym) VALUE (1, 'have', 'income');

COMMIT;
-- -----------------------------------------------------
-- Table sharingMethods
-- -----------------------------------------------------
DROP TABLE IF EXISTS sharingMethods;

CREATE TABLE IF NOT EXISTS sharingMethods (
  id INT NOT NULL,
  sharingMethod VARCHAR(50) NOT NULL,
  description VARCHAR(250) NULL,
  CONSTRAINT sharingMethods_PK PRIMARY KEY sharingMethods_PK_indx (id),
  CONSTRAINT sharingMethods_UK UNIQUE KEY sharingMethods_UK_indx (sharingMethod ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Sharing methods list';

START TRANSACTION;

INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (0, 'NO SHARING', 'Expenditures are not at all shared among the community members. Each transaction');
INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (1, 'DUTCH', 'Expenditures are shared equally among all the community members');
INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (2, 'INCOME BASED', 'Each community member holds a stake that is proportional to their period income');
INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (3, 'WEIGHT BASED', 'Each community member holds a stake that is proportional to their weight on the community');
INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (4, 'FIXED SHARE', 'Each community member holds a stake that is proprotional to a pre-determined fixed value');
INSERT INTO sharingMethods (id, sharingMethod, description) VALUES (5, 'INCOME-WEIGHT', 'Each community member holds a stake on the overall income that is proportional to their income, and on the outflow that is proportinal to their weight on the community');

COMMIT;

-- -----------------------------------------------------
-- Table communities
-- -----------------------------------------------------
DROP TABLE IF EXISTS communities;

CREATE TABLE IF NOT EXISTS communities (
  community VARCHAR(50) NOT NULL COMMENT 'The community name, a string of up to 50 characters',
  sharingMethod INT NOT NULL DEFAULT 1 COMMENT 'The community sharing method. Assumed NO SHARING as default',
  firstAccountingDay INT NOT NULL DEFAULT 28 COMMENT 'The day of the month used as the community starting accounting day. Defaults to 28',
  lastAccountingDay INT NOT NULL DEFAULT 27 COMMENT 'The day of the month used as the community end accounting day. Generally determined as the community first accounting day minus 1, defaults to 27',
  loginFromAnyHost TINYINT NOT NULL DEFAULT 1 'The community members can login from any host',
  CONSTRAINT communities_PK PRIMARY KEY communities_PK_indx (community),
  CONSTRAINT community_HAS_sharingMethod FOREIGN KEY community_HAS_sharingMethod_indx (sharingMethod) REFERENCES sharingMethods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Community list and related settings';

START TRANSACTION;

INSERT INTO communities (community, sharingMethod, firstAccountingDay, lastAccountingDay) VALUE ('Famiglia Criscoli Satariano Merlo', 2, DEFAULT, DEFAULT);
INSERT INTO communities (community, sharingMethod, firstAccountingDay, lastAccountingDay) VALUE ('Famiglia Criscoli Giusti', 0, DEFAULT, DEFAULT);

COMMIT;

-- -----------------------------------------------------
-- Table roles
-- -----------------------------------------------------
/*DROP TABLE IF EXISTS roles;

CREATE TABLE IF NOT EXISTS roles (
  id INT NOT NULL,
  role VARCHAR(25) NOT NULL,
  CONSTRAINT roles_PK PRIMARY KEY roles_PK_indx (id),
  CONSTRAINT roles_UK UNIQUE KEY roles_UK_indx (role ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Role list';

START TRANSACTION;

INSERT INTO roles (id, role) VALUE (0, 'GLOBAL ADMINISTRATOR');
INSERT INTO roles (id, role) VALUE (1, 'COMMUNITY ADMINISTRATOR');
INSERT INTO roles (id, role) VALUE (2, 'COMMUNITY ACCOUNTANT');
INSERT INTO roles (id, role) VALUE (3, 'COMMUNITY MEMBER');
INSERT INTO roles (id, role) VALUE (4, 'COMMUNITY APPLICANT');

COMMIT;*/

-- -----------------------------------------------------
-- Table users
-- -----------------------------------------------------
DROP TABLE IF EXISTS users;

CREATE TABLE IF NOT EXISTS users (
	id INT NOT NULL AUTO_INCREMENT,
	username VARCHAR(64) NOT NULL COMMENT "The user's chosen username",
	hostname VARCHAR(64) NOT NULL DEFAULT '%' COMMENT "The hosts from which the user is authorised to connect. Defaults to ANY (%)",
	firstName VARCHAR(50) NULL DEFAULT NULL COMMENT "The user's firts name and, if applicable, any middle name",
	familyName VARCHAR(75) NULL DEFAULT NULL COMMENT "The user's family name",
	email VARCHAR(100) NULL DEFAULT NULL "Any valid user's email, also used for internal communication",
	CONSTRAINT users_PK PRIMARY KEY users_PK_indx (id),
	CONSTRAINT users_UK UNIQUE KEY users_UK_indx (username ASC, hostname ASC),
	CONSTRAINT appUser_IS_DBMSUser FOREIGN KEY appUser_IS_DBMSUser_indx (hostname, username) REFERENCES mysql.user (Host, User) ON DELETE UPDATE ON CASCADE UPDATE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'All the DB users';

START TRANSACTION;

INSERT INTO users (id, username, hostname, firstName, familyName, email) VALUE (1, 'giulio.criscoli', 'localhost', 'Giulio', 'Criscoli', 'giulio.criscoli@gmail.com');
INSERT INTO users (id, username, hostname, firstName, familyName, email) VALUE (2, 'irene.satariano', 'localhost', 'Maria Irene', 'Satariano', 'irene.satariano@gmail.com');
INSERT INTO users (id, username, hostname, firstName, familyName, email) VALUE (3, 'elena.merlo', 'localhost', 'Elena', 'Merlo', 'elenamerlo96@gmail.com');
INSERT INTO users (id, username, hostname, firstName, familyName, email) VALUE (4, 'francesco.criscoli', 'localhost', 'Francesco', 'Criscoli', 'francesco.criscoli@libero.it');
INSERT INTO users (id, username, hostname, firstName, familyName, email) VALUE (5, 'maddalena.giusti', 'localhost', 'Maddalena', 'Giusti', 'maddalena.giusti@libero.it');

COMMIT;
-- -----------------------------------------------------
-- Table communityMembers
-- -----------------------------------------------------
DROP TABLE IF EXISTS communityMembers;

CREATE TABLE IF NOT EXISTS communityMembers (
  id INT NOT NULL AUTO_INCREMENT,
  community VARCHAR(50) NOT NULL COMMENT 'The community name',
  communityMember INT NOT NULL COMMENT "Every community member",
  weight INT NOT NULL DEFAULT 1 COMMENT 'The weight the user expects to impose on the community',
  -- role INT NOT NULL DEFAULT 2 COMMENT "The user's role within the community",
  CONSTRAINT communityMembers_PK PRIMARY KEY communityMembers_PK_indx (id),
  CONSTRAINT communityMembers_UK UNIQUE KEY communityMembers_UK_indx (community ASC, id ASC),
  CONSTRAINT member_BELONGSTO_community FOREIGN KEY member_BELONGSTO_community_indx (community) REFERENCES communities (community) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT community_HAS_member FOREIGN KEY community_HAS_member_indx (communityMember) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE -- ,
  -- CONSTRAINT communityMember_HAS_role FOREIGN KEY communityMember_HAS_role_indx (role) REFERENCES roles (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'The relationships among the users, the communities they belong to, their role within the community, and their expected weight on the community';

START TRANSACTION;

INSERT INTO communityMembers (id, community, communityMember, weight) VALUE (1, 'Famiglia Criscoli Satariano Merlo', 1, 2);
INSERT INTO communityMembers (id, community, communityMember, weight) VALUE (2, 'Famiglia Criscoli Satariano Merlo', 2, 4);
INSERT INTO communityMembers (id, community, communityMember, weight) VALUE (2, 'Famiglia Criscoli Satariano Merlo', 3, 4);
INSERT INTO communityMembers (id, community, communityMember, weight) VALUE (2, 'Famiglia Criscoli Satariano Merlo', 4, 4);
INSERT INTO communityMembers (id, community, communityMember, weight) VALUE (2, 'Famiglia Criscoli Satariano Merlo', 5, 4);

COMMIT;
-- -----------------------------------------------------
-- Table accounts
-- -----------------------------------------------------
DROP TABLE IF EXISTS accounts;

CREATE TABLE IF NOT EXISTS accounts (
  iban VARCHAR(27) NOT NULL COMMENT 'IBAN code',
  bic VARCHAR(25) NOT NULL COMMENT 'BIC / SWIFT code',
  bank VARCHAR(100) NULL DEFAULT NULL,
  CONSTRAINT accounts_PK PRIMARY KEY accounts_PK_indx (iban),
  CONSTRAINT accounts_UK UNIQUE KEY accounts_UK_indx (bic)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Bank accounts list';

-- -----------------------------------------------------
-- Table typesOfPaymentInstruments
-- -----------------------------------------------------
DROP TABLE IF EXISTS typesOfPaymentInstruments;

CREATE TABLE IF NOT EXISTS typesOfPaymentInstruments (
  type VARCHAR(25) NOT NULL COMMENT 'Payment instruments types, like: credit card, debit card, cheque, cash, ...',
  CONSTRAINT typesOfPaymentInstruments_PK PRIMARY KEY typesOfPaymentInstruments_PK_indx (type)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Payment instruments types';

START TRANSACTION;

INSERT INTO typesOfPaymentInstruments (type) VALUES ('cash');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('credit card');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('debit card');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('cheque');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('permanent bank transfer');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('bank transfer');
INSERT INTO typesOfPaymentInstruments (type) VALUES ('credit transfer (giro)');

COMMIT;
-- -----------------------------------------------------
-- Table bankAccountHolders
-- -----------------------------------------------------
DROP TABLE IF EXISTS bankAccountHolders;

CREATE TABLE IF NOT EXISTS bankAccountHolders (
  id INT NOT NULL,
  bankAccount VARCHAR(27) NOT NULL COMMENT 'Bank account number',
  holder VARCHAR(16) NOT NULL COMMENT 'Bank account holder',
  isOwner TINYINT NOT NULL DEFAULT 1  COMMENT 'Is the holder also the bank account owner?',
  CONSTRAINT bankAccountHolders_PK PRIMARY KEY bankAccountHolders_PK_indx (id),
  CONSTRAINT bankAccountHolders_UK UNIQUE KEY bankAccountHolders_UK_indx (bankAccount ASC, holder ASC),
  CONSTRAINT holder_HOLDS_bankAccount FOREIGN KEY holder_HOLDS_bankAccount_indx (bankAccount) REFERENCES accounts (iban) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT bankAccount_ISHELDBY_holder FOREIGN KEY bankAccount_ISHELDBE_holder (holder) REFERENCES users (SSN) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Relationships between bank accounts and their holders/owners';

-- -----------------------------------------------------
-- Table paymentInstruments
-- -----------------------------------------------------
DROP TABLE IF EXISTS paymentInstruments;

CREATE TABLE IF NOT EXISTS paymentInstruments (
  id INT NOT NULL,
  bankAccount VARCHAR(27) NOT NULL,
  paymentInstrumentType VARCHAR(25) NOT NULL,
  serialNumber VARCHAR(25) NULL DEFAULT NULL,
  holder VARCHAR(16) NULL DEFAULT NULL,
  dailyExpenditureCeiling DECIMAL NULL DEFAULT NULL,
  dailyWithdrawalCeiling DECIMAL NULL DEFAULT NULL,
  monthlyExpenditureCeiling DECIMAL NULL DEFAULT NULL,
  monthlyWithdrawalCeiling DECIMAL NULL DEFAULT NULL,
  firstAccountingDay INT NOT NULL DEFAULT 28,
  lastAccountingDay INT NOT NULL DEFAULT 27,
  CONSTRAINT paymentInstruments_PK PRIMARY KEY paymentInstruments_PK_indx (id),
  CONSTRAINT paymentInstruments_UK UNIQUE KEY paymentInstruments_UK_indx (bankAccount ASC, paymentInstrumentType ASC, holder ASC, serialNumber ASC),
  CONSTRAINT paymentInstrumentType_CHARGESON_bankAccount FOREIGN KEY paymentInstrumentType_CHARGESON_bankAccount_indx (bankAccount) REFERENCES accounts (iban) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT holder_HOLDS_paymentInstrumentType FOREIGN KEY holder_HOLDS_paymentInstrumentType_indx (paymentInstrumentType) REFERENCES typesOfPaymentInstruments (type) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT paymentInstrument_ISHELDBY_holder FOREIGN KEY paymentInstrument_ISHELDBY_holder_indx (holder) REFERENCES users (SSN) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Payment instruments associated to the bank accounts';

-- -----------------------------------------------------
-- Table activities
-- -----------------------------------------------------
DROP TABLE IF EXISTS activities;

CREATE TABLE IF NOT EXISTS activities (
  id INT NOT NULL,
  community VARCHAR(25) NOT NULL COMMENT 'The community name',
  activity VARCHAR(50) NOT NULL COMMENT 'An illustrative, short name for a community activity',
  isProject TINYINT NOT NULL DEFAULT 1 COMMENT 'Is the activity still a project? Meaning: is it funded (activity) or just an intent (project)?',
  description MEDIUMTEXT NULL DEFAULT NULL COMMENT 'A verbose description of the activity or project',
  CONSTRAINT activities_PK PRIMARY KEY activities_PK_indx (id),
  CONSTRAINT activities_UK UNIQUE KEY acitivities_UK_indx (community ASC, activity ASC),
  CONSTRAINT community_HAS_activities FOREIGN KEY community_HAS_activities_indx (community) REFERENCES communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Community activities and projects';

-- -----------------------------------------------------
-- Table transactions
-- -----------------------------------------------------
DROP TABLE IF EXISTS transactions;

CREATE TABLE IF NOT EXISTS transactions (
  id INT NOT NULL,
  paymentInstrument INT NOT NULL,
  date DATE NULL DEFAULT NULL,
  amount DECIMAL NOT NULL,
  direction INT NOT NULL DEFAULT -1,
  expenditureCausal INT NOT NULL,
  isPrivate TINYINT NOT NULL DEFAULT 0,
  activity INT NULL DEFAULT NULL,
  CONSTRAINT transactions_PK PRIMARY KEY transactions_PK_indx (id),
  CONSTRAINT transactions_UK UNIQUE KEY (paymentInstrument ASC, date ASC, amount ASC, direction ASC, expenditureCausal),
  CONSTRAINT transaction_ISCHARGEDTO_paymentInstrument FOREIGN KEY transaction_ISCHARGEDTO_paymentInstrument_indx (paymentInstrument) REFERENCES paymentInstruments (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT transaction_HAS_direction FOREIGN KEY transaction_HAS_direction_indx (direction) REFERENCES directions (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT transaction_HAS_causal FOREIGN KEY transaction_HAS_causal_indx (expenditureCausal) REFERENCES expenditureCausals (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT transaction_ISACCOUNTEDAGAINST_activity FOREIGN KEY transaction_ISACCOUNTEDAGAINST_activity_indx (activity) REFERENCES activities (id)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Transactions list';

-- -----------------------------------------------------
-- Table paymentInstrumentsBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS paymentInstrumentsBalance;

CREATE TABLE IF NOT EXISTS paymentInstrumentsBalance (
  id INT NOT NULL AUTO_INCREMENT,
  paymentInstrument INT NOT NULL COMMENT 'The payment instrument the balance refers to',
  firstAccountingDate DATE NOT NULL COMMENT 'The initial accounting date, as a date',
  lastAccountingDate DATE NOT NULL COMMENT 'The end accounting date, as a date',
  initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
  income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
  outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
  finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
  CONSTRAINT paymentInstrumentsBalance_PK PRIMARY KEY paymentInstrumentsBalance_PK_indx (id),
  CONSTRAINT paymentInstrumentsBalance_UK UNIQUE KEY paymentInstrumentsBalance_UK_indx (paymentInstrument ASC, firstAccountingDate ASC, lastAccountingDate ASC),
  CONSTRAINT balance_REFERSTO_paymentInstrument FOREIGN KEY balance_REFERSTO_paynInstrument_indx (paymentInstrument) REFERENCES paymentInstruments (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Each payment instrument periodical balance';

-- -----------------------------------------------------
-- Table userBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS userBalance;

CREATE TABLE IF NOT EXISTS userBalance (
  id INT NOT NULL AUTO_INCREMENT,
  user VARCHAR(25) NOT NULL COMMENT 'The user the balance refers to',
  firstAccountingDate DATE NOT NULL COMMENT 'The initial accounting date, as a date',
  lastAccountingDate DATE NOT NULL COMMENT 'The end accounting date, as a date',
  initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
  income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
  outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
  finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
  CONSTRAINT userBalance_PK PRIMARY KEY userBalance_PK_indx (id),
  CONSTRAINT userBalance_UK UNIQUE KEY userBalance_UK_indx (user ASC, firstAccountingDate ASC, lastAccountingDate ASC),
  CONSTRAINT balance_REFERSTO_user FOREIGN KEY balance_REFERSTO_user_indx (user) REFERENCES users (SSN) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each user's periodical balance";

-- -----------------------------------------------------
-- Table communityBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS communityBalance;

CREATE TABLE IF NOT EXISTS communityBalance (
  id INT NOT NULL AUTO_INCREMENT,
  community VARCHAR(25) NOT NULL COMMENT 'The community the balance refers to',
  firstAccountingDate DATE NOT NULL COMMENT 'The initial accounting date, as a date',
  lastAccountingDate DATE NOT NULL COMMENT 'The end accounting date, as a date',
  initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
  income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
  outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
  finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
  CONSTRAINT communityBalance_PK PRIMARY KEY communityBalance_PK_indx (id),
  CONSTRAINT communityBalance_UK UNIQUE KEY communityBalance_UK_indx (community ASC, firstAccountingDate ASC, lastAccountingDate),
  CONSTRAINT balance_REFERSTO_community FOREIGN KEY balance_REFERSTO_community_indx (community) REFERENCES communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each community periodical balance";
