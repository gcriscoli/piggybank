SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `piggybank`
--
CREATE DATABASE IF NOT EXISTS `piggybank` DEFAULT CHARACTER SET latin1 COLLATE latin1_bin;
USE `piggybank`;

-- --------------------------------------------------------

--
-- Struttura della tabella `directions`
--
-- Creazione: Gen 21, 2021 alle 08:34
--

DROP TABLE IF EXISTS `directions`;
CREATE TABLE IF NOT EXISTS `directions` (
  `id` int NOT NULL COMMENT 'The actual transaction directions: -1, 0, or 1',
  `direction` varchar(5) COLLATE latin1_bin DEFAULT NULL COMMENT 'The descriptions of transaction directions: income, no transaction, or outflow, respectively',
  `synonym` varchar(7) COLLATE latin1_bin DEFAULT NULL COMMENT 'Any synonym for the transacion direction descriptions',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
  `lastModified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  CONSTRAINT `directions_PK` PRIMARY KEY `directions_PK_indx` (`id` ASC),
  CONSTRAINT `directions_UK` UNIQUE KEY `directions_UK_indx` (`direction` ASC),
  CONSTRAINT `directions_syn_UK` UNIQUE KEY `directions_syn_UK_indx` (`synonym` ASC)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='Transaction directions';

--
-- Svuota la tabella prima dell'inserimento `directions`
--

TRUNCATE TABLE `directions`;
--
-- Dump dei dati per la tabella `directions`
--

INSERT DELAYED IGNORE INTO `directions` (`id`, `direction`, `synonym`, `created`, `lastModified`) VALUES
(-1, 'give', 'outflow', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(0, NULL, NULL, '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(1, 'have', 'income', '2021-01-21 08:34:22', '2021-01-21 08:34:22');

-- --------------------------------------------------------

--
-- Struttura della tabella `expenditureDetails`
--
-- Creazione: Gen 21, 2021 alle 08:34
--

DROP TABLE IF EXISTS `expenditureDetails`;
CREATE TABLE IF NOT EXISTS `expenditureDetails` (
  `expenditureDetail` varchar(50) COLLATE latin1_bin NOT NULL COMMENT 'Invoices to account expenses against',
  `community` varchar(50) COLLATE latin1_bin NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure invoice is related',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
  `lastModified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  PRIMARY KEY (`expenditureDetail`),
  KEY `expenditureDetail_REFERSTO_community` (`community`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='List of expenditure invoices';

--
-- Svuota la tabella prima dell'inserimento `expenditureDetails`
--

TRUNCATE TABLE `expenditureDetails`;
--
-- Dump dei dati per la tabella `expenditureDetails`
--

INSERT DELAYED IGNORE INTO `expenditureDetails` (`expenditureDetail`, `community`, `created`, `lastModified`) VALUES
('Accomodation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Associations and clubs', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Backery, grocery, green grocery, ...', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Books', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Cinemas and theatres', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Clothes', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Commissions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Condominium fees', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Dental care', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Donations', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Drugs', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Eating out', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Electricity', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Equipment, gear and outfit', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Events and receptions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Field trips', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Fuel', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Garbage disposal', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Gas', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Health insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Hospitalization', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Internet', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Libraries', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Long term leasing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Maintenance and repair', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Medical care', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Mobile phone', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Mortgage', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Museums', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Photocopies, handouts, ...', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Physical examination', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Practitioners and specialists', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Presents', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Professional order', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Property tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Public transportation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Purchase', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Redecoration', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Refurbishing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Registration fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Renovation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Rental', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Reservations', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Retirement fund', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Road tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Servicing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Shoes', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Standardization and law compliance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Stationery', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Supermarket', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Tax returns', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Taxes and other fees', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Technical inspection', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Telephone', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Tickets', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Travel guides', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Tuition fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Visits', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Water', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22');

-- --------------------------------------------------------

--
-- Struttura della tabella `expenditureItems`
--
-- Creazione: Gen 21, 2021 alle 08:34
--

DROP TABLE IF EXISTS `expenditureItems`;
CREATE TABLE IF NOT EXISTS `expenditureItems` (
  `expenditureItem` varchar(25) COLLATE latin1_bin NOT NULL COMMENT 'Expenditure items',
  `community` varchar(50) COLLATE latin1_bin NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure item is related',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
  `lastModified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  PRIMARY KEY (`expenditureItem`),
  KEY `expenditureItem_REFERSTO_community` (`community`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='List of expenditure items';

--
-- Svuota la tabella prima dell'inserimento `expenditureItems`
--

TRUNCATE TABLE `expenditureItems`;
--
-- Dump dei dati per la tabella `expenditureItems`
--

INSERT DELAYED IGNORE INTO `expenditureItems` (`expenditureItem`, `community`, `created`, `lastModified`) VALUES
('Bills', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Charity', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Clothing and outfit', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Daily shopping', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Education', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Home', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Leisure and recreation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Medical', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Social life', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Sports', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Taxes', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Travels & Holidays', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
('Vehicles', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22');

-- --------------------------------------------------------

--
-- Struttura della tabella `expenditureCausals`
--
-- Creazione: Gen 21, 2021 alle 08:34
--

DROP TABLE IF EXISTS `expenditureCausals`;
CREATE TABLE IF NOT EXISTS `expenditureCausals` (
  `id` int NOT NULL AUTO_INCREMENT,
  `expenditureItem` varchar(25) COLLATE latin1_bin NOT NULL,
  `expenditureDetail` varchar(50) COLLATE latin1_bin DEFAULT NULL,
  `community` varchar(50) COLLATE latin1_bin NOT NULL DEFAULT 'GLOBAL' COMMENT 'The community to which the expenditure causal is related',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
  `lastModified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  PRIMARY KEY (`id`),
  UNIQUE KEY `expenditureCausals_UK_indx` (`expenditureItem`,`expenditureDetail`),
  KEY `expenditureCausal_HAS_Invoice` (`expenditureDetail`),
  KEY `expenditureCausal_REFERSTO_community` (`community`)
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='List of expenditure causals';

--
-- Svuota la tabella prima dell'inserimento `expenditureCausals`
--

TRUNCATE TABLE `expenditureCausals`;
--
-- Dump dei dati per la tabella `expenditureCausals`
--

INSERT DELAYED IGNORE INTO `expenditureCausals` (`id`, `expenditureItem`, `expenditureDetail`, `community`, `created`, `lastModified`) VALUES
(1, 'Vehicles', 'Purchase', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(2, 'Vehicles', 'Rental', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(3, 'Vehicles', 'Long term leasing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(4, 'Vehicles', 'Fuel', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(5, 'Vehicles', 'Servicing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(6, 'Vehicles', 'Maintenance and repair', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(7, 'Vehicles', 'Insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(8, 'Vehicles', 'Road tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(9, 'Vehicles', 'Property tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(10, 'Vehicles', 'Registration fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(11, 'Vehicles', 'Technical inspection', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(12, 'Home', 'Purchase', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(13, 'Home', 'Rental', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(14, 'Home', 'Mortgage', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(15, 'Home', 'Renovation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(16, 'Home', 'Redecoration', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(17, 'Home', 'Refurbishing', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(18, 'Home', 'Standardization and law compliance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(19, 'Home', 'Condominium fees', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(20, 'Home', 'Insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(21, 'Home', 'Property tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(22, 'Home', 'Commissions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(23, 'Bills', 'Water', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(24, 'Bills', 'Electricity', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(25, 'Bills', 'Gas', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(26, 'Bills', 'Telephone', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(27, 'Bills', 'Internet', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(28, 'Bills', 'TV', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(29, 'Bills', 'Mobile phone', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(30, 'Bills', 'Garbage disposal', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(31, 'Medical', 'Heath insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(32, 'Medical', 'Dental care', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(33, 'Medical', 'Medical care', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(34, 'Medical', 'Practitioners and specialists', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(35, 'Medical', 'Drugs', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(36, 'Medical', 'Hospitalization', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(37, 'Education', 'Registration fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(38, 'Education', 'Tuition fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(39, 'Education', 'Stationery', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(40, 'Education', 'Books', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(41, 'Education', 'Photocopies, handouts, ...', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(42, 'Education', 'Accomodation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(43, 'Education', 'Public transportation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(44, 'Education', 'Libraries', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(45, 'Education', 'Museums', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(46, 'Education', 'Visits', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(47, 'Education', 'Field trips', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(48, 'Sports', 'Registration fee', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(49, 'Sports', 'Physical examination', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(50, 'Sports', 'Equipment, gear and outfit', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(51, 'Travel and holidays', 'Insurance', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(52, 'Travel and holidays', 'Commissions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(53, 'Travel and holidays', 'Accomodation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(54, 'Travel and holidays', 'Public transportation', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(55, 'Travel and holidays', 'Museums', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(56, 'Travel and holidays', 'Visits', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(57, 'Travel and holidays', 'Equipment, gear and outfit', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(58, 'Travel and holidays', 'Reservations', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(59, 'Travel and holidays', 'Tickets', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(60, 'Travel and holidays', 'Taxes and other fees', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(61, 'Travel and holidays', 'Travel guides', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(62, 'Taxes', 'Tax returns', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(63, 'Taxes', 'Professional order', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(64, 'Taxes', 'Retirement fund', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(65, 'Taxes', 'Property tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(66, 'Taxes', 'Estate tax', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(67, 'Taxes', 'Garbage disposal', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(68, 'Leisure and recreation', 'Books', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(69, 'Leisure and recreation', 'Libraries', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(70, 'Leisure and recreation', 'Museums', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(71, 'Leisure and recreation', 'Visits', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(72, 'Leisure and recreation', 'Eating out', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(73, 'Leisure and recreation', 'Cinemas and theaters', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(74, 'Leisure and recreation', 'Events and receptions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(75, 'Leisure and recreation', 'Associations and clubs', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(76, 'Daily shopping', 'Supermarket', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(77, 'Daily shopping', 'Bakery, grocery, green grocery, ...', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(78, 'Clothing and outfit', 'Clotes', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(79, 'Clothing and outfit', 'Shoes', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(80, 'Social life', 'Presents', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(81, 'Social life', 'Eating out', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(82, 'Social life', 'Events and receptions', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(83, 'Social life', 'Associations and clubs', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(84, 'Social life', 'Cinemas and theatres', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22'),
(85, 'Charity', 'Donations', 'GLOBAL', '2021-01-21 08:34:22', '2021-01-21 08:34:22');

-- --------------------------------------------------------

--
-- Struttura della tabella `transactions`
--
-- Creazione: Gen 21, 2021 alle 08:34
--

DROP TABLE IF EXISTS `transactions`;
CREATE TABLE IF NOT EXISTS `transactions` (
  `id` int NOT NULL,
  `paymentInstrument` int NOT NULL COMMENT 'The payment instrument that was charged',
  `date` date DEFAULT NULL COMMENT 'The transaction date',
  `amount` decimal(10,0) NOT NULL COMMENT 'The transaction amount',
  `direction` int NOT NULL DEFAULT '-1' COMMENT 'The transaction direction',
  `expenditureCausal` int NOT NULL COMMENT 'The transaction causal',
  `commentary` text COLLATE latin1_bin COMMENT 'A verbose description of the transaction, if appropriate',
  `isPrivate` tinyint NOT NULL DEFAULT '0' COMMENT 'Indication whether the transaction is private or communal. Defaults to communal (FALSE)',
  `activity` int DEFAULT NULL COMMENT 'Reference to the activity or project the transaction shall be accounted against',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'The record creation time reference',
  `lastModified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'The record last modification time reference',
  PRIMARY KEY (`id`),
  UNIQUE KEY `transactions_UK` (`paymentInstrument`,`date`,`amount`,`direction`,`expenditureCausal`),
  KEY `transaction_HAS_direction` (`direction`),
  KEY `transaction_HAS_causal` (`expenditureCausal`),
  KEY `transaction_ISACCOUNTEDAGAINST_activity` (`activity`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='Transactions list';

--
-- Svuota la tabella prima dell'inserimento `transactions`
--

TRUNCATE TABLE `transactions`;
-- --------------------------------------------------------
