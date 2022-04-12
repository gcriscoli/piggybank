-- Script prepared by Giulio Criscoli
-- Wed 30/04/2020 10:45
-- Model:	piggybank 	Version: 0.5.1

-- NOTES
-- Release 0.5.1
-- -	Inserted user 'piggybank_admin'@'%' in table ops_users; This record is to be deleted from this file and recorded separatly
--	(possibly from the application configuration file so soon as ready) in a proto-definitive version
-- Relaese 0.5
-- -	Removed field remoteHostname, remoteHTTPClientIP, remoteHTTPXForwardedFor from table log_errorLog;
-- -	Removed field remoteHostname, remoteHTTPClientIP, remoteHTTPXForwardedFor from table log_activityLog.

-- Release 0.4
-- -	Modified table log_activityLog to also include:
--	-	remoteIPAddress (replaces old userIP),
--	-	remoteHostname
--	-	remoteHTTPClientIP
--	-	remoteHTTPXForwardedFor
--	-	requestingMySQLClient
-- - Modified table log_errorLog to also include:
--	-	remoteIPAddress (replaces old userIP),
--	-	remoteHostname
--	-	remoteHTTPClientIP
--	-	remoteHTTPXForwardedFor
--	-	requestingMySQLClient

-- Release 0.3
-- -	Added a unique key to identify each community;
-- -	Separated DEMO data from CONFIGURATION and DEFAULT data; now all DEMO information is in a file called
--	demoPiggybankData.sql;
-- -	Related expenditureItems, expenditureDetails and expenditureCausals to communities;
-- -	Created a GLOBAL community to store shared expenditureXXX information;
-- -	Removed the numeric id from table expenditureDetails;
-- -	Removed the numeric id from table expenditureItems;
-- -	Updated table expenditureCausals foreign keys accordingly;

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
 * -	manage expenditure causals, invoices, items, ops_activities and projects;
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
-- DATABASE Roles
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

-- -----------------------------------------------------
-- DATABASE USERS (... and I mean DATABASE,
-- not APPLICATION users, that are defined later on)
-- -----------------------------------------------------

-- The ONE and ONLY global administrator
DROP USER IF EXISTS 'piggybank_admin';

CREATE USER IF NOT EXISTS 'piggybank_admin' IDENTIFIED WITH mysql_native_password BY 'P!ggyb4nk' DEFAULT ROLE 'GLOBAL ADMINISTRATOR';
GRANT ALL ON * TO 'piggybank_admin' WITH GRANT OPTION;

-- -----------------------------------------------------
-- Table cnf_sharingMethods
-- -----------------------------------------------------
DROP TABLE IF EXISTS cnf_sharingMethods;

CREATE TABLE IF NOT EXISTS cnf_sharingMethods (
	id INT NOT NULL,
	sharingMethod VARCHAR(50) NOT NULL,
	description VARCHAR(250) NULL,
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT cnf_sharingMethods_PK PRIMARY KEY cnf_sharingMethods_PK_indx (id),
	CONSTRAINT cnf_sharingMethods_UK UNIQUE KEY cnf_sharingMethods_UK_indx (sharingMethod ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Sharing methods list';

START TRANSACTION;

INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (0, 'NO SHARING', 'Expenditures are not at all shared among the community members. Each transaction');
INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (1, 'DUTCH', 'Expenditures are shared equally among all the community members');
INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (2, 'INCOME BASED', 'Each community member holds a stake that is proportional to their period income');
INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (3, 'WEIGHT BASED', 'Each community member holds a stake that is proportional to their weight on the community');
INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (4, 'FIXED SHARE', 'Each community member holds a stake that is proprotional to a pre-determined fixed value');
INSERT INTO cnf_sharingMethods (id, sharingMethod, description) VALUE (5, 'INCOME-WEIGHT', 'Each community member holds a stake on the overall income that is proportional to their income, and on the outflow that is proportinal to their weight on the community');

COMMIT;

-- -----------------------------------------------------
-- Table ops_communities
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communities;

CREATE TABLE IF NOT EXISTS ops_communities (
	community VARCHAR(50) NOT NULL COMMENT 'The community name, a string of up to 50 characters',
	communityKey VARCHAR(10) NOT NULL COMMENT 'A short, textual, unique key to allow for convenient community identification,',
	initialBalance DECIMAL(11,3) NOT NULL DEFAULT 0 COMMENT 'The community initial balance',
	sharingMethod INT NOT NULL DEFAULT 1 COMMENT 'The community sharing method. Assumed NO SHARING as default',
	firstAccountingDay INT NOT NULL DEFAULT 28 COMMENT 'The day of the month used as the community starting accounting day. Defaults to 28',
	lastAccountingDay INT NOT NULL DEFAULT 27 COMMENT 'The day of the month used as the community end accounting day. Generally determined as the community first accounting day minus 1, defaults to 27',
	loginFromAnyHost TINYINT NOT NULL DEFAULT 1 COMMENT 'The community members can login from any host',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communities_PK PRIMARY KEY ops_communities_PK_indx (community),
	CONSTRAINT ops_communityKey_UK UNIQUE KEY ops_communityKey_indx (communityKey ASC),
	CONSTRAINT community_HAS_sharingMethod FOREIGN KEY community_HAS_sharingMethod_indx (sharingMethod) REFERENCES cnf_sharingMethods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Community list and related settings';

GRANT SELECT, INSERT, UPDATE ON ops_communities TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (initialBalance,firstAccountingDay, lastAccountingDay) ON ops_communities TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT ON ops_communities TO 'COMMUNITY MEMBER';

START TRANSACTION;

INSERT INTO ops_communities (community, communityKey) VALUE ('GLOBAL', 'GLOBAL');

COMMIT;

-- -----------------------------------------------------
-- Table ops_expenditureItems
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_expenditureItems;

CREATE TABLE IF NOT EXISTS ops_expenditureItems (
	expenditureItem VARCHAR(25) NOT NULL COMMENT 'Expenditure items',
	community VARCHAR(50) NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure item is related',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_expenditureItems_PK PRIMARY KEY ops_expenditureItems_PK_indx (expenditureItem),
	CONSTRAINT expenditureItem_REFERSTO_community FOREIGN KEY expenditureItem_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure items';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_expenditureItems TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (expenditureItem) ON ops_expenditureItems TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT ON ops_expenditureItems TO 'COMMUNITY MEMBER';

START TRANSACTION;

INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Vehicles');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Home');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Bills');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Medical');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Education');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Sports');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Travels & Holidays');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Taxes');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Leisure and recreation');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Daily shopping');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Clothing and outfit');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Social life');
INSERT INTO ops_expenditureItems (expenditureItem) VALUE ('Charity');

