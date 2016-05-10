<?php
/**
 * Global Configuration Override
 *
 * You can use this file for overriding configuration values from modules, etc.
 * You would place values in here that are agnostic to the environment and not
 * sensitive to security.
 *
 * @NOTE: In practice, this file will typically be INCLUDED in your source
 * control, so do not include passwords or other sensitive information in this
 * file.
 */

/*
Basic Setup from:
http://framework.zend.com/manual/2.3/en/tutorials/tutorial.dbadapter.html
Adapter Settings from:
http://framework.zend.com/manual/2.3/en/modules/zend.db.adapter.html#zend-db-adapter
*/

return array(
   'db' => array(
      'driver' => 'Pdo',
      'dsn' => 'mysql:dbname=zf2tutorial;host=localhost',
      'username' => '',
      'password' => ''
   ),
   'service_manager' => array(
      'factories' => array(
         'Zend\Db\Adapter\Adapter' => 'Zend\Db\Adapter\AdapterServiceFactory',
      ),
   ),
);
