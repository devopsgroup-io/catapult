source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
webroot=$(catapult websites.apache.$5.webroot)

# run software database operations
if [ "$software" = "codeigniter2" ]; then
    output=$(cd "/var/www/repositories/apache/${domain}/${webroot}" && php index.php migrate)
    if echo $output | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $output
    fi
elif [ "$software" = "codeigniter3" ]; then
    output=$(cd "/var/www/repositories/apache/${domain}/${webroot}" && php index.php migrate)
    if echo $output | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $output
    fi
elif [ "$software" = "drupal6" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush watchdog-delete all -y
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush updatedb -y
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush cache-clear all -y
elif [ "$software" = "drupal7" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush watchdog-delete all -y
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush updatedb -y
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush cache-clear all -y
elif [ "$software" = "joomla3" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php cli/garbagecron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php cli/update_cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php cli/deletefiles.php
elif [ "$software" = "suitecrm7" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php cron.php
elif [ "$software" = "wordpress" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root core update-db
    cd "/var/www/repositories/apache/${domain}/${webroot}" && php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root cache flush
else
    echo "this software does not have any database operations to perform"
fi

touch "/catapult/provisioners/redhat/logs/software_database_operations.$(catapult websites.apache.$5.domain).complete"
