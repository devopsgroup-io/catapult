#!/bin/bash

/bin/echo -e "\nTHIS CATAPULT CRON_CERTIFICATES MODULE RENEWS LET'S ENCRYPT HTTPS CERTIFICATES FOR WEBSITES\n"

/bin/bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --keep-going
