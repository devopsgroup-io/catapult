<?php

global $project;
$project = 'mysite';

global $databaseConfig;
$databaseConfig = array(
    'type' => 'MySQLDatabase',
    'server' => '',
    'username' => '',
    'password' => '',
    'database' => '',
    'path' => ''
);

// Set the site locale
i18n::set_locale('en_US');
