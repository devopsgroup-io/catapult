<?php

return [
    'default-connection' => 'concrete',
    'connections' => [
        'concrete' => [
            'driver' => 'c5_pdo_mysql',
            'server' => 'localhost',
            'database' => 'database_name_here',
            'username' => 'username_here',
            'password' => 'password_here',
            'charset' => 'utf8',
        ],
    ],
];
