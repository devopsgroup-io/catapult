source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)

# run software database operations
if [ "$software" = "codeigniter2" ]; then

    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "$software" = "codeigniter3" ]; then
    result=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php index.php migrate)
    if echo $result | grep --extended-regexp --quiet --regexp="<html" --regexp="<\?"; then
        echo -e "Migrations are not configured"
    else
        echo $result
    fi

elif [ "$software" = "drupal6" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y cache-clear all

elif [ "$software" = "drupal7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y watchdog-delete all
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y updatedb
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y cache-clear all

elif [ "$software" = "elgg1" ]; then

    echo "nothing to perform, skipping..."

elif [ "$software" = "expressionengine3" ]; then

    echo "nothing to perform, skipping..."

elif [ "$software" = "joomla3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/garbagecron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/update_cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/finder_indexer.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cli/deletefiles.php

elif [ "$software" = "laravel5" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan key:generate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan migrate
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan cache:clear
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan clear-compiled
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php artisan optimize

elif [ "$software" = "mediawiki1" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/update.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/runJobs.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php maintenance/rebuildall.php

elif [ "$software" = "moodle3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/cron.php
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/purge_caches.php

elif [ "$software" = "silverstripe3" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/tasks/MigrationTask
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php framework/cli-script.php dev/build "flush=1"

elif [ "$software" = "suitecrm7" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php cron.php

elif [ "$software" = "wordpress" ]; then

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root core update-db
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root cache flush

elif [ "$software" = "xenforo" ]; then

    echo "nothing to perform, skipping..."

elif [ "$software" = "zendframework2" ]; then

    echo "nothing to perform, skipping..."

fi

touch "/catapult/provisioners/redhat/logs/software_operations_meta.$(catapult websites.apache.$5.domain).complete"
