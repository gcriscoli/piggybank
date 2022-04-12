<?php

namespace /gcriscoli/piggybank/addresses;

/* Class definition of an ADDRESS OBJECT */
/* Author:              Giulio Criscoli
 * Version:             1.0
 * Project start date:  10/01/2021
 * Last update:         10/01/2021
 *
 * An ADDRESS is a physical location on earth identified by a Name and a set of coordinates.
 * It belongs to a Nation territory.
 * Nations are defined as separate objects in a specific class.
 */

class Address {

	protected StreetSuffix; /* Denominazione Urbanistica Generica, DUG in Italian */
	protected Toponym;
	protected HouseNumber;
	protected ZIPCode;
	protected Town;
	protected ProvinceOrState;
	protected Nation;

	protected Latitude;
	protected Longitude;
	protected Elevation;
    protected Approx;       /* Boolean value to define whether to Lat/Long position has been APPROXIMATELY determined
                             * by querying to Google Maps DB on the basis of the given address, or was provided as
                             * an exact value by the user */

	protected LocalModel;   /* Addresses appear very different in presentation, depending on the language pattern to be
                             * followed.
                             * For example, Italian addresses follow the model "StreetSuffix Toponym, HouseNumber\nZIPCode Town (Province)\n State", whereas in French they look like "HouseNumber StreetSuffix Toponym\nZIPCode Town (Province)\nNation".
                             * Different patterns or models can be provided in the form of a string that informs the
                             * __toString() method as to how to format each address, depending on its global location. */

    /* OPERATIONS ON ADDRESSES */
    /* Explicit operations (PUBLIC methods)*/
    /* On addresses, a set of different publicly available operations exists:
     * - Create an address object (__construct)
     * - Modify an existing address object, thus modify any of its attributes value
     * - Set any attribute value
     * - Get any attribute value
     * - Write an address object content out as a valid address according to any local model, the latter being normally stored as part of a Nation object
     */

    /* Implicit operations (PROTECTED and PRIVATE methods) */
    /* Likewise, a number of implicit operations exists:
     * - Retrieve an address coordinates from Google Maps
     */

    public function __construct(string StreetSuffix = NULL,
                                string Toponym = NULL,
                                string HouseNumber = NULL,
                                string ZIPCode = NULL,
                                string Town = NULL,
                                string ProvinceOrState = NULL,
                                string Nation = NULL,
                                double Latitude = NULL,
                                double Longitude = NULL,
                                double Elevation = NULL,
                                bool Approx = TRUE) {

    }
}


?>