COMMIT;

-- -----------------------------------------------------
-- Table ops_expenditureDetails
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_expenditureDetails;

CREATE TABLE IF NOT EXISTS ops_expenditureDetails (
	expenditureDetail VARCHAR(50) NOT NULL COMMENT 'Invoices to account expenses against',
	community VARCHAR(50) NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure invoice is related',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_expenditureDetails_PK PRIMARY KEY ops_expenditureDetails_PK_indx (expenditureDetail ASC),
	CONSTRAINT expenditureDetail_REFERSTO_community FOREIGN KEY expenditureDetail_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure invoices';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_expenditureDetails TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (expenditureDetail) ON ops_expenditureDetails TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT ON ops_expenditureDetails TO 'COMMUNITY MEMBER';

START TRANSACTION;

-- Vehicles
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Purchase');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Rental');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Long term leasing');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Fuel');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Servicing');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Maintenance and repair');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Insurance');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Road tax');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Property tax');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Technical inspection');

-- Home
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Mortgage');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Renovation');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Redecoration');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Refurbishing');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Standardization and law compliance');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Condominium fees');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Commissions');

-- Bills
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Water');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Electricity');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Gas');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Telephone');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Internet');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Mobile phone');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Garbage disposal');

-- Medical
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Health insurance');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Dental care');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Medical care');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Practitioners and specialists');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Drugs');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Hospitalization');

-- Education
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Registration fee');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Tuition fee');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Stationery');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Books');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Photocopies, handouts, ...');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Accomodation');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Public transportation');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Libraries');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Museums');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Visits');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Field trips');

-- Sports
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Equipment, gear and outfit');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Physical examination');

-- Travel and holidays

INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Reservations');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Tickets');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Taxes and other fees');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Travel guides');

-- Taxes
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Tax returns');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Professional order');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Retirement fund');

-- Leisure and recreation
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Eating out');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Cinemas and theatres');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Events and receptions');



-- Shopping
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Supermarket');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Backery, grocery, green grocery, ...');

-- Clothing and outfit
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Shoes');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Clothes');

-- Social life
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Presents');
INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Associations and clubs');

INSERT INTO ops_expenditureDetails (expenditureDetail) VALUE ('Donations');

COMMIT;

-- -----------------------------------------------------
-- Table ops_expenditureCausals
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_expenditureCausals;

CREATE TABLE IF NOT EXISTS ops_expenditureCausals (
	id INT NOT NULL AUTO_INCREMENT,
	expenditureItem VARCHAR(25) NOT NULL,
	expenditureDetail VARCHAR(50) NULL DEFAULT NULL,
	community VARCHAR(50) NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure causal is related',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_expenditureCausals_PK PRIMARY KEY ops_expenditureCausals_PK_indx (id),
	CONSTRAINT ops_expenditureCausals_UK UNIQUE KEY ops_expenditureCausals_UK_indx (expenditureItem ASC, expenditureDetail ASC),
	CONSTRAINT expenditureCausal_HAS_Item FOREIGN KEY expenditureCausal_HAS_Item_indx (expenditureItem) REFERENCES ops_expenditureItems (expenditureItem) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT expenditureCausal_HAS_Invoice FOREIGN KEY expenditureCausal_HAS_Invoice_indx (expenditureDetail) REFERENCES ops_expenditureDetails (expenditureDetail) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT expenditureCausal_REFERSTO_community FOREIGN KEY expenditureCausal_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'List of expenditure causals';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_expenditureCausals TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (expenditureItem, expenditureDetail) ON ops_expenditureCausals TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT ON ops_expenditureCausals TO 'COMMUNITY MEMBER';

START TRANSACTION;

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Purchase');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Rental');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Long term leasing');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Fuel');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Servicing');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Maintenance and repair');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Insurance');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Road tax');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Property tax');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Registration fee');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Vehicles', 'Technical inspection');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Purchase');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Rental');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Mortgage');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Renovation');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Redecoration');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Refurbishing');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Standardization and law compliance');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Condominium fees');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Insurance');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Property tax');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Home', 'Commissions');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Water');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Electricity');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Gas');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Telephone');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Internet');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'TV');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Mobile phone');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Bills', 'Garbage disposal');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Heath insurance');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Dental care');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Medical care');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Practitioners and specialists');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Drugs');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Medical', 'Hospitalization');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Registration fee');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Tuition fee');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Stationery');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Books');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Photocopies, handouts, ...');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Accomodation');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Public transportation');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Libraries');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Museums');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Visits');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Education', 'Field trips');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Sports', 'Registration fee');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Sports', 'Physical examination');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Sports', 'Equipment, gear and outfit');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Insurance');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Commissions');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Accomodation');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Public transportation');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Museums');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Visits');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Equipment, gear and outfit');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Reservations');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Tickets');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Taxes and other fees');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Travel and holidays', 'Travel guides');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Tax returns');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Professional order');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Retirement fund');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Property tax');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Estate tax');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Taxes', 'Garbage disposal');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Books');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Libraries');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Museums');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Visits');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Eating out');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Cinemas and theaters');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Events and receptions');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Leisure and recreation', 'Associations and clubs');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Daily shopping', 'Supermarket');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Daily shopping', 'Bakery, grocery, green grocery, ...');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Clothing and outfit', 'Clotes');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Clothing and outfit', 'Shoes');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Social life', 'Presents');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Social life', 'Eating out');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Social life', 'Events and receptions');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Social life', 'Associations and clubs');
INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Social life', 'Cinemas and theatres');

