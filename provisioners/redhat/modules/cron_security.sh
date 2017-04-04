#!/bin/bash

/bin/echo -e "THIS CRON_SECURITY MODULE IS USED TO HELP IDENTIFY ATTACK PATTERNS"

/bin/echo -e "\nhere are recent ip addresses blocked by fail2ban"
/bin/echo -e "================================================"
/bin/grep "Ban" /var/log/fail2ban.log* | /bin/head -n 20

/bin/echo -e "\nhere are recent 404s targeted at this server's ip address"
/bin/echo -e "========================================================="
/bin/grep --extended-regexp --max-count=20 --regexp="\" 404 " /var/log/httpd/access_log

/bin/echo -e "\nhere are recent 404s potentially targeted at vhosts"
/bin/echo -e "==================================================="
/bin/grep --extended-regexp --max-count=20 --regexp="\" 404 " /var/log/httpd/*/access_log

/bin/echo -e "\nhere are recent matches from a keyword threatlist potentially targeted at vhosts"
/bin/echo -e "(denied|failed|failure|invalid|limit|permission)"
/bin/echo -e "================================================================================"
/bin/grep --extended-regexp --max-count=20 --regexp="(denied|failed|failure|invalid|limit|permission)" /var/log/httpd/*/error_log

/bin/echo -e "\nhere are the currently configured fail2ban jails"
/bin/echo -e "================================================"
/bin/fail2ban-client status

/bin/echo -e "\nhere are all the available fail2ban filters"
/bin/echo -e "==========================================="
/bin/ls /etc/fail2ban/filter.d
