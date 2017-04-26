#!/bin/bash

/bin/echo -e "==========================================================================================="
/bin/echo -e "THIS CATAPULT CRON_ANTIVIRUS MODULE IS USED TO HELP FIND INFECTED FILES IN WEBSITE WEBROOTS"
/bin/echo -e "==========================================================================================="

/usr/bin/freshclam

/usr/bin/clamscan /var/www/ --infected --recursive

/bin/echo -e "\n"
