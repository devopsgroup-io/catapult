source "/catapult/provisioners/redhat/modules/catapult.sh"


# create custom cron tasks
if ([ "${4}" == "apache" ] || [ "${4}" == "mysql" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_git.sh" > "/etc/cron.weekly/catapult-git.cron"
fi

if [ "${4}" == "mysql" ]; then
    # ref: https://mariadb.com/kb/en/mariadb/mysqlcheck/
    cat "/catapult/provisioners/redhat/modules/cron_mysql.sh" > "/etc/cron.weekly/catapult-mysql.cron"
fi

cat "/catapult/provisioners/redhat/modules/cron_reboot.sh" > "/etc/cron.weekly/catapult-reboot.cron"


# define cron tasks and be mindful of order
hourly=("0anacron" "0yum-hourly.cron")
daily=("0yum-daily.cron" "logrotate" "man-db.cron")
weekly=("catapult-git.cron" "catapult-mysql.cron" "catapult-reboot.cron")
monthly=()

for file in /etc/cron.hourly/*; do
    if ! [[ ${hourly[*]} =~ $(basename $file) ]]; then
        echo "removing ${file}"
        rm -rf $file
    else
        chown root:root $file
        chmod 755 $file
    fi
done

for file in /etc/cron.daily/*; do
    if ! [[ ${daily[*]} =~ $(basename $file) ]]; then
        echo "removing ${file}"
        rm -rf $file
    else
        chown root:root $file
        chmod 755 $file
    fi
done

for file in /etc/cron.weekly/*; do
    if ! [[ ${weekly[*]} =~ $(basename $file) ]]; then
        echo "removing ${file}"
        rm -rf $file
    else
        chown root:root $file
        chmod 755 $file
    fi
done

for file in /etc/cron.monthly/*; do
    if ! [[ ${monthly[*]} =~ $(basename $file) ]]; then
        echo "removing ${file}"
        rm -rf $file
    else
        chown root:root $file
        chmod 755 $file
    fi
done


echo -e "\n> anacron configuration"
cat /etc/anacrontab

echo -e "\n> cron hourly"
ls /etc/cron.hourly/

echo -e "\n> cron daily"
ls /etc/cron.daily/

echo -e "\n> cron weekly"
ls /etc/cron.weekly/

echo -e "\n> cron monthly"
ls /etc/cron.monthly/

echo -e "\n> cron log"
tail /var/log/cron
