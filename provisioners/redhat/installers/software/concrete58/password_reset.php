<?php

// https://documentation.concrete5.org/developers/security/encryption-service
$ui = UserInfo::getByID(1);
$ui->changePassword($args[0]);
