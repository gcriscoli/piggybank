<?php

spl_autoload_register(function ($class_name)
{
   $file = 'class.' . $class_name . '.php';
   if (file_exists($file) && is_readable($file))
   {
		require($file);
   }
   else
   {
		throw new Error ("Unable to locate or to access class file $file, which is required by the application. Cannot proceed. Please ensure that the file exist and be readable.", );
   }
})

?>
