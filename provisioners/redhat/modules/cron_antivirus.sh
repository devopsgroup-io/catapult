#!/bin/bash

/bin/echo -e "\nTHIS CATAPULT CRON_ANTIVIRUS MODULE IS USED TO HELP FIND INFECTED FILES IN WEBSITE WEBROOTS\n"

/usr/bin/freshclam

/usr/bin/clamscan /var/www/repositories/apache/ --infected --recursive
