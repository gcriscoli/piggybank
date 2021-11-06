CREATE TABLE IF NOT EXISTS iso3166_political_entities (
	id INT NOT NULL AUTO_INCREMENT COMMENT "Artificial primary key",
	iso3166_1_alpha2_code VARCHAR(2) NOT NULL COMMENT "ISO 3166-1 2 letter Country code",
    iso3166_1_alpha3_code VARCHAR(3) NOT NULL COMMENT "ISO 3166-1 3 letter Country code",
    iso3166_1_numeric_code VARCHAR(3) NOT NULL COMMENT "ISO 3166-1 3 digit Country code",
	iso3166_2_alphanumeric_code VARCHAR(3) NULL DEFAULT NULL COMMENT "ISO 3166-2 3 alphanumeric signs Country internal subdivision code. It only applies to officially ISO 3166 registered Country internal political or administrative subdivisions",
	iso3166_complete_code VARCHAR(16) NULL DEFAULT NULL COMMENT "ISO 3166 complete (-1 and -2, as applicable) Country or internal subdivision code",
	common_name VARCHAR(75) NOT NULL COMMENT "ISO 3166 registered political or administrative entity common name; the name by which a political or administrative entity is commonly known",
	official_name VARCHAR (200) NOT NULL COMMENT "ISO 3166 registered political or administrative entity official name",
	local_name VARCHAR (80) NULL DEFAULT NULL COMMENT "ISO 3166 registered political or administrative entity local name",
	local_variant VARCHAR (50) NULL DEFAULT NULL COMMENT "ISO 3166 registered political or administrative entity name local variant, if any",
	parent_pe INT NULL DEFAULT NULL COMMENT "Reference to the ISO 3166 parent political entity",
	pe_category VARCHAR (50) NULL DEFAULT 'COUNTRY' COMMENT "ISO 3166 political or administrative entity category",
	sovereignty VARCHAR(25) NULL DEFAULT NULL COMMENT "ISO 3166 sovereignty",
	INDEX iso3166_1_alpha2_code_indx (iso3166_1_alpha2_code ASC),
	INDEX iso3166_1_alpha3_code_indx (iso3166_1_alpha3_code ASC),
	INDEX iso3166_1_numeric_code_indx (iso3166_1_numeric_code ASC),
	INDEX iso3166_2_alphanumeric_code_index (iso3166_2_alphanumeric_code ASC),
	INDEX iso3166_complete_code_indx (iso3166_complete_code ASC),
	CONSTRAINT iso3166_political_entities_pk PRIMARY KEY iso3166_political_entities_pk_indx (id ASC),
	CONSTRAINT iso3166_political_entities_uk UNIQUE KEY iso3166_political_entities_uk_indx (iso3166_1_alpha2_code ASC, iso3166_2_alphanumeric_code ASC),
	CONSTRAINT parent_pe_fk FOREIGN KEY parent_pe_fk_indx (parent_pe ASC) REFERENCES iso3166_political_entities (id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT sovereignty_fk FOREIGN KEY sovereignty_fk_indx (sovereignty ASC) REFERENCES sovereignties (sovereignty)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 DEFAULT COLLATE = utf8mb4_general_ci COMMENT = "ISO 3166 Country and Country subdivisions list, amended with ISO 4217 currencies and ITU international dialling codes"