#!/bin/bash

/bin/echo -e "==========================================================================================="
/bin/echo -e "THIS CATAPULT CRON_CERTIFICATES MODULE RENEWS LET'S ENCRYPT HTTPS CERTIFICATES FOR WEBSITES"
/bin/echo -e "==========================================================================================="

/bin/bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --keep-going

while IFS= read -r line
do
    domain=$(echo "${line}" | cut -d " " -f 1)
    cd "/catapult/provisioners/redhat/installers/dehydrated/certs/${domain}/" && cat "cert.pem" "privkey.pem" "chain.pem" > "/catapult/provisioners/redhat/certs/${domain}.pem"
done < "/catapult/provisioners/redhat/installers/dehydrated/domains.txt"

sudo /usr/bin/systemctl reload haproxy.service

ls -lha /catapult/provisioners/redhat/certs/

/bin/echo -e "\n"
