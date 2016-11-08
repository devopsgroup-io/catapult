source "/catapult/provisioners/redhat/modules/catapult.sh"



if ([ "${4}" == "apache" ] || [ "${4}" == "mysql" ]); then
    echo -e "\n> configuring daily cron task: git gc"
    touch "/etc/cron.daily/catapult-git.cron"
    cat > "/etc/cron.daily/catapult-git.cron" << EOF
#!/bin/bash

for directory in /var/www/repositories/apache/*/; do
    # on a new provision, there will be no directories and an empty for loop returns itself
    if [ -e "${directory}" ]; then
        folder=$(basename "${directory}")
        if ! ([ "_default_" == "${folder}" ]); then
            cd "${directory}" \
                && git gc
        fi
    fi
done
EOF
    chmod 755 "/etc/cron.daily/catapult-git.cron"
fi



if [ "${4}" == "mysql" ]; then
    echo -e "\n> configuring daily cron task: mysql check"
    # ref: https://mariadb.com/kb/en/mariadb/mysqlcheck/
    touch "/etc/cron.daily/catapult-mysql.cron"
    cat > "/etc/cron.daily/catapult-mysql.cron" << EOF
#!/bin/bash

/bin/mysqlcheck --user maintenance --all-databases --auto-repair --check-only-changed --optimize --silent
EOF
    chmod 755 "/etc/cron.daily/catapult-mysql.cron"
fi



echo -e "\n> configuring weekly cron task: system reboot"
touch "/etc/cron.weekly/catapult-reboot.cron"
cat > "/etc/cron.weekly/catapult-reboot.cron" << EOF
#!/bin/bash

kernel_running=$(uname --release)
kernel_running="kernel-${kernel_running}"
kernel_staged=$(rpm --last --query kernel | head --lines 1 | awk '{print $1}')
if [ "${kernel_running}" != "${kernel_staged}" ]; then
    /sbin/reboot
fi
EOF
chmod 755 "/etc/cron.weekly/catapult-reboot.cron"



echo -e "=> anacron configuration"
cat /etc/anacrontab

echo -e "=> cron hourly"
ls /etc/cron.hourly/

echo -e "=> cron daily"
ls /etc/cron.daily/

echo -e "=> cron monthly"
ls /etc/cron.monthly/

echo -e "=> cron log"
tail /var/log/cron
