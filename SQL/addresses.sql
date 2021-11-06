DROP DATABASE IF EXISTS addresses;

CREATE DATABASE IF NOT EXISTS addresses;

USE addresses;

CREATE TABLE IF NOT EXISTS sovereignties (
	sovereignty VARCHAR (25) NOT NULL DEFAULT 'UN member state' COMMENT 'Sovereignty as recognized by the ISO 3166-1 Maintenance Agency',
	CONSTRAINT sovereignties_pk PRIMARY KEY sovereignties_pk_indx (sovereignty ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = 'ISO 3166-1 sovereignties';

CREATE TABLE IF NOT EXISTS tlds (
	tld VARCHAR(25) NOT NULL COMMENT 'ISO 3166-1 Country code Top Level Domains',
	description VARCHAR(255) NULL DEFAULT NULL COMMENT 'Short descritpion, if necessary, of the TLD',
	CONSTRAINT tlds_pk PRIMARY KEY tld_pk_indx (tld ASC)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = 'ISO 3166-1 Country code Top Level Domains';

INSERT INTO tlds (tld, description) VALUE ('N/I', 'NOT IMPLEMENTED');

CREATE TABLE IF NOT EXISTS countries (
	country_name VARCHAR(255) NOT NULL COMMENT 'Common country name' COLLATE utf8mb4_general_ci,
	official_state_name VARCHAR(255) NOT NULL COMMENT 'Official State name, as recognized by the ISO 3166 Maintenance Agency',
	sovereignty VARCHAR(25) NULL DEFAULT 'UN member state',
	alpha2 VARCHAR (2) NOT NULL COMMENT 'ISO 3166-1 2 letter Country code',
	alpha3 VARCHAR (3) NOT NULL COMMENT 'ISO 3166-1 3 letter Country code',
	num3 VARCHAR (3) NOT NULL COMMENT 'ISO 3166-1 3 digit Country code',
	CONSTRAINT countries_pk PRIMARY KEY countries_pk_indx (alpha2 ASC),
	CONSTRAINT countries_alpha2_uk UNIQUE KEY countries_alpha2_uk_indx (alpha2 ASC),
	CONSTRAINT countries_alpha3_uk UNIQUE KEY countries_alpha3_uk_indx (alpha3 ASC),
	CONSTRAINT countries_sovereignty_fk FOREIGN KEY countries_sovereignty_fk_indx (sovereignty) REFERENCES sovereignties (sovereignty) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = 'ISO 3166 Country Codes';

CREATE TABLE IF NOT EXISTS country_code_tlds (
	id INT NOT NULL AUTO_INCREMENT,
	country VARCHAR (2) NOT NULL COMMENT 'ISO 3166-1 2 letter Country code',
	cctld VARCHAR (25) NULL DEFAULT 'N/I' COMMENT 'ISO 3166-1 Country code Top Level Domain',
	CONSTRAINT country_code_tlds_pk PRIMARY KEY country_code_tlds_pk_indx (id),
	CONSTRAINT country_code_tlds_uk UNIQUE KEY country_code_tlds_uk_indx (country ASC, cctld ASC),
	CONSTRAINT cctld_belongsto_country FOREIGN KEY cctld_belongsto_country_indx (country) REFERENCES countries (alpha2) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT country_has_cctld FOREIGN KEY country_has_cctld_indx (cctld) REFERENCES tlds (tld) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = 'List of Countries and of their cctlds';

CREATE TABLE IF NOT EXISTS country_subdivisions (
	id INT NOT NULL AUTO_INCREMENT,
	country VARCHAR(2) NULL DEFAULT NULL COMMENT 'ISO 3166-1 2 letter Country code',
	alpha2 VARCHAR (2) NOT NULL COMMENT 'ISO 3166-2 2 character subdivision code',
	official_subdivision_name VARCHAR (255) NOT NULL COMMENT 'ISO 3166-2 region name',
	super_division VARCHAR (2) NULL DEFAULT NULL COMMENT 'Identifier of the region the subregion belongs to',
	INDEX alpha2_indx (alpha2 ASC),
	CONSTRAINT country_subdivisions_pk PRIMARY KEY country_subdivisions_pk_indx (id),
	CONSTRAINT country_subdivision_code_uk UNIQUE KEY country_subdivision_code_uk_indx (country ASC, alpha2 ASC),
	CONSTRAINT country_subdivision_name_uk UNIQUE KEY country_subdivision_name_uk_indx (country ASC, official_subdivision_name ASC),
	CONSTRAINT subdivision_belongsto_country_fk FOREIGN KEY subdivision_belongsto_country_fk_idx (country) REFERENCES countries (alpha2) ON DELETE NO ACTION ON UPDATE CASCADE,
	CONSTRAINT subdivision_belongsto_subdivision_fk FOREIGN KEY subdivision_belongsto_subdivisiono_fk_indx (super_division) REFERENCES country_subdivisions (alpha2) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT 'Country official subdivisions as recognized and encoded by the ISO 3166-2 Maintaining Agency';

CREATE TABLE IF NOT EXISTS addresses (
	id INT NOT NULL AUTO_INCREMENT,
	street_suffix VARCHAR(25) NOT NULL COMMENT 'Street suffix',
	street_name VARCHAR(255) NOT NULL COMMENT 'Street name',
	street_number VARCHAR (25) NOT NULL COMMENT 'Street number',
	zip_code VARCHAR (5) NOT NULL COMMENT 'ZIP code',
	town VARCHAR (255) NOT NULL COMMENT 'Town',
	province VARCHAR (255) NOT NULL COMMENT 'Province',
	country VARCHAR (2) NOT NULL COMMENT 'State',
	CONSTRAINT addresses_pk PRIMARY KEY addresses_pk_indx (id),
	CONSTRAINT addresses_uk UNIQUE KEY addresses_uk_indx (country ASC, province ASC, street_suffix ASC, street_name ASC, street_number ASC),
	CONSTRAINT isin_country_fk FOREIGN KEY isin_country_fk_indx (country) REFERENCES countries (alpha2) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = 'Addresses';