INSERT INTO ops_expenditureCausals (expenditureItem, expenditureDetail) VALUE ('Charity', 'Donations');

COMMIT;

-- -----------------------------------------------------
-- Table cnf_directions
-- -----------------------------------------------------
DROP TABLE IF EXISTS cnf_directions;

CREATE TABLE IF NOT EXISTS cnf_directions (
	id INT NOT NULL COMMENT 'The actual transaction directions: -1, 0, or 1',
	direction VARCHAR(5) NULL DEFAULT NULL COMMENT 'The descriptions of transaction directions: income, no transaction, or outflow, respectively',
	synonym VARCHAR(7) NULL DEFAULT NULL COMMENT 'Any synonym for the transacion direction descriptions',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT cnf_directions_PK PRIMARY KEY directions_PK_indx (id),
	CONSTRAINT cnf_directions_UK UNIQUE KEY directions_UK_indx (direction ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Transaction directions';

CREATE UNIQUE INDEX synonym_UK ON cnf_directions (synonym ASC);
START TRANSACTION;

INSERT INTO cnf_directions (id, direction, synonym) VALUE (0, NULL, NULL);
INSERT INTO cnf_directions (id, direction, synonym) VALUE (-1, 'give', 'outflow');
INSERT INTO cnf_directions (id, direction, synonym) VALUE (1, 'have', 'income');

COMMIT;

-- -----------------------------------------------------
-- Table ops_communityAccountingPeriods
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communityAccountingPeriods;

CREATE TABLE IF NOT EXISTS ops_communityAccountingPeriods (
	id INT NOT NULL AUTO_INCREMENT,
	community VARCHAR(50) NOT NULL COMMENT "The community the accounting period refers to",
	startDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT "The starting date of an accounting period. Defaults to the current date",
	endDate DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP + 30) COMMENT "The end date of an accounting period. Defaults to 30 days after the starting date",
	initialBalance DECIMAL (11,3) NOT NULL DEFAULT 0 COMMENT "The accounting period initial balance",
	finalBalance DECIMAL (11,3) NULL DEFAULT NULL COMMENT "The accounting period final balance",
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communityAccountingPeriods_PK PRIMARY KEY ops_communityAccountingPeriods_PK_indx (id ASC),
	CONSTRAINT ops_communityAccountingPeriods_UK UNIQUE KEY ops_communityAccountingPeriods_UK_indx (community ASC, startDate ASC, endDate ASC),
	CONSTRAINT ops_communityAccountingPeriod_REFERSTO_ops_communities FOREIGN KEY ops_communityAccountingPeriod_REFERSTO_ops_communities_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Accounting periods riferred to the communities";

GRANT SELECT, UPDATE, INSERT, DELETE ON ops_communityAccountingPeriods TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT ON ops_communityAccountingPeriods TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_users
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_users;

CREATE TABLE IF NOT EXISTS ops_users (
	id INT NOT NULL AUTO_INCREMENT,
	username CHAR(32) NOT NULL DEFAULT '' COMMENT "The user's chosen username" COLLATE utf8_bin,
	hostname CHAR(255) NOT NULL DEFAULT '' COMMENT "The host to which the user is associated. Defaults to localhost." COLLATE ascii_general_ci,
	firstName VARCHAR(50) NULL DEFAULT NULL COMMENT "The user's first name and, if applicable, any middle names",
	familyName VARCHAR(75) NULL DEFAULT NULL COMMENT "The user's family name",
	email VARCHAR(100) NULL DEFAULT NULL COMMENT "Any valid user's email, also used for internal communication",
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT users_PK PRIMARY KEY users_PK_indx (id),
	CONSTRAINT users_UK UNIQUE KEY users_UK_indx (username ASC, hostname ASC),
	CONSTRAINT appUser_IS_DBMSUser FOREIGN KEY appUser_IS_DBMSUser_indx (hostname, username) REFERENCES mysql.user (Host, User) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'All the DB users';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_users TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (firstName, familyName, email) ON ops_users TO 'COMMUNITY MEMBER';

-- At the moment this is here. In a definitive version, though, the admin creation and registration shall be done as part of the installation process!!!!
INSERT INTO ops_users (username, hostname) VALUE ('piggybank_admin', '%');

-- -----------------------------------------------------
-- Table ops_userAccountingPeriods
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_userAccountingPeriods;

CREATE TABLE IF NOT EXISTS ops_userAccountingPeriods (
	id INT NOT NULL AUTO_INCREMENT,
	user INT NOT NULL COMMENT "The community the accounting period refers to",
	startDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT "The starting date of an accounting period. Defaults to the current date",
	endDate DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP + 30) COMMENT "The end date of an accounting period. Defaults to 30 days after the starting date",
	initialBalance DECIMAL (11,3) NOT NULL DEFAULT 0 COMMENT "The accounting period initial balance",
	finalBalance DECIMAL (11,3) NULL DEFAULT NULL COMMENT "The accounting period final balance",
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_userAccountingPeriods_PK PRIMARY KEY ops_userAccountingPeriods_PK_indx (id ASC),
	CONSTRAINT ops_userAccountingPeriods_UK UNIQUE KEY ops_userAccountingPeriods_UK_indx (user ASC, startDate ASC, endDate ASC),
	CONSTRAINT ops_userAccountingPeriod_REFERSTO_ops_users FOREIGN KEY ops_userAccountingPeriod_REFERSTO_ops_users_indx (user) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Accounting periods referred to the users";

GRANT SELECT ON ops_userAccountingPeriods TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, UPDATE, INSERT, DELETE ON ops_userAccountingPeriods TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communityMembers
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communityMembers;

CREATE TABLE IF NOT EXISTS ops_communityMembers (
	id INT NOT NULL AUTO_INCREMENT,
	community VARCHAR(50) NOT NULL COMMENT 'The community name',
	communityMember INT NOT NULL COMMENT "Every community member",
	weight DECIMAL(11,3) NOT NULL DEFAULT 1 COMMENT 'The weight the user expects to impose on the community',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communityMembers_PK PRIMARY KEY ops_communityMembers_PK_indx (id),
	CONSTRAINT ops_communityMembers_UK UNIQUE KEY ops_communityMembers_UK_indx (community ASC, id ASC),
	CONSTRAINT member_BELONGSTO_community FOREIGN KEY member_BELONGSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT community_HAS_member FOREIGN KEY community_HAS_member_indx (communityMember) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'The relationships among the users, the communities they belong to, their role within the community, and their expected weight on the community';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_communityMembers TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (weight) ON ops_communityMembers TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT, UPDATE (weight) ON ops_communityMembers TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_accounts
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_accounts;

CREATE TABLE IF NOT EXISTS ops_accounts (
	iban VARCHAR(27) NOT NULL COMMENT 'IBAN code',
	bic VARCHAR(25) NOT NULL COMMENT 'BIC / SWIFT code',
	bank VARCHAR(100) NULL DEFAULT NULL,
	initialBalance DECIMAL(11,3) NOT NULL DEFAULT 0 COMMENT 'The bank account initial balance',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT accounts_PK PRIMARY KEY accounts_PK_indx (iban),
	CONSTRAINT accounts_UK UNIQUE KEY accounts_UK_indx (bic)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Bank accounts list';

GRANT SELECT ON ops_accounts TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT ON ops_accounts TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_accounts TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_paymentInstrumentsTypes
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_paymentInstrumentsTypes;

CREATE TABLE IF NOT EXISTS ops_paymentInstrumentsTypes (
	type VARCHAR(25) NOT NULL COMMENT 'Payment instruments types, like: credit card, debit card, cheque, cash, ...',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_paymentInstrumentsTypes_PK PRIMARY KEY ops_paymentInstrumentsTypes_PK_indx (type)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Payment instruments types';

GRANT SELECT, INSERT ON ops_paymentInstrumentsTypes TO 'COMMUNITY MEMBER';

START TRANSACTION;

INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('cash');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('credit card');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('debit card');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('cheque');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('permanent bank transfer');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('bank transfer');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('credit transfer (giro)');
INSERT INTO ops_paymentInstrumentsTypes (type) VALUE ('other...');

COMMIT;

-- -----------------------------------------------------
-- Table ops_bankAccountHolders
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_bankAccountHolders;

CREATE TABLE IF NOT EXISTS ops_bankAccountHolders (
	id INT NOT NULL,
	bankAccount VARCHAR(27) NOT NULL COMMENT 'Bank account number',
	holder INT NOT NULL COMMENT 'Bank account holder',
	isOwner TINYINT NOT NULL DEFAULT 1  COMMENT 'Is the holder also the bank account owner?',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_bankAccountHolders_PK PRIMARY KEY ops_bankAccountHolders_PK_indx (id),
	CONSTRAINT ops_bankAccountHolders_UK UNIQUE KEY ops_bankAccountHolders_UK_indx (bankAccount ASC, holder ASC),
	CONSTRAINT holder_HOLDS_bankAccount FOREIGN KEY holder_HOLDS_bankAccount_indx (bankAccount) REFERENCES ops_accounts (iban) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT bankAccount_ISHELDBY_holder FOREIGN KEY bankAccount_ISHELDBE_holder (holder) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Relationships between bank accounts and their holders/owners';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_bankAccountHolders TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_paymentInstruments
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_paymentInstruments;

CREATE TABLE IF NOT EXISTS ops_paymentInstruments (
	id INT NOT NULL,
	bankAccount VARCHAR(27) NOT NULL,
	paymentInstrumentType VARCHAR(25) NOT NULL,
	serialNumber VARCHAR(25) NULL DEFAULT NULL,
	holder INT NULL DEFAULT NULL,
	dailyExpenditureCeiling DECIMAL NULL DEFAULT NULL,
	dailyWithdrawalCeiling DECIMAL NULL DEFAULT NULL,
	monthlyExpenditureCeiling DECIMAL NULL DEFAULT NULL,
	monthlyWithdrawalCeiling DECIMAL NULL DEFAULT NULL,
	firstAccountingDay INT NOT NULL DEFAULT 28,
	lastAccountingDay INT NOT NULL DEFAULT 27,
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_paymentInstruments_PK PRIMARY KEY ops_paymentInstruments_PK_indx (id),
	CONSTRAINT ops_paymentInstruments_UK UNIQUE KEY ops_paymentInstruments_UK_indx (bankAccount ASC, paymentInstrumentType ASC, holder ASC, serialNumber ASC),
	CONSTRAINT paymentInstrumentType_CHARGESON_bankAccount FOREIGN KEY paymentInstrumentType_CHARGESON_bankAccount_indx (bankAccount) REFERENCES ops_accounts (iban) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT holder_HOLDS_paymentInstrumentType FOREIGN KEY holder_HOLDS_paymentInstrumentType_indx (paymentInstrumentType) REFERENCES ops_paymentInstrumentsTypes (type) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT paymentInstrument_ISHELDBY_holder FOREIGN KEY paymentInstrument_ISHELDBY_holder_indx (holder) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Payment instruments associated to the bank accounts';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_paymentInstruments TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_paymentInstrumentsAccountingPeriods
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_paymentInstrumentsAccountingPeriods;

CREATE TABLE IF NOT EXISTS ops_paymentInstrumentsAccountingPeriods (
	id INT NOT NULL AUTO_INCREMENT,
	paymentInstrument INT NOT NULL COMMENT "The payment instrument the accounting period refers to",
	startDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT "The starting date of an accounting period. Defaults to the current date",
	endDate DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP + 30) COMMENT "The end date of an accounting period. Defaults to 30 days after the starting date",
	initialBalance DECIMAL (11,3) NOT NULL DEFAULT 0 COMMENT "The accounting period initial balance",
	finalBalance DECIMAL (11,3) NULL DEFAULT NULL COMMENT "The accounting period final balance",
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_paymentInstrumentsAccountingPeriods_PK PRIMARY KEY ops_paymentInstrumentsAccountingPeriods_PK_indx (id ASC),
	CONSTRAINT ops_paymentInstrumentsAccountingPeriods_UK UNIQUE KEY ops_paymentInstrumentsAccountingPeriods_UK_indx (paymentInstrument ASC, startDate ASC, endDate ASC),
	CONSTRAINT ops_AccountingPeriod_REFERSTO_ops_paymentInstruments FOREIGN KEY ops_AccountingPeriod_REFERSTO_ops_paymentInstrument_indx (paymentInstrument) REFERENCES ops_paymentInstruments (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Accounting periods refered to the payment instruments";

GRANT SELECT ON ops_communityAccountingPeriods TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, UPDATE, INSERT, DELETE ON ops_communityAccountingPeriods TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_activities
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_activities;

CREATE TABLE IF NOT EXISTS ops_activities (
	id INT NOT NULL,
	community VARCHAR(25) NOT NULL COMMENT 'The community name',
	activity VARCHAR(50) NOT NULL COMMENT 'An illustrative, short name for a community activity',
	isProject TINYINT NOT NULL DEFAULT 1 COMMENT 'Is the activity still a project? Meaning: is it funded (activity) or just an intent (project)?',
	description MEDIUMTEXT NULL DEFAULT NULL COMMENT 'A verbose description of the activity or project',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_activities_PK PRIMARY KEY ops_activities_PK_indx (id),
	CONSTRAINT ops_activities_UK UNIQUE KEY acitivities_UK_indx (community ASC, activity ASC),
	CONSTRAINT community_HAS_activities FOREIGN KEY community_HAS_activities_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Community ops_activities and projects';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_activities TO 'COMMUNITY ADMINISTRATOR';
GRANT SELECT, INSERT, UPDATE (community) ON ops_activities TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT, UPDATE (activity, isProject, description) ON ops_activities TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_transactions
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_transactions;

CREATE TABLE IF NOT EXISTS ops_transactions (
	id INT NOT NULL,
	paymentInstrument INT NOT NULL COMMENT 'The payment istrument that was charged',
	date DATE NULL DEFAULT NULL COMMENT 'The transaction date',
	amount DECIMAL NOT NULL COMMENT 'The transaction amount',
	direction INT NOT NULL DEFAULT -1 COMMENT 'The transaction direction',
	expenditureCausal INT NOT NULL COMMENT 'The transaction causal',
	commentary TEXT NULL DEFAULT NULL COMMENT "A verbose description of the transaction, if appropriate",
	isPrivate TINYINT NOT NULL DEFAULT 0 COMMENT "Indication whether the transaction is private or communal. Defaults to communal (FALSE)",
	activity INT NULL DEFAULT NULL COMMENT "Reference to the activity or project the transaction shall be accounted against",
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_transactions_PK PRIMARY KEY ops_transactions_PK_indx (id),
	CONSTRAINT ops_transactions_UK UNIQUE KEY (paymentInstrument ASC, date ASC, amount ASC, direction ASC, expenditureCausal),
	CONSTRAINT transaction_ISCHARGEDTO_paymentInstrument FOREIGN KEY transaction_ISCHARGEDTO_paymentInstrument_indx (paymentInstrument) REFERENCES ops_paymentInstruments (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT transaction_HAS_direction FOREIGN KEY transaction_HAS_direction_indx (direction) REFERENCES cnf_directions (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT transaction_HAS_causal FOREIGN KEY transaction_HAS_causal_indx (expenditureCausal) REFERENCES ops_expenditureCausals (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT transaction_ISACCOUNTEDAGAINST_activity FOREIGN KEY transaction_ISACCOUNTEDAGAINST_activity_indx (activity) REFERENCES ops_activities (id)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Transactions list';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_transactions TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_paymentInstrumentsBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_paymentInstrumentsBalance;

CREATE TABLE IF NOT EXISTS ops_paymentInstrumentsBalance (
	id INT NOT NULL AUTO_INCREMENT,
	paymentInstrument INT NOT NULL COMMENT 'The payment instrument the balance refers to',
	accountingPeriod INT NOT NULL COMMENT 'The payment instrument the balance refers to',
	initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
	income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
	outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
	finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_paymentInstrumentsBalance_PK PRIMARY KEY ops_paymentInstrumentsBalance_PK_indx (id),
	CONSTRAINT ops_paymentInstrumentsBalance_UK UNIQUE KEY ops_paymentInstrumentsBalance_UK_indx (paymentInstrument ASC, accountingPeriod ASC),
	CONSTRAINT piBalance_REFERSTO_paymentInstrument FOREIGN KEY piBalance_REFERSTO_paymentInstrument_indx (paymentInstrument) REFERENCES ops_paymentInstruments (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT piBalance_REFERSTO_accountingPeriod FOREIGN KEY piBalance_REFERSTO_accountingPeriod_indx (accountingPeriod) REFERENCES ops_userAccountingPeriods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Each payment instrument periodical balance';

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_paymentInstrumentsBalance TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_userBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_userBalance;

CREATE TABLE IF NOT EXISTS ops_userBalance (
	id INT NOT NULL AUTO_INCREMENT,
	user INT NOT NULL COMMENT 'The user the balance refers to',
	accountingPeriod INT NOT NULL COMMENT "The user's accounting period the balance refers to",
	initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
	income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
	outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
	finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_userBalance_PK PRIMARY KEY ops_userBalance_PK_indx (id),
	CONSTRAINT ops_userBalance_UK UNIQUE KEY ops_userBalance_UK_indx (user ASC, accountingPeriod ASC),
	CONSTRAINT balance_REFERSTO_user FOREIGN KEY balance_REFERSTO_user_indx (user) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT userBalance_REFERSTO_accountingPeriod FOREIGN KEY userBalance_REFERSTO_accountingPeriod_indx (accountingPeriod) REFERENCES ops_userAccountingPeriods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each user's periodical balance";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_userBalance TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communityBalance
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communityBalance;

CREATE TABLE IF NOT EXISTS ops_communityBalance (
	id INT NOT NULL AUTO_INCREMENT,
	community VARCHAR(25) NOT NULL COMMENT 'The community the balance refers to',
	accountingPeriod INT NOT NULL COMMENT 'The community accounting period each balance refers to',
	initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The balance on the intial accountig date. Assumed 0 as default',
	income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
	outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
	finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall balance, determined as the initial balance plus the overall income minus the overall outflow',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communityBalance_PK PRIMARY KEY ops_communityBalance_PK_indx (id),
	CONSTRAINT ops_communityBalance_UK UNIQUE KEY ops_communityBalance_UK_indx (community ASC, accountingPeriod ASC),
	CONSTRAINT communityBalance_REFERSTO_community FOREIGN KEY communityBalance_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT communityBalance_REFERSTO_accountingPeriod FOREIGN KEY communityBalance_REFERSTO_accountingPeriod_indx (accountingPeriod) REFERENCES ops_communityAccountingPeriods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each community periodical balance";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_communityBalance TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT ON ops_communityBalance TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communityEstimates
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_userEstimates;

CREATE TABLE IF NOT EXISTS ops_userEstimates (
	id INT NOT NULL AUTO_INCREMENT,
	user INT NOT NULL COMMENT 'The user the estimate refers to',
	accountingPeriod INT NOT NULL COMMENT 'The community accounting period each estimate refers to',
	initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The estimate on the initial accounting date. Assumed 0 as default',
	income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
	outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
	finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall estimate, determined as the initial estimate plus the overall income minus the overall outflow',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_userEstimates_PK PRIMARY KEY ops_userEstimates_PK_indx (id),
	CONSTRAINT ops_userEstimates_UK UNIQUE KEY ops_userEstimates_UK_indx (user ASC, accountingPeriod ASC),
	CONSTRAINT userEstimate_REFERSTO_user FOREIGN KEY userEstimate_REFERSTO_user_indx (user) REFERENCES ops_users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT userEstimate_REFERSTO_accountingPeriod FOREIGN KEY userEstimate_REFERSTO_accountingPeriod_indx (accountingPeriod) REFERENCES ops_communityAccountingPeriods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each community periodical estimate";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_userEstimates TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT ON ops_userEstimates TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communityEstimates
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communityEstimates;

CREATE TABLE IF NOT EXISTS ops_communityEstimates (
	id INT NOT NULL AUTO_INCREMENT,
	community VARCHAR(25) NOT NULL COMMENT 'The community the estimate refers to',
	accountingPeriod INT NOT NULL COMMENT 'The community accounting period each estimate refers to',
	initialBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The estimate on the initial accounting date. Assumed 0 as default',
	income DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period averall income',
	outflow DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall outflow',
	finalBalance DECIMAL NOT NULL DEFAULT 0 COMMENT 'The period overall estimate, determined as the initial estimate plus the overall income minus the overall outflow',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communityEstimates_PK PRIMARY KEY ops_communityEstimates_PK_indx (id),
	CONSTRAINT ops_communityEstimates_UK UNIQUE KEY ops_communityEstimates_UK_indx (community ASC, accountingPeriod ASC),
	CONSTRAINT communityEstimate_REFERSTO_community FOREIGN KEY communityEstimate_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT communityEstimate_REFERSTO_accountingPeriod FOREIGN KEY communityEstimate_REFERSTO_accountingPeriod_indx (accountingPeriod) REFERENCES ops_communityAccountingPeriods (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Each community periodical estimate";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_communityEstimates TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT ON ops_communityEstimates TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table conf_deadlineRepetitions
-- -----------------------------------------------------
DROP TABLE IF EXISTS cnf_deadlineRepetitions;

CREATE TABLE IF NOT EXISTS cnf_deadlineRepetitions (
	repetition VARCHAR(25) NOT NULL COMMENT 'An intuitive name',
	nrOfDays INT NOT NULL DEFAULT 0 COMMENT 'The time interval between two subsequent occurrences, in days',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT cnf_deadlineRepetions_PK PRIMARY KEY cnf_deadlineRepetitions_PK_indx (repetition)
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT 'A list of commonly used repetition intervals';

GRANT SELECT ON cnf_deadlineRepetitions TO 'COMMUNITY MEMBER';

START TRANSACTION;

INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('daily', 1);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('weekly', 7);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('bi-weekly', 14);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('monthly', 30);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('bi-monthly', 60);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('quarterly', 90);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('every 4 months', 120);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('every 6 months', 180);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('yearly', 365);
INSERT INTO cnf_deadlineRepetitions (repetition, nrOfDays) VALUE ('every 2 years', 730);

COMMIT;

-- -----------------------------------------------------
-- Table ops_userDeadlines
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_userDeadlines;

CREATE TABLE IF NOT EXISTS ops_userDeadlines (
	id INT NOT NULL AUTO_INCREMENT,
	user INT NOT NULL COMMENT "The reference to a user",
	deadline DATE NULL DEFAULT NULL COMMENT 'A user deadline',
	amount DECIMAL NOT NULL DEFAULT 0 COMMENT 'The expected amount of the transaction',
	direction INT NOT NULL DEFAULT -1 COMMENT 'The transaction direction',
	expenditureCausal INT NOT NULL COMMENT 'The transaction causal',
	commentary TEXT NULL DEFAULT NULL COMMENT 'A verbose descritpion of the transaction, if appropriate',
	activity INT NULL DEFAULT NULL COMMENT 'Any activity or project the transaction may accounted against',
	isRepeatable TINYINT NOT NULL DEFAULT 0 COMMENT 'Indicates whether the deadline repaeats regularly over time',
	repetition VARCHAR(25) NULL DEFAULT NULL COMMENT 'Indicates the time lapse between two occurences of the same repetition series',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_userDeadlines_PK PRIMARY KEY ops_userDeadlines_PK_indx (id),
	CONSTRAINT ops_userDeadlines_UK UNIQUE KEY (deadline ASC, amount ASC, direction ASC, expenditureCausal),
	CONSTRAINT userDeadline_REFERSTO_user FOREIGN KEY userDeadline_REFERSTO_user_indx (user) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT userDeadline_HAS_direction FOREIGN KEY userDeadline_HAS_direction_indx (direction) REFERENCES cnf_directions (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT userDeadline_HAS_causal FOREIGN KEY userDeadline_HAS_causal_indx (expenditureCausal) REFERENCES ops_expenditureCausals (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT userDeadline_ISACCOUNTEDAGAINST_activity FOREIGN KEY userDeadline_ISACCOUNTEDAGAINST_activity_indx (activity) REFERENCES ops_activities (id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT userDeadline_REPEATSEVERY_repetition FOREIGN KEY userDeadline_REPEATSEVERY_repetition_indx (repetition) REFERENCES cnf_deadlineRepetitions (repetition) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Community deadlines";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_userDeadlines TO 'COMMUNITY MEMBER';
GRANT SELECT ON ops_userDeadlines TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table ops_communityDeadlines
-- -----------------------------------------------------
DROP TABLE IF EXISTS ops_communityDeadlines;

CREATE TABLE IF NOT EXISTS ops_communityDeadlines (
	id INT NOT NULL AUTO_INCREMENT,
	community VARCHAR(25) NOT NULL COMMENT 'The community the deadline refers to',
	deadline DATE NULL DEFAULT NULL COMMENT 'A community deadline',
	amount DECIMAL NOT NULL DEFAULT 0 COMMENT 'The expected amount of the transaction',
	direction INT NOT NULL DEFAULT -1 COMMENT 'The transaction direction',
	expenditureCausal INT NOT NULL COMMENT 'The transaction causal',
	commentary TEXT NULL DEFAULT NULL COMMENT 'A verbose description of the transaction, if appropriate',
	activity INT NULL DEFAULT NULL COMMENT 'Any activity or project the transaction may accounted against',
	isRepeatable TINYINT NOT NULL DEFAULT 0 COMMENT 'Indicates whether the deadline repaeats regularly over time',
	repetition VARCHAR(25) NULL DEFAULT NULL COMMENT 'Indicates the time lapse between two occurences of the same repetition series',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT ops_communityDeadlines_PK PRIMARY KEY ops_communityDeadlines_PK_indx (id),
	CONSTRAINT ops_communityDeadlines_UK UNIQUE KEY (deadline ASC, amount ASC, direction ASC, expenditureCausal),
	CONSTRAINT communityDeadline_REFERSTO_community FOREIGN KEY communityDeadline_REFERSTO_community_indx (community) REFERENCES ops_communities (community) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT communityDeadline_HAS_direction FOREIGN KEY communityDeadline_HAS_direction_indx (direction) REFERENCES cnf_directions (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT communityDeadline_HAS_causal FOREIGN KEY communityDeadline_HAS_causal_indx (expenditureCausal) REFERENCES ops_expenditureCausals (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT communityDeadline_ISACCOUNTEDAGAINST_activity FOREIGN KEY communityDeadline_ISACCOUNTEDAGAINST_activity_indx (activity) REFERENCES ops_activities (id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT communityDeadline_REPEATSEVERY_repetition FOREIGN KEY communityDeadline_REPEATSEVERY_repetition_indx (repetition) REFERENCES cnf_deadlineRepetitions (repetition) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "Community deadlines";

GRANT SELECT, INSERT, UPDATE, DELETE ON ops_communityDeadlines TO 'COMMUNITY ACCOUNTANT';
GRANT SELECT, INSERT ON ops_communityDeadlines TO 'COMMUNITY MEMBER';

-- -----------------------------------------------------
-- Table log_activityLog
-- -----------------------------------------------------
DROP TABLE IF EXISTS log_activityLog;

CREATE TABLE IF NOT EXISTS log_activityLog (
	id INT NOT NULL AUTO_INCREMENT,
	time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The event time reference',
	user INT NOT NULL COMMENT "The user's reference",
	remoteIPAddress VARCHAR(46) NOT NULL DEFAULT '::ffff:127.0.0.1' COMMENT "The user's IP address, in either IPv4 or IPv6 notation. In case the user connects through a proxy, the proxy IP address.",
	action VARCHAR (512) NOT NULL COMMENT 'A concise description of the action',
	detail TEXT NULL DEFAULT NULL COMMENT 'A verbose description of the action,if appropriate',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT log_activityLog_PK PRIMARY KEY log_activityLog_PK_indx (id ASC),
	CONSTRAINT log_activityLog_PK UNIQUE KEY log_activityLog_UK_indx (time ASC, user ASC, action ASC),
	CONSTRAINT activity_PERFORMEDBY_user FOREIGN KEY activity_PERFORMEDBY_user_indx (user) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT 'The application activity log';

-- -----------------------------------------------------
-- Table cnf_PHPErrorLevels
-- -----------------------------------------------------
DROP TABLE IF EXISTS cnf_PHPErrorLevels ;

CREATE TABLE IF NOT EXISTS cnf_PHPErrorLevels (
  PHPErrorCode INT NOT NULL,
  PHPErrorLevel VARCHAR(25) NOT NULL,
  PHPErrorDescription VARCHAR(255) NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  CONSTRAINT PHPErrorLevels_PK PRIMARY KEY PHPErrorLevels_PK_indx (PHPErrorCode ASC),
  CONSTRAINT PHPErrorLevels_UK UNIQUE KEY PHPErrorLevels_UK_indx (PHPerrorLevel ASC)
) ENGINE = InnoDB  DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = 'Error levels and related codes as defined by PHP (7.3 taken as a reference)';

START TRANSACTION;

INSERT INTO cnf_PHPErrorLevels (PHPErrorCode, PHPErrorLevel, PHPErrorDescription) VALUES
	(1, 'E_ERROR', "A fatal run-time error, that can't be recovered from. The execution of the script is stopped immediately."),
	(2, 'E_WARNING', "A run-time warning. It is non-fatal and most errors tend to fall into this category. The execution of the script is not stopped."),
	(4, 'E_PARSE', "The compile-time parse error. Parse errors should only be generated by the parser."),
	(8, 'E_NOTICE', "A run-time notice indicating that the script encountered something that could possibly an error, although the situation could also occur when running a script normally."),
	(16, 'E_CORE_ERROR', "A fatal error that occur during the PHP's engine initial startup. This is like an E_ERROR, except it is generated by the core of PHP."),
	(32, 'E_CORE_WARNING', "A non-fatal error that occur during the PHP's engine initial startup. This is like an E_WARNING, except it is generated by the core of PHP."),
	(64, 'E_COMPILE_ERROR', "A fatal error that occur while the script was being compiled. This is like an E_ERROR, except it is generated by the Zend Scripting Engine."),
	(128, 'E_COMPILE_WARNING', "A non-fatal error occur while the script was being compiled. This is like an E_WARNING, except it is generated by the Zend Scripting Engine."),
	(256, 'E_USER_ERROR', "A fatal user-generated error message. This is like an E_ERROR, except it is generated by the PHP code using the function trigger_error() rather than the PHP engine."),
	(512, 'E_USER_WARNING', "A non-fatal user-generated warning message. This is like an E_WARNING, except it is generated by the PHP code using the function trigger_error() rather than the PHP engine"),
	(1024, 'E_USER_NOTICE', "A user-generated notice message. This is like an E_NOTICE, except it is generated by the PHP code using the function trigger_error() rather than the PHP engine."),
	(2048, 'E_STRICT', "Not strictly an error, but triggered whenever PHP encounters code that could lead to problems or forward incompatibilities"),
	(4096, 'E_RECOVERABLE_ERROR', "A catchable fatal error. Although the error was fatal, it did not leave the PHP engine in an unstable state. If the error is not caught by a user defined error handler (see set_error_handler()), the application aborts as it was an E_ERROR."),
	(8192, 'E_DEPRECATED', "A run-time notice indicating that the code will not work in future versions of PHP"),
	(16384, 'E_USER_DEPRECATED', "A user-generated warning message. This is like an E_DEPRECATED, except it is generated by the PHP code using the function trigger_error() rather than the PHP engine."),
	(32767, 'E_ALL', "All errors and warnings, except of level E_STRICT prior to PHP 5.4.0.");

COMMIT;

-- -----------------------------------------------------
-- Table log_errorLog
-- -----------------------------------------------------
DROP TABLE IF EXISTS log_errorLog;

CREATE TABLE IF NOT EXISTS log_errorLog (
	id INT NOT NULL AUTO_INCREMENT,
	gdo TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The event time reference',
	user INT NOT NULL COMMENT "The user's reference",
	remoteIPAddress VARCHAR(46) NOT NULL DEFAULT '::ffff:127.0.0.1' COMMENT "The user's IP address, in either IPv4 or IPv6 notation. In case the user connects through a proxy, the proxy IP address.",
	errorMessage VARCHAR (255) NOT NULL COMMENT 'The PHP generated error message',
	errorCode INT NOT NULL DEFAULT 0 COMMENT 'The PHP generated error code',
	errorSeverity INT NOT NULL DEFAULT 1 COMMENT 'The PHP reported error severity',
	errorFile VARCHAR(255) NULL DEFAULT NULL COMMENT 'The path to the file where the error or exception was thrown',
	errorLine INT NULL DEFAULT NULL COMMENT 'The line where the error or exception was thrown',
	created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
	lastModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
	CONSTRAINT log_errorLog_PK PRIMARY KEY log_errorLog_PK_indx (id),
	CONSTRAINT log_errorLog_UK UNIQUE KEY log_errorLog_UK_indx (gdo ASC, user ASC, remoteIPAddress ASC),
	CONSTRAINT error_GENERATEDBY_user FOREIGN KEY error_GENERATEDBY_user_indx (user) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT error_HAS_severity FOREIGN KEY error_HAS_severity_indx (errorCode) REFERENCES cnf_PHPErrorLevels (PHPErrorCode) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin COMMENT = "The log of the execution time errors as generated by PHP scripts";
