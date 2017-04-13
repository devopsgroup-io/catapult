source "/catapult/provisioners/redhat/modules/catapult.sh"

# set a variable to the .cnf
dbconf="/catapult/provisioners/redhat/installers/temp/${1}.cnf"

domain=$(catapult websites.apache.$5.domain)
domainvaliddbname=$(catapult websites.apache.$5.domain | tr "." "_" | tr "-" "_")
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)


# set site email address
# set admin credentials, email address, and role
if ([ ! -z "${software}" ]); then
    echo -e "* setting ${software} site email address..."
    echo -e "* setting ${software} admin account credentials, email address, and role..."
fi

if [ "${software}" = "drupal6" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush variable-set site_mail $(catapult company.email)

    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users (uid, pass, mail, status)
        VALUES ('1', MD5('$(catapult environments.${1}.software.drupal.admin_password)'), '$(catapult company.email)', '1')
        ON DUPLICATE KEY UPDATE name='admin', mail='$(catapult company.email)', pass=MD5('$(catapult environments.${1}.software.drupal.admin_password)'), status='1';
    "
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users_roles (uid, rid)
        VALUES ('1', '3')
        ON DUPLICATE KEY UPDATE rid='3';
    "

elif [ "${software}" = "drupal7" ]; then
    
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush variable-set site_mail $(catapult company.email)

    password_hash=$(cd "/var/www/repositories/apache/${domain}/${webroot}" && php ./scripts/password-hash.sh $(catapult environments.${1}.software.drupal.admin_password))
    password_hash=$(echo "${password_hash}" | awk '{ print $4 }' | tr -d " " | tr -d "\n")
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users (uid, pass, mail, status)
        VALUES ('1', '${password_hash}', '$(catapult company.email)', '1')
        ON DUPLICATE KEY UPDATE name='admin', mail='$(catapult company.email)', pass='${password_hash}', status='1';
    "
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users_roles (uid, rid)
        VALUES ('1', '3')
        ON DUPLICATE KEY UPDATE rid='3';
    "

elif [ "${software}" = "elgg1" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users_entity (username, password_hash, email, banned, admin)
        VALUES ('admin', MD5('$(catapult environments.${1}.software.admin_password)'), '$(catapult company.email)', 'no', 'yes')
        ON DUPLICATE KEY UPDATE username='admin', password_hash=MD5('$(catapult environments.${1}.software.admin_password)'), email='$(catapult company.email)', banned='no', admin='yes';
    "

elif [ "${software}" = "joomla3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        UPDATE ${software_dbprefix}users
        SET username='admin', email='$(catapult company.email)', password=MD5('$(catapult environments.${1}.software.admin_password)'), block='0'
        WHERE name='Super User';
    "

elif [ "${software}" = "mediawiki1" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}user (user_id, user_name, user_email)
        VALUES ('1', 'Admin', '$(catapult company.email)')
        ON DUPLICATE KEY UPDATE user_name='Admin', user_email='$(catapult company.email)';
    "
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php maintenance/changePassword.php --userid="1" --password="$(catapult environments.${1}.software.admin_password)"
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}user_groups (ug_user, ug_group)
        VALUES ('1', 'sysop')
        ON DUPLICATE KEY UPDATE ug_user=ug_user, ug_group=ug_group;
    "

elif [ "${software}" = "moodle3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        UPDATE ${software_dbprefix}user
        SET username='admin', password=MD5('$(catapult environments.${1}.software.admin_password)'), suspended='0', email='$(catapult company.email)'
        WHERE id='2';
    "

elif [ "${software}" = "silverstripe3" ]; then

    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        UPDATE ${software_dbprefix}Member
        SET FirstName='Default Admin', Email='$(catapult company.email)', Password='$(catapult environments.${1}.software.admin_password)', PasswordEncryption='none', LockedOutUntil='NULL'
        WHERE ID='1';
    "
    # a hack to encrypt the plain text password that we just set, wahoo!
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php framework/cli-script.php dev/tasks/EncryptAllPasswordsTask

elif [ "${software}" = "suitecrm7" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users (id, user_name, user_hash, is_admin)
        VALUES ('1', 'admin', MD5('$(catapult environments.${1}.software.admin_password)'), '1')
        ON DUPLICATE KEY UPDATE user_name='admin', user_hash=MD5('$(catapult environments.${1}.software.admin_password)'), is_admin='1';
    "

elif [ "${software}" = "wordpress" ]; then
    
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "UPDATE ${software_dbprefix}options SET option_value='$(catapult company.email)' WHERE option_name = 'admin_email';"
    
    mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "
        INSERT INTO ${software_dbprefix}users (id, user_login, user_pass, user_nicename, user_email, user_status, display_name)
        VALUES ('1', 'admin', MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), 'admin', '$(catapult company.email)', '0', 'admin')
        ON DUPLICATE KEY UPDATE user_login='admin', user_pass=MD5('$(catapult environments.${1}.software.wordpress.admin_password)'), user_nicename='admin', user_email='$(catapult company.email)', user_status='0', display_name='admin';
    "
    wp-cli --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" user add-role 1 administrator

fi


# run software database operations
if ([ ! -z "${software}" ]); then
    echo -e "* running ${software} log cleanup, cron, database migrations, and cache rebuilds..."
fi

if [ "${software}" = "codeigniter2" ]; then

    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "${software}" = "codeigniter3" ]; then
    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "${software}" = "drupal6" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y core-cron
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y cache-clear all

elif [ "${software}" = "drupal7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y core-cron
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y cache-clear all

elif [ "${software}" = "elgg1" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "expressionengine3" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "joomla3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/garbagecron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/update_cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/finder_indexer.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/deletefiles.php

elif [ "${software}" = "laravel5" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan key:generate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan migrate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan cache:clear
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan clear-compiled
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan optimize

elif [ "${software}" = "mediawiki1" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/update.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/runJobs.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/rebuildall.php

elif [ "${software}" = "moodle3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/purge_caches.php

elif [ "${software}" = "silverstripe3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/tasks/MigrationTask
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/build "flush=1"

elif [ "${software}" = "suitecrm7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cron.php

elif [ "${software}" = "wordpress" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root core update-db
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root cache flush

elif [ "${software}" = "xenforo" ]; then

    echo "nothing to perform, skipping..."

elif [ "${software}" = "zendframework2" ]; then

    echo "nothing to perform, skipping..."

fi

touch "/catapult/provisioners/redhat/logs/software_operations_meta.$(catapult websites.apache.$5.domain).complete"
