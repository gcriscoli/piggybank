CREATE TABLE IF NOT EXISTS test (
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	nome VARCHAR (25) NULL DEFAULT NULL,
	cognome VARCHAR(25) NOT NULL,
	cf VARCHAR (16) NOT NULL
) ENGINE = InnoDB DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_bin;

INSERT INTO test (nome, cognome, cf) VALUES
	('Giulio', 'Criscoli', 'CRSGLI73E07G224Q'),
	('Maria Irene', 'Satariano', 'STRMRN66E59G273X'),
	('Umberto', 'Criscoli', '1234567890ABCDEF'),
	('Carla', 'Criscoli', '1234567890ABCDEF'),
	('Leonardo', 'Criscoli', '1234567890ABCDEF');


