<?php

interface PersistentStorage {

	/* PersistentStorage is the abstraction of any persistent storage facility, be it a file or a database.
	 * Any web application that requires permanently storing its data will implement an instance of the PersistentStorage,
	 * and - by means of it - will transparently manage the connection to the storage facility.
	 *
	 * Persistent Storage is meant to be used to handle DB connections as well as configuration files or other types of files. */

	$PersistentStorageHandler;		/* The persistent storage facility handler. May not always be required. */

	public function OpenStreamToStorage (array $PersistentStorageParameters);
	/* Opens a stream to an existing persistent storage facility and returns its connection handler.
	 * The result is NULL if the operation fails. */

	public function Store ($Data): ?bool;
	/* Stores data in an existing persistent storage facility identified by $PersistentStorageHandler.
	 * Returns TRUE on success, FALSE on fail and NULL there is no openable stream (maybe the resource doesn't exist
	 * or it is not accessible) */

	public function Fetch ($Data): ?array;
	/* Fetches data from an existing persistent storage facility identified by $PersistentStorageHandler.
	 * Returns the data on success, FALSE on fail or NULL if the persistent storage facility is non-existing
	 * or non-openable. */

	public function CloseStreamToStorage ();
	/* Closes an open stream committing any changes. */
}

class MySQLPersistentStorage implements PersistentStorage {
	#code

	public $PersistentStorageHandler;

	public function __construct (array $PersistentStorageParameters) {

		if (array_key_exists('HOSTNAME', $PersistentStorageParameters) &&
			array_key_exists('USERNAME', $PersistentStorageParameters) &&
			array_key_exists('PASSWORD', $PersistentStorageParameters) &&
			array_key_exists('DATABASE', $PersistentStorageParameters) &&
			array_key_exists('PORT', $PersistentStorageParameters) &&
			array_key_exists('SOCKET', $PersistentStorageParameters)) {

			$this->PersistentStorageHandler = new mysqli($PersistentStorageParameters['HOSTNAME'],
												 $PersistentStorageParameters['USERNAME'],
												 $PersistentStorageParameters['PASSWORD'],
												 $PersistentStorageParameters['DATABASE'],
												 $PersistentStorageParameters['PORT'],
												 $PersistentStorageParameters['SOCKET']);

			if ($this->PersistentStorageHandler->errno) {

			}
		}
	}

	public function setPersistentStorageHandler ($MySQLConnectionHandler): ?bool {

	}

	public function getPersistentStorageHandler (): ?MySQLPersistentStorage {

	}

	public function OpenStreamToStorage (array $PeristentStorageParameters) {

	}

	public function Store ($Data): ?bool {

	}

	public function Fetch ($Data): ?array {

	}

	public function CloseStreamToStorage () {

	}
}


?>
