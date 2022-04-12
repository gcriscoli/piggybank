<?php

namespace /gcriscoli/piggybank/addresses;

class Countries {

/* Class definition of a COUNTRY OBJECT */
/* Author:              Giulio Criscoli
 * Version:             1.0
 * Project start date:  10/01/2021
 * Last update:         10/01/2021
 *
 */

    protected $Country;                 /* The Country name, ISO8859-1 character coded */
    protected $IntlCountryCode ['Alpha2' => NULL, 'Alpha3' => NULL, 'Numeric' => NULL]
                                       /* The ISO3166 2-letter, 3-letter and numeric Country identification.
                                        * Please see https://www.iban.com/country-codes for reference */
    protected $Currency;               /* The currency in use within a given Nation */
    protected $currencySymbol          /* The symbol of the currency defined above */
    protected $Language;               /* The official language of a Country. In case more languages benefit of the
                                        * "official language" status within a given Country, as is the case in Belgium,
                                        * this property coud be an (associative) array */
    protected $IntlDialingCode;        /* The Country International Dialing Code in the form of a string.
                                        * Each leading '0' should be replaced by the '+' sign. */
    protected $MoreUndocumnetedInfo;   /* An associative array to store any value as referred to a Nation that does not
                                        * fit into any other documented or self-explanatory property of a Nation object */

    public __construct(string $Nation = NULL,
                       array $IntlCountryCode = NULL,
                       string $Currency = NULL,
                       string $CurrencySymbol = NULL,
                       string $Language = NULL,
                       string $IntlDialingCode = NULL,
                       array $MoreUndocumentedInfo = NULL) {

       $this->setNation($Nation);
       $this->setIntlCountryCode($IntlCountryCode);
       $this->setCurrency($Currency);
       $this->setCurrencySymbol($CurrencySymbol);
       $this->setLanguage($Language);
       $this->setIntlDialingCode($IntlDialingCode);

    }

    public function __set (string $property, $value = NULL): ?bool {
       if (method_exists('set' . $property)) {
           return call_user_func(__CLASS__ . '::set' . $property, $value);
       } elseif (property_exists($property)) {
           $this->property = $value;
       } else {
           $this->MoreUndocumentedInfo[$Property] = $value;
       }

       return TRUE;
    }

    public function __get (string $property) {

       if (method_exists('get' . $property)) {
           return call_user_func(__CLASS__ . '::get' . $property);
       } elseif (property_exists($property)) {
           return $this->property;
       } elseif (array_key_exists($property, $this->MoreUndocumentedInfo)) {
           return $this->MoreUndocumentedInfo[$property];
       }

       return NULL;
    }

    protected function setNation (string $Nation = NULL): bool {
       $this->Nation = $Nation;
    }

    protected function setIntlCountryCode(?string $IntlCountryCode = NULL): ?bool {

       /* The function gets a string or NULL as input, andan array possibly containing the Country ISO3166 International Codes and returns
        * - NULL, if NULL is passed onto the function,
        * - TRUE, if the string is the serialization of an associative array containing any well-formatted code,
        * - FALSE, otherwise.
        * In case the string is neither NULL, nor an associative array containing at least some significant information,
        * its elements are stored in the $MoreUndocumentedInfo field. */

       if ($IntlCountryCode === NULL) {
           return NULL;                    /* Return NULL on NULL input */
       }

       $SmtgChanged = FALSE;               /* Keep track of significant changes to the $IntlCountryCode: none, so far */

       try {
           $IntlCountryCode = unserialize($intlCountryCode);
                                           /* Unserialize returns the unserialized object upon success, or FALSE upon
                                            * failure.
                                            * Besides, if the latter is the case, an E_NOTICE excpetion is thrown.
                                            * If the serialized string unserializes to a FALSE boolean, FALSE is returned,
                                            * but no exception is thrown.*/
       } catch (Exception $exception) {

           /* If unserialize throws an excpetion - meaning that the provided string could not be unserialized -
            * the function shall stop and return NULL */
           echo "The provided object could not be successfully unserialized ($exception->getMessage()). Quitting...<br>"; //This needs be fixed at a later stage!
           return NULL;
       }

       /* If the unserialization succeeds,
        * check that the unserialized object is an array, */
       if (is_array($IntlCountryCode)) {

           /* in which case, check each key */
           foreach ($IntlCountryCode as $Key => $Value) {

               /* for correspondance to an existing key in $IntlCountryCode,*/
               if (array_key_exists($Key, $this->IntlCountryCode)){

                   /* set its value accordingly, */
                   $this->IntlCountryCode[$Key] = $Value;

                   /* and keep track of any significant changes */
                   $SmtgChanged = TRUE;
               } else {

                   /* or store any information in $MoreUndocumentedInfo */
                   $this->MoreUndocumentedInfo[$Key] = $Value;
               }
           }
       } else {

           /* In case the unserialized object is not an arra, its value shall be stored as an additional
            * value of $MoreUndocumentedInfo.
            * In this case, no significant change to $IntlCountryCode has taken place. */
           $this->MoreUndocumentedInfo[] = $IntlCountryCode;
       }

       /* Eventually return the current status of significant changes */
       return $SmtgChanged;
    }

    public function setCurrency (?string $Currency = NULL): bool {

        /* The function sets the Country currency to the provided string value.
         * It returns TRUE, normally, and FALSE if and only if the provided string value itself is NULL. */
        $this->Currency = $Currency;

        return ($this->Currency === NULL ? FALSE : TRUE);
    }

}




?>
