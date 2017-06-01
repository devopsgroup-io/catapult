#!/bin/bash

/bin/echo -e "====================================================================================="
/bin/echo -e "THIS CATAPULT CRON_SECURITY_PREVENTIVE MODULE AUDITS SECURITY HARDENING CONFIGURATION"
/bin/echo -e "====================================================================================="

/bin/lynis audit system --quick --quiet

/bin/grep "hardening_index" /var/log/lynis-report.dat
/bin/grep "lynis_tests_done" /var/log/lynis-report.dat
/bin/grep "report_datetime_start" /var/log/lynis-report.dat
/bin/grep "report_datetime_end" /var/log/lynis-report.dat

/bin/echo -e "\n"
