<?php

namespace DBConnection;

$DBParams = array();

$DBParams ['DBMSType']	=	'MySQL';
$DBParams ['hostname']	=	'MySQL80';
$DBParams ['username']	=	'root';
$DBParams ['password']	=	'P455word!';
$DBParams ['database']	=	'piggybank';
$DBParams ['port']	=	'3306';
$DBParams ['socket']	=	'TCP/IP';
$DBParams ['limit']	=	30;

$validationPatterns = array();

/* A label is any arbitrarily long sequence of alphanumeric characters and hyphens that start and end with a letter or a number:
 *	[a-zA-Z0-9]+[a-zA-Z0-9\-]*(?(?<=\-)[a-zA-Z0-9]|)
 * A tld (Top Level Domain) is any at least 2 character long label:
 * 	(?=\S{2,})[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]
 * Any valid hostname is a 4-to.253 character long sequence of labels separated by dots (\.) and terminated by a tld:
 * 	^(?=.{4,253})([a-zA-Z0-9][a-zA-Z0-9\-]*(?(?<=\-)[a-zA-Z0-9]+|)\.)+(?=\S{2,})[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]$
 * */
$validationPatterns ['DBParams']['hostname']	=	'(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)';

/* Any valid IPv4 address is composed of 4 octets in decimal notation, separated by single dots (.).
 * Overall, a valid IPv4 address is
 * - between 7 and 15 character long:
 * 		(?=.{7,15})
 * - ((a sequence of 1-to-3 decimals followed by a single dot (.)) repeated 3 times) followed by a sequence of 1-to-3 decimals:
 * 		(?=(\d{1,3}\.){3}\d{1,3});
 * - each octet is a sequence of 1 to three digits and ranges between 1 and 254, this meaning that:
 *   - the first digit, if present, can only be 1 or 2:
 *   	[12]?
 *   - if the first digit is 2, the second can only range between 0 and 5; ohtherwise, between 0 and 9:
 *   	(?(?<=2)[0-5]|[0-9]);
 *   - if the first two digits are 2 and 5, respectively, then the third can only range between 0 and 4, otherwise, between 0 and 9:
 *   	(?(?<=25)[0-4]|[0-9]);
 * - the first three octets are followed by a single dot (\.); the fourth octet is not followed by anything:
 * 	^([12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])\.){3}[12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])$
 * - The complete regular expression, then, is:
 * 	^(?=.{7,15})(?=(\d{1,3}\.){3}\d{1,3})([12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])\.){3}[12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])$*/
$validationPatterns ['DBParams']['IPv4']	=	'^(?=.{7,15})(?=(\d{1,3}\.){3}\d{1,3})([12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])\.){3}[12]?(?(?<=2)[0-5]|[0-9])?(?(?<=25)[0-4]|[0-9])$';

/* An IPv6 address is as provided below */
$validationPatterns ['DBParams']['IPv6']	=	'^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$';

/* A valid docker container name is any 1-to-128 character long sequence of characters:
 * 	(?=.{1,128})
 * A container name shall start and end with a letter or a number, and may contain as many hyphens or dashes and dots as desired:
 * 	[a-zA-Z0-9][a-zA-Z0-9\.\-]{0,126}(?(?<=[\.\-])[a-zA-Z0-9]|[a-zA-Z0-9]?)
 * The complete regular expression, then, is:
 * 	^(?=.{1,128})[a-zA-Z0-9][a-zA-Z0-9\.\-]{0,126}(?(?<=[\.\-])[a-zA-Z0-9]|[a-zA-Z0-9]?)$
 * */
$validationPatterns ['DBParams']['Docker']	=	'^(?=.{1,128})[a-zA-Z0-9][a-zA-Z0-9\.\-]{0,126}(?(?<=[\.\-])[a-zA-Z0-9]|[a-zA-Z0-9]?)$';
$validationPatterns ['DBParams']['NULL'] = NULL;
?>
