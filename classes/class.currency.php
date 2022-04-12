<?php

//namespace gcriscoli/piggybank/currencies;

class Currency {

/* Class definition of a CURRENCY OBJECT based on ISO4177 */
/* Author:              Giulio Criscoli
 * Version:             1.0
 * Project start date:  10/01/2021
 * Last update:         10/01/2021
 *
 */

    /* PERSISTENT STORAGE MANAGEMENT */

    private const HOSTNAME = '127.0.0.1';
    private const USERNAME = 'root';
    private const PASSWORD = 'P455word!';
    private const DATABASE = 'piggybank';
    private const PORT = 3306;

    private $ConnectionHandler;

    /* PERSISTENT STORAGE MANAGEMENT */

	protected $Currency;
	protected $CurrencyCode;
	protected $CurrencySymbol;
	protected $UnicodeCurrencyCharCode;
	protected $HTMLCurrencyCharCode;
	protected $HEXCurrencyCharCode;

    private const UNICODE_VALID_STRING = '/^[u|U]\+[0-9A-Fa-f]{5}?/';
	private const HTML_VALID_STRING = '/^&#(x|X)[0-9a-f-A-F]{1,4}?/';
	private const HEX_VALID_STRING = '/^&#[0-9a-fA-F]{1,4}?/';

    /* In case the class contructor is called without any initialization parameter, it defaults the
     * configuration to EURO as the standard Currency.
     * This setting can be changed by modifying the following constants.
     * Should anyone decide to hand change those settings, please make sure they are still consistent.
     * */

    private const DEFAULT_CURRENCY = 'Euro';                        // The default currency is 'Euro'.
    private const DEFAULT_CURRENCY_CODE = 'EUR';                    // The default currency symbol is 'EUR' - the official 'Euro' currency code
    private const DEFAULT_CURRENCY_SYMBOL = '€';                    // The default currency symbol is '€' - the official 'Euro' symbol
    private const DEFAULT_UNICODE_CURRENCY_CHAR_CODE = 'U+020AC';   // The default currency unicode char code is 'U+020AC' - the '€' unicode representation
    private const DEFAULT_HTML_CURRENCY_CHAR_CODE = '&#x20AC';      // The default currency HTML char code is '&#x20AC' - the '€' HTML representation
    private const DEFAULT_HEX_CURRENCY_CHAR_CODE = '&#20AC';        // The default currency HEX char code is '&#20AC' - the '€' HEX representation
    /* The above seen settings will, at a later stage - be moved away from the class definition and store in an appropriate configuration file */


