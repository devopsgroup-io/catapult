source "/catapult/provisioners/redhat/modules/catapult.sh"


# create custom cron tasks
# security: preventive
cat "/catapult/provisioners/redhat/modules/cron_security_preventive.sh" > "/etc/cron.weekly/00catapult-security-preventive.cron"
# security: detective
cat "/catapult/provisioners/redhat/modules/cron_security_detective.sh" > "/etc/cron.weekly/01catapult-security-detective.cron"
# security: corrective
if ([ "${4}" == "apache" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_security_corrective.sh" > "/etc/cron.weekly/02catapult-security-corrective.cron"
fi
# bamboo
if ([ "${4}" == "bamboo" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_bamboo.sh" > "/etc/cron.daily/catapult-bamboo.cron"
fi
# certificates
if ([ "${4}" == "apache" ] && [ "${1}" != "dev" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_certificates.sh" > "/etc/cron.weekly/catapult-certificates.cron"
fi
# git
if ([ "${4}" == "apache" ] || [ "${4}" == "mysql" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_git.sh" > "/etc/cron.weekly/catapult-git.cron"
fi
# mail
if ([ "${4}" == "apache" ]); then
    cat "/catapult/provisioners/redhat/modules/cron_mail.sh" > "/etc/cron.daily/catapult-mail.cron"
fi
# mysql
if ([ "${4}" == "mysql" ]); then
    # ref: https://mariadb.com/kb/en/mariadb/mysqlcheck/
    cat "/catapult/provisioners/redhat/modules/cron_mysql.sh" > "/etc/cron.weekly/catapult-mysql.cron"
fi


# define cron tasks and be mindful of order
hourly=("0anacron" "0yum-hourly.cron")
daily=("0yum-daily.cron" "catapult-bamboo.cron" "catapult-mail.cron" "logrotate" "man-db.cron")
weekly=("00catapult-security-preventive.cron" "01catapult-security-detective.cron" "02catapult-security-corrective.cron" "catapult-certificates.cron" "catapult-git.cron" "catapult-mysql.cron")
monthly=()

# ensure loose set of cron tasks and set correct permissions
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
