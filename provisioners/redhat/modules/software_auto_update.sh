source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)
softwareversion=$(provisioners software.apache.${software}.version)

if ([ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ] && [ "${software_auto_update}" = "True" ]) || ([ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_auto_update}" = "True" ]); then
    software_auto_update="true"
else
    software_auto_update="false"
fi

# only auto-update if the tools are available
if hash composer 2>/dev/null && hash drush 2>/dev/null && hash wp-cli 2>/dev/null; then

    if ([ "${software_auto_update}" = "true" ] && [ "${software}" = "codeigniter2" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat system/core/CodeIgniter.php 2>/dev/null | grep "define('CI_VERSION'" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "codeigniter3" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat system/core/CodeIgniter.php 2>/dev/null | grep "define('CI_VERSION'" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "drupal6" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat modules/system/system.module 2>/dev/null | grep "define('VERSION'" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-refresh
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-updatecode

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "drupal7" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat includes/bootstrap.inc 2>/dev/null | grep "define('VERSION'" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-refresh
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush -y pm-updatecode

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "expressionengine3" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat system/ee/legacy/libraries/Core.php 2>/dev/null | grep "define('APP_VER'" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "joomla3" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat libraries/cms/version/version.php 2>/dev/null | grep "const RELEASE =" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            #@todo - joomla updates from the admin, cli option?
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "laravel5" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat vendor/laravel/framework/src/Illuminate/Foundation/Application.php 2>/dev/null | grep "const VERSION =" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            #@todo - automate the manual https://www.laravel.com/docs/master/upgrade
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "mediawiki1" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat includes/DefaultSettings.php 2>/dev/null | grep "\$wgVersion = " | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            #@todo - automate the manual https://www.mediawiki.org/wiki/Manual:Upgrading
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "moodle3" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat version.php 2>/dev/null | grep "\$release" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && php admin/cli/upgrade.php --non-interactive

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "silverstripe3" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat framework/silverstripe_version 2>/dev/null | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            #@todo - dependency management is going to be a challenge, the blanket ^3.0 requirement does not work, versions need to match. also, swap needed to be bumped up from 256 to 1024MB.
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer require "silverstripe/cms:^3.0" "silverstripe/framework:^3.0" "silverstripe/reports:^3.0" "silverstripe/siteconfig:^3.0" --no-update
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "suitecrm7" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat suitecrm_version.php 2>/dev/null | grep "\$suitecrm_version" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            #@todo - automote https://suitecrm.com/wiki/index.php/Upgrade
            #cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "wordpress" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat wp-includes/version.php 2>/dev/null | grep "\$wp_version" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root theme update --all
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root plugin update --all
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root core update
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root plugin update --all
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && wp-cli --allow-root theme update --all

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "xenforo" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat library/XenForo/Application.php 2>/dev/null | grep "public static \$version =" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    elif ([ "${software_auto_update}" = "true" ] && [ "${software}" = "zendframework2" ]); then

        version=$(cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && cat vendor/zendframework/zendframework/library/Zend/Version/Version.php 2>/dev/null | grep "const VERSION =" | grep --extended-regexp --only-matching --regexp="[0-9]\.[0-9][0-9]?[0-9]?(\.[0-9][0-9]?[0-9]?)?")

        if [ "$(grep --only-matching --regexp="^[0-9]" <<< "${version}")" = "${softwareversion}" ]; then
            echo -e "\nSUPPORTED SOFTWARE VERSION DETECTED: ${version}\n"

            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer require "zendframework/zendframework:^2.0" --no-update
            cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && composer update

        else
            echo -e "\nSUPPORTED SOFTWARE NOT DETECTED\n"
        fi

    fi

else

    echo -e "\t* software tools have yet to be installed, skipping..."

fi

touch "/catapult/provisioners/redhat/logs/software_auto_update.$(catapult websites.apache.$5.domain).complete"
