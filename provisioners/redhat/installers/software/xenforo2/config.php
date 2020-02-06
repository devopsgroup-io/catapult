<?php

$config['db']['host'] = 'localhost';
$config['db']['port'] = 3306;
$config['db']['username'] = '';
$config['db']['password'] = '';
$config['db']['dbname'] = '';
$config['db']['socket'] = null;

$config['superAdmins'] = '1';

if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_FORWARDED_FOR'];
}
