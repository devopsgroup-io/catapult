#!/bin/bash

/bin/echo -e "======================================================================================"
/bin/echo -e "THIS CATAPULT CRON_SECURITY_CORRECTIVE MODULE FINDS INFECTED FILES IN WEBSITE WEBROOTS"
/bin/echo -e "======================================================================================"

/usr/bin/freshclam

/usr/bin/clamscan /var/www/ --infected --recursive --remove=yes

/bin/echo -e "\n"
