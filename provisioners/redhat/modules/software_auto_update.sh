source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)

# only auto-update if the tools are available
if hash composer 2>/dev/null && hash drush 2>/dev/null && hash wp-cli 2>/dev/null; then

    # run software auto update operations
    if ([ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ] && [ "${software_auto_update}" = "True" ]) || ([ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_auto_update}" = "True" ]); then
        
        echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, performing an auto update..."

        if [ "$software" = "codeigniter2" ]; then

            : #no-op

        elif [ "$software" = "codeigniter3" ]; then

            : #no-op

        elif [ "$software" = "drupal6" ]; then

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-refresh
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-updatecode

        elif [ "$software" = "drupal7" ]; then

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-refresh
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-updatecode

        elif [ "$software" = "joomla3" ]; then

            #@todo - joomla updates from the admin, cli option?
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update
            : #no-op

        elif [ "$software" = "laravel5" ]; then

            #@todo - automate the manual https://www.laravel.com/docs/master/upgrade
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update
            : #no-op

        elif [ "$software" = "mediawiki1" ]; then

            #@todo - automate the manual https://www.mediawiki.org/wiki/Manual:Upgrading
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update
            : #no-op

        elif [ "$software" = "moodle3" ]; then

           cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/upgrade.php --non-interactive

        elif [ "$software" = "silverstripe3" ]; then

            #@todo - dependency management is going to be a challenge, the blanket ^3.0 requirement does not work, versions need to match. also, swap needed to be bumped up from 256 to 1024MB.
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer require "silverstripe/cms:^3.0" "silverstripe/framework:^3.0" "silverstripe/reports:^3.0" "silverstripe/siteconfig:^3.0" --no-update
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update
            : #no-op

        elif [ "$software" = "suitecrm7" ]; then

            #@todo - automote https://suitecrm.com/wiki/index.php/Upgrade
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update
            : #no-op

        elif [ "$software" = "wordpress" ]; then

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root core update

        elif [ "$software" = "xenforo" ]; then

            : #no-op

        elif [ "$software" = "zendframework2" ]; then

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer require "zendframework/zendframework:^2.0" --no-update
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else

            echo "\t* this software does not have any database operations to perform, skipping auto update..."

        fi

    else

        echo -e "\t* workflow is set to ${software_workflow}, this is the ${1} environment, and software_auto_update is not configured; skipping auto update..."

    fi

else

    echo -e "\t* software tools have yet to be installed, skipping..."

fi

touch "/catapult/provisioners/redhat/logs/software_auto_update.$(catapult websites.apache.$5.domain).complete"