	public function __construct (?string $Currency = self::DEFAULT_CURRENCY,
								 ?string $CurrencyCode = self::DEFAULT_CURRENCY_CODE,
								 ?string $CurrencySymbol = self::DEFAULT_CURRENCY_SYMBOL,
								 ?string $UnicodeCurrencyCharCode = self::DEFAULT_UNICODE_CURRENCY_CHAR_CODE,
								 ?string $HTMLCurrencyCharCode = self::DEFAULT_HTML_CURRENCY_CHAR_CODE,
								 ?string $HEXCurrencyCharCode = self::DEFAULT_HEX_CURRENCY_CHAR_CODE) {

		$this->setCurrency($Currency);
		$this->setCurrencyCode($CurrencyCode);
		$this->setCurrencySymbol($CurrencySymbol);
		$this->setUnicodeCurrencyCharCode($UnicodeCurrencyCharCode);
		$this->setHTMLCurrencyCharCode($HTMLCurrencyCharCode);
		$this->setHEXCurrencyCharCode($HEXCurrencyCharCode);

        $this->ConnectionHandler = new mysqli(self::HOSTNAME, self::USERNAME, self::PASSWORD, self::DATABASE, self::PORT);

        switch ($this->ConnectionHandler->connect_errno) {

            case 1049:  /* NON-EXISTENT DATABASE */

                /* This situation may occur when the connection to the DBMS would have succeeded, but
                 * the specified DB doesn't exist on the DBMS.
                 * To ascertain that a second attempt is made to connect to the DBMS without the DB specification.
                 * In case this succeeds, an attempt is made to create a DB with the given name.
                 * If this is succesfull, the routine continues, otherwise an exception is thrown. */
                echo "Connection to " . self::HOSTNAME . " as user " . self::USERNAME . " with password " . self::PASSWORD . " asking for database " . self::DATABASE . " on port " . self::PORT . " failed miserably.<br>";
                echo "Attempting new simplified connection to " . self::HOSTNAME . " as user " . self::USERNAME . " with password " . self::PASSWORD . ".<br>";
                $this->ConnectionHandler = new mysqli(self::HOSTNAME, self::USERNAME, self::PASSWORD);

                if ($this->ConnectionHandler->connect_errno !== 0) {

                    /* If the "simplified" connection fails, the problem may reside elsewhere.
                     * In this case, there is no further recovery action that could be automatically taken
                     * without modifying the connection parameters, i.e.: the HOSTNAME, the USERNAME or the PASSWORD.
                     * When the connection fails again, the mysqli constructor returns a non-FALSE value, which is then
                     * used to throw an exception and stop execution. */
                    echo "Simplified connection failed.<br>";
                    throw new Exception('MySQL error ' . $this->ConnectionHandler->connect_errno . ': ' . $this->ConnectionHandler->connect_error, E_ERROR);
                } else {

                    /* If the "simplified" connection succeeds, maybe the DB doesn't exist.
                     * In this case, an attempt is made to create it. */
                    $CreateDB = 'CREATE DATABASE IF NOT EXISTS `' . self::DATABASE . '`';
                    echo "Simplified connection succeeded. Attempting to create the database:<br>$CreateDB<br>";

                    if ($this->ConnectionHandler->query($CreateDB)) {

                        /* If the DB creation succeeds, privileges on it must be set so that the connection user can
                         * manipulate the DB structure and data, and grant privileges to other users. */
                        $GrantPrivileges = "GRANT ALL ON `" . self::DATABASE . "`.* TO `" . self::USERNAME . "`@`" . $_SERVER['SERVER_NAME'] . "` WITH GRANT OPTION";
                        echo "The DB creation succeeded. Proceeding to grant user's privileges:<br>$GrantPrivileges<br>";
                        $this->ConnectionHandler->query($GrantPrivileges);

                        /* If granting privileges to the user fails, an exception is thrown to inform. */
                        if ($this->ConnectionHandler->errno !== 0) {

                            echo "Granting user's privileges failed. Fuck you!<br>";
                            throw new Exception ('Unable to set administrative privileges for user ' . self::USERNAME . ' on database ' . self::DATABASE . '.', E_NOTICE);
                        }
                    } else {

                        /* If the DB creation fails, the user has insufficient privileges to create new databases.
                         * In this case, an exception is thrown to inform. */

                        echo "The DB creation failed. Fuck you!<br>";
                        throw new Exception('The specified database (' . self::DATABASE . ') does not exist, and the specified user (' . self::USERNAME . ') has insufficient privileges to create it.', E_NOTICE);
                    }
                }
                break;
            case 1045:  /* BAD PASSWORD */

                /* This situation may occur when the DB user's password provided in the configuration file is wrong.
                 * If this is the case, there is no automatic recovery action possible: the DB administrator must
                 * provide new or valid credentials. */
                throw new Exception ("The database user's password is wrong. Please make contact with the DB Administrator to get new or valid credentials.", E_ERROR);
                break;
            case 2054:  /* BAD USERNAME */

                /* This situation may occur when the DB user's username provided in the configuration file is wrong.
                 * If this is the case, there is no automatic recovery action possible: the DB administrator must
                 * provide new or valid credentials. */
                throw new Exception ("The database user's username is wrong. Please make contact with the DB Administrator to get new or valid credentials.", E_ERROR);
                break;
            case 2002:  /* BAD HOST OR PORT */

                /* This situation may occur when the DBMS hostname, or connection port, or both
                 * provided in the configuration file are wrong.
                 * If this is the case, there is no automatic recovery action possible: the DB administrator must
                 * provide new or valid credentials. */
                throw new Exception ("Your connection to the DBMS was rejected. The DBMS hostname or port might be wrong. Please make contact with the DBMS Administrator to get new or valid connection parameters.", E_ERROR);
                break;
            case 1130:  /* UNAUTHORIZED GUEST CONNECTION */

                /* This situation may occur when all the connection parameters are correct, but the DB user is not allowed
                 * to connect from the specified hostname.
                 * If this is the case, there is no automatic recovery action possible: the DBMS Administrator must allow the
                 * user's connection from the specified hostname. */
                throw new Exception ("You are not allowed to connect to the DB from the servers hostname or IP address. Please make contact with the DBMS Administrator to adjust the DBMS settings.", E_ERROR);
                break;
            default:    /* HOORAY */
                echo "If you are reading this, it's your lucky day!<br>";
                break;
        }
	}

