#!/bin/bash

/bin/echo -e "==========================================================================================="
/bin/echo -e "THIS CATAPULT CRON_CERTIFICATES MODULE RENEWS LET'S ENCRYPT HTTPS CERTIFICATES FOR WEBSITES"
/bin/echo -e "==========================================================================================="

/bin/bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --keep-going

/bin/echo -e "\n"
