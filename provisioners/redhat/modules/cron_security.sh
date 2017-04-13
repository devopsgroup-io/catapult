#!/bin/bash

/bin/echo -e "THIS CRON_SECURITY MODULE IS USED TO HELP IDENTIFY ATTACK PATTERNS"

/bin/echo -e "\nhere are recent ip addresses blocked by fail2ban (/var/log/fail2ban.log*)"
/bin/echo -e "================================================"
/bin/tac /var/log/fail2ban.log* | /bin/grep --extended-regexp --max-count=20 --regexp="(Ban)"

if [ -f "/var/log/httpd/access_log" ]; then

    /bin/echo -e "\nhere are recent 404s targeted at this server's ip address of $(hostname -i | awk '{print $3}') (/var/log/httpd/access_log*)"
    /bin/echo -e "========================================================="
    /bin/tac /var/log/httpd/access_log* | /bin/grep --extended-regexp --max-count=20 --regexp="\" 404 "

    /bin/echo -e "\nhere are recent 404s potentially targeted at vhosts (/var/log/httpd/*/access_log*)"
    /bin/echo -e "==================================================="
    /bin/tac /var/log/httpd/*/access_log* | /bin/grep --extended-regexp --max-count=20 --regexp="\" 404 "

    /bin/echo -e "\nhere are recent matches from a keyword threatlist potentially targeted at vhosts (/var/log/httpd/*/error_log*)"
    /bin/echo -e "(denied|failed|failure|invalid|limit|permission)"
    /bin/echo -e "================================================================================"
    /bin/tac /var/log/httpd/*/error_log* | /bin/grep --ignore-case --extended-regexp --max-count=20 --regexp="(denied|failed|failure|invalid|limit|permission)"

fi

/bin/echo -e "\nhere is the fail2ban configuration"
/bin/echo -e "================================================"
/bin/cat /etc/fail2ban/jail.local

/bin/echo -e "\nhere are the currently configured fail2ban jails"
/bin/echo -e "================================================"
/bin/fail2ban-client status

/bin/echo -e "\nhere are all the available fail2ban filters (/etc/fail2ban/filter.d)"
/bin/echo -e "==========================================="
/bin/ls /etc/fail2ban/filter.d