	public function __toString(): ?string {

		return ($this->getCurrencyCode() . ' (' . $this->getCurrencySymbol() . ')');
	}

	public function __serialize(): array {

		$SerializedCurrency = [
			'Currency'	=>	$this->getCurrency(),
			'Currency code'	=>	$this->getCurrencyCode(),
			'Currency symbol'	=>	$this->getCurrencySymbol(),
			'Currency UNICODE char code'	=>	$this->getUnicodeCurrencyCharCode(),
			'Currency HTML char code'	=>	$this->getHTMLCurrencyCharCode(),
			'Currency HEX char code'	=>	$this->getHEXCurrencyCharCode()
		];

		return $SerializedCurrency;
	}

	public function __unserialize(array $SerializedCurrency) {

		if (array_key_exists('Currency', $SerializedCurrency)) {
			$this->setCurrency($SerializedCurrency['Currency']);
		}

		if (array_key_exists('Currency code', $SerializedCurrency)) {
			$this->setCurrencyCode($SerializedCurrency['Currency code']);
		}

		if (array_key_exists('Currency symbol', $SerializedCurrency)) {
			$this->setCurrencySymbol($SerializedCurrency['Currency symbol']);
		}

		if (array_key_exists('Currency UNICODE char code', $SerializedCurrency)) {
			$this->setCurrencyUnicodeCharCode($SerializedCurrency['Currency UNICODE char code']);
		}

		if (array_key_exists('Currency HTML char code', $SerializedCurrency)) {
			$this->setCurrencyHTMLCharCode($SerializedCurrency['Currency HTML char code']);
		}

		if (array_key_exists('Currency HEX char code', $SerializedCurrency)) {
			$this->setCurrencyHTMLCharCode($SerializedCurrency['Currency HEX char code']);
		}
	}

	public function setCurrency (?string $Currency): bool {

		/* The function sets property $Currency value to input parameter $Currency, regardless of it being
		 * an exisiting Currency or NULL.
		 * There is no way to determine if a string is a valid Currency other than comparing it with a list
		 * of valid currencies, therefore no validity check is performed.
		 * $Currency is set to NULL iff the input parameter is explicitely NULL, otherwise it defaults to class
		 * constant DEFAULT_CURRENCY.
		 * The function returns FALSE id $Currency is set to NULL, or TRUE otherwise.
		 */

		$this->$Currency = $Currency;

		return ($this->Currency === NULL ? FALSE : TRUE);
	}

	public function getCurrency (): ?string {

		return $this->Currency;
	}

	public function setCurrencyCode (?string $CurrencyCode): bool {

		/* The function sets property $CurrencyCode to input parameter $CurrencyCode, regardless of it being
		 * an exisiting Currency Code or NULL.
		 * Valid CurrencyCodes are three letter all capital strings.
		 * $CurrencyCode is set to NULL iff the input parameter is explicitely NULL or if the provided input parameter
		 * is an invalid $CurrencyCode, otherwise it defaults to class constant DEFAULT_CURRENCY_CODE.
		 * The function returns FALSE if $CurrencyCode is set to NULL, or TRUE otherwise.
		 */

		$this->CurrencyCode = (($CurrencyCode === NULL || strlen($CurrencyCode) <> 3) ? NULL : strtoupper($CurrencyCode));

		return ($this->CurrencyCode === NULL ? FALSE : TRUE);
	}

	public function getCurrencyCode (): ?string {

		return $this->CurrencyCode;
	}

