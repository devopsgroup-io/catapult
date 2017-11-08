#!/bin/bash

/bin/echo -e "====================================================================================="
/bin/echo -e "THIS CATAPULT CRON_SECURITY_PREVENTIVE MODULE AUDITS SECURITY HARDENING CONFIGURATION"
/bin/echo -e "====================================================================================="

/bin/echo -e "\nhere is the status of the system kernel"
/bin/echo -e "----------------------------------------"
kernel_running=$(/bin/uname --release)
kernel_running="kernel-${kernel_running}"
kernel_staged=$(/bin/rpm --last --query kernel | /bin/head --lines 1 | /bin/awk '{print $1}')
/bin/echo -e "running kernel ${kernel_running}"
/bin/echo -e "staged kernel ${kernel_staged}"
if [ "${kernel_running}" != "${kernel_staged}" ]; then
    /bin/echo -e "\n***this system will reboot at 3:05am to apply the staged kernel"
    /sbin/shutdown --reboot 03:05
fi

/bin/echo -e "\nhere are results from a security audit performed by lynis"
/bin/echo -e "----------------------------------------"
/bin/lynis audit system --quick --quiet
/bin/grep "hardening_index" /var/log/lynis-report.dat
/bin/grep "lynis_tests_done" /var/log/lynis-report.dat
/bin/grep "report_datetime_start" /var/log/lynis-report.dat
/bin/grep "report_datetime_end" /var/log/lynis-report.dat
/bin/echo -e "\n"