	public function setCurrencySymbol (?string $CurrencySymbol): bool {

		/* The function sets property $CurrencySymbol to input parameter $CurrencySymbol, regardless of it being
		 * an exisiting Currency Symbol or NULL.
		 * Valid CurrencySimbols are one-to-three letter strings.
		 * As valid CurrencySymbol include upper- and lower- case characters, the input symbol is assumed to have been
		 * provided correctly: no case conversion is performed.
		 * $CurrencySymbol is set to NULL iff the input parameter is explicitely NULL or if the provided input parameter
		 * is an invalid $CurrencyCode, otherwise it defaults to class constant DEFAULT_CURRENCY_SYMBOL.
		 * The function returns FALSE if $CurrencySymbol is set to NULL, or TRUE otherwise.
		 */

		$this->CurrencySymbol = (($CurrencySymbol === NULL || strlen($CurrencySymbol) < 1 || strlen($CurrencySymbol) > 3) ? NULL : $CurrencySymbol);

		return ($this->CurrencySymbol === NULL ? FALSE : TRUE);
	}

	public function getCurrencySymbol (): ?string {

		return $this->CurrencySymbol;
	}

	public function setUnicodeCurrencyCharCode (?string $UnicodeCurrencyCharCode): bool {

		/* The function sets property $UnicodeCurrencyCharCode to input parameter $UnicodeCurrencyCharCode, regardless of it being
		 * an exisiting UNICODE char code or NULL.
		 * Valid UNICODES are seven letter upercase strings starting with 'U+'.
		 * $UnicodeCurrencyCharCode is set to NULL iff the input parameter is explicitely NULL or if the provided input parameter
		 * is an invalid $CurrencyCode, otherwise it defaults to class constant DEFAULT_UNICODE_CURRENCY_CHAR_CODE.
		 * The function returns FALSE if $UnicodeCurrencyCharCode is set to NULL, or TRUE otherwise.
		 */

		$this->UnicodeCurrencyCharCode = (($UnicodeCurrencyCharCode === NULL || ! preg_match(self::UNICODE_VALID_STRING, $UnicodeCurrencyCharCode)) ? NULL : strtoupper($UnicodeCurrencyCharCode));

		return ($this->UnicodeCurrencyCharCode === NULL ? FALSE : TRUE);
	}

	public function getUnicodeCurrencyCharCode (): ?string {

		return $this->UnicodeCurrencyCharCode;
	}

	public function setHTMLCurrencyCharCode (?string $HTMLCurrencyCharCode = '&#x20AC'): bool {

		/* The function sets property $HTMLCurrencyCharCode to input parameter $HTMLCurrencyCharCode, regardless of it being
		 * an exisiting HTML char code or NULL.
		 * Valid HTML codes are seven letter uppercase strings starting with '&#x'.
		 * $HTMLCurrencyCharCode is set to NULL iff the input parameter is explicitely NULL or if the provided input parameter
		 * is an invalid $HTMLCurrencyCharCode, otherwise it defaults to class constant DEFAULT_HTML_CURRENCY_CHAR_CODE.
		 * The function returns FALSE if $HTMLCurrencyCharCode is set to NULL, or TRUE otherwise.
		 */

		$this->HTMLCurrencyCharCode = (($HTMLCurrencyCharCode === NULL || ! preg_match(self::HTML_VALID_STRING, $HTMLCurrencyCharCode)) ? NULL : strtoupper($HTMLCurrencyCharCode));

		return ($this->HTMLCurrencyCharCode === NULL ? FALSE : TRUE);
	}

	public function getHTMLCurrencyCharCode (): ?string {

		return $this->HTMLCurrencyCharCode;
	}

	public function setHEXCurrencyCharCode (?string $HEXCurrencyCharCode): bool {

		/* The function sets property $HEXCurrencyCharCode to input parameter $HEXCurrencyCharCode, regardless of it being
		 * an exisiting HEX char code or NULL.
		 * Valid HEX codes are six letter uppercase strings starting with '&#'.
		 * $HEXCurrencyCharCode is set to NULL iff the input parameter is explicitely NULL or if the provided input parameter
		 * is an invalid $HEXCurrencyCharCode, otherwise it defaults to class constant DEFAULT_HEX_CURRENCY_CHAR_CODE.
		 * The function returns FALSE if $HEXCurrencyCharCode is set to NULL, or TRUE otherwise.
		 */

		$this->HEXCurrencyCharCode = (($HEXCurrencyCharCode === NULL || ! preg_match(self::HEX_VALID_STRING, $HEXCurrencyCharCode)) ? NULL : strtoupper($HEXCurrencyCharCode));

		return ($this->HEXCurrencyCharCode === NULL ? FALSE : TRUE);
	}

	public function getHEXCurrencyCharCode (): ?string {

		return $this->HEXCurrencyCharCode;
	}
}


?>
