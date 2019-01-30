source "/catapult/provisioners/redhat/modules/catapult.sh"

mysql_user="$(catapult environments.${1}.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(catapult environments.${1}.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(catapult environments.${1}.servers.redhat_mysql.mysql.root_password)"
if [ "${1}" == "dev" ]; then
    redhat_mysql_ip="$(catapult environments.${1}.servers.redhat_mysql.ip)"
else
    redhat_mysql_ip="$(catapult environments.${1}.servers.redhat_mysql.ip_private)"
fi

domain=$(catapult websites.apache.$5.domain)
domain_environment=$(catapult websites.apache.$5.domain)
if [ "$1" != "production" ]; then
    domain_environment="${1}.${domain_environment}"
fi
domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
# get the final domain for the environment
if [ -z "${domain_tld_override}" ]; then
    if [ "${1}" = "production" ]; then
        domain_expanded="${domain}"
    else
        domain_expanded="${1}.${domain}"
    fi
else
    if [ "${1}" = "production" ]; then
        domain_expanded="${domain}.${domain_tld_override}"
    else
        domain_expanded="${1}.${domain}.${domain_tld_override}"
    fi
fi
force_https=$(catapult websites.apache.$5.force_https)
if [ "${force_https}" = "True" ]; then
    domain_expanded_protocol="https:\\/\\/${domain_expanded}"
else
    domain_expanded_protocol="http:\\/\\/${domain_expanded}"
fi
domain_valid_db_name=$(catapult websites.apache.$5.domain | tr "." "_" | tr "-" "_")
domain_valid_regex="$(catapult websites.apache.$5.domain | sed 's/\./\\\\\./g' | sed 's/\-/\\\\\-/g')"
software=$(catapult websites.apache.$5.software)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
softwareroot=$(provisioners software.apache.${software}.softwareroot)
unique_hash=$(dmidecode -s system-uuid)
webroot=$(catapult websites.apache.$5.webroot)
database_config_file=$(provisioners software.apache.${software}.database_config_file)


# generate software database config files
# set website software logging and debug output
if ([ ! -z "${software}" ]); then
    echo -e "* generating ${software} database config file and configuring software-specific logging and debug output..."
fi

if [ "${software}" = "codeigniter2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" \
        --expression="s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domain_valid_db_name}';/g" \
        --expression="s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "codeigniter3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'hostname'\s=>\s'localhost'/'hostname' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domain_valid_db_name}'/g" \
        --expression="s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "concrete58" ]; then

    # set correct php version for concrete5 cli
    sudo chmod 744 "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}/concrete/bin/concrete5"
    sed --in-place --expression "s#\#\!/usr/bin/env\sphp#\#\!/usr/bin/env /opt/rh/rh-php71/root/usr/bin/php#g" "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}/concrete/bin/concrete5"

    # if concrete5 is not installed, then site_install.php and site_install_user.php are used
    # if concrete5 is installed, then database.php is used
    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    file_site_install="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}/application/config/site_install.php"
    file_site_install_user="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}/application/config/site_install_user.php"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
        sed --expression="s/database_name_here/${1}_${domain_valid_db_name}/g" \
            --expression="s/username_here/${mysql_user}/g" \
            --expression="s/password_here/${mysql_user_password}/g" \
            --expression="s/localhost/${redhat_mysql_ip}/g" \
            /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
        sudo chmod 0444 "${file}"
    else
        mkdir --parents $(dirname "${file_site_install}")
        sed --expression="s/database_name_here/${1}_${domain_valid_db_name}/g" \
            --expression="s/username_here/${mysql_user}/g" \
            --expression="s/password_here/${mysql_user_password}/g" \
            --expression="s/localhost/${redhat_mysql_ip}/g" \
            /catapult/provisioners/redhat/installers/software/${software}/site_install.php > "${file_site_install}"
        cp "${file_site_install}" "${file_site_install_user}"
        sudo chmod 0444 "${file_site_install}"
        sudo chmod 0444 "${file_site_install_user}"
    fi

    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.log.emails 1 --allow-as-root
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.log.errors 1 --allow-as-root
    if ([ "$1" = "dev" ] || [ "$1" = "test" ]); then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.display_errors 1 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.detail debug --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.error_reporting 1 --allow-as-root
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.display_errors 0 --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.detail message --allow-as-root
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && concrete/bin/concrete5 c5:config set concrete.debug.error_reporting 0 --allow-as-root
    fi

elif [ "${software}" = "drupal6" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domain_valid_db_name}"
    sed --expression="s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "drupal7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domain_valid_db_name}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
    sed --expression="s/\$databases\s=\sarray();/${connectionstring}/g" \
        --expression="s/\$drupal_hash_salt\s=\s'';/\$drupal_hash_salt = '${unique_hash}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

    if ([ "$1" = "dev" ] || [ "$1" = "test" ]); then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set error_level 2
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --always-set variable-set error_level 0
    fi

elif [ "${software}" = "drupal8" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    # @todo: the sed delimiter was updated from / to ~ to accomodate for the ${webroot}'s "/" - plan to persist the ~ delimiter
    connectionstring="\$databases['default']['default'] = ['driver' => 'mysql','database' => '${1}_${domain_valid_db_name}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}'];"
    sed --expression="s/\$databases\s=\s\[\];/${connectionstring}/g" \
        --expression="s/\$settings\['hash_salt'\]\s=\s'';/\$settings['hash_salt'] = '${unique_hash}';/g" \
        --expression="s~\$config_directories\s=\s\[\];~\$config_directories = [CONFIG_SYNC_DIRECTORY => '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}sites\\/default\\/files\\/sync'];~g" \
        --expression="s/\$settings\['trusted_host_patterns'\]\s=\s\[\];/\$settings['trusted_host_patterns'] = ['^${domain_valid_regex}','^.+\\\.${domain_valid_regex}'];/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"

    # create the drupal 8 sync directory
    mkdir --parents "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/sync"

    # drupal 8 requires the config file to be writable for installation
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush status bootstrap | grep -q Successful
    if [ $? -eq 0 ]; then
        sudo chmod 0444 "${file}"
    fi

    if ([ "$1" = "dev" ] || [ "$1" = "test" ]); then
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.logging error_level verbose
    else
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" && drush --yes config-set system.logging error_level hide
    fi

elif [ "${software}" = "elgg1" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/{{dbuser}}/${mysql_user}/g" \
        --expression="s/{{dbpassword}}/${mysql_user_password}/g" \
        --expression="s/{{dbname}}/${1}_${domain_valid_db_name}/g" \
        --expression="s/{{dbhost}}/${redhat_mysql_ip}/g" \
        --expression="s/{{dbprefix}}/${software_dbprefix}/g" \
        --expression="s/{{dataroot}}/\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}dataroot/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "elgg2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/{{dbuser}}/${mysql_user}/g" \
        --expression="s/{{dbpassword}}/${mysql_user_password}/g" \
        --expression="s/{{dbname}}/${1}_${domain_valid_db_name}/g" \
        --expression="s/{{dbhost}}/${redhat_mysql_ip}/g" \
        --expression="s/{{dbprefix}}/${software_dbprefix}/g" \
        --expression="s/{{dataroot}}/\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}dataroot/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "expressionengine3" ]; then

    # https://docs.expressionengine.com/latest/general/system_configuration_overrides.html

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'hostname'\s=>\s''/'hostname' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domain_valid_db_name}'/g" \
        --expression="s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        --expression="s/\$config\['avatar_url'\]\s=\s'';/\$config\['avatar_url'\] = '${domain_expanded_protocol}\\/images\\/avatars';/g" \
        --expression="s/\$config\['captcha_url'\]\s=\s'';/\$config\['captcha_url'\] = '${domain_expanded_protocol}\\/images\\/captchas';/g" \
        --expression="s/\$config\['cookie_domain'\]\s=\s'';/\$config\['cookie_domain'\] = '.${domain_expanded}';/g" \
        --expression="s/\$config\['cp_url'\]\s=\s'';/\$config\['cp_url'\] = '${domain_expanded_protocol}\\/admin.php';/g" \
        --expression="s/\$config\['emoticon_url'\]\s=\s'';/\$config\['emoticon_url'\] = '${domain_expanded_protocol}\\/images\\/smileys';/g" \
        --expression="s/\$config\['sig_img_url'\]\s=\s'';/\$config\['sig_img_url'\] = '${domain_expanded_protocol}\\/images\\/signatures';/g" \
        --expression="s/\$config\['site_url'\]\s=\s'';/\$config\['site_url'\] = '${domain_expanded_protocol}';/g" \
        --expression="s/\$config\['theme_folder_url'\]\s=\s'';/\$config\['theme_folder_url'\] = '${domain_expanded_protocol}\\/themes';/g" \
        --expression="s/\$config\['new_relic_app_name'\]\s=\s'';/\$config\['new_relic_app_name'\] = '${domain_environment}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "joomla3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/public\s\$host\s=\s'';/public \$host = '${redhat_mysql_ip}';/g" \
        --expression="s/public\s\$user\s=\s'';/public \$user = '${mysql_user}';/g" \
        --expression="s/public\s\$password\s=\s'';/public \$password = '${mysql_user_password}';/g" \
        --expression="s/public\s\$db\s=\s'';/public \$db = '${1}_${domain_valid_db_name}';/g" \
        --expression="s/public\s\$dbprefix\s=\s'';/public \$dbprefix = '${software_dbprefix}';/g" \
        --expression="s/public\s\$log_path\s=\s'';/public \$log_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}logs';/g" \
        --expression="s/public\s\$tmp_path\s=\s'';/public \$tmp_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}tmp';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/configuration.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "laravel5" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/env('DB_HOST',\s'localhost')/'${redhat_mysql_ip}'/g" \
        --expression="s/env('DB_DATABASE',\s'forge')/'${1}_${domain_valid_db_name}'/g" \
        --expression="s/env('DB_USERNAME',\s'forge')/'${mysql_user}'/g" \
        --expression="s/env('DB_PASSWORD',\s'')/'${mysql_user_password}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "mediawiki1" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$wgScriptPath\s=\s\"\";/\$wgScriptPath = \"${domain_expanded_protocol}\";/g" \
        --expression="s/\$wgDBserver\s=\s\"\";/\$wgDBserver = \"${redhat_mysql_ip}\";/g" \
        --expression="s/\$wgDBname\s=\s\"\";/\$wgDBname = \"${1}_${domain_valid_db_name}\";/g" \
        --expression="s/\$wgDBuser\s=\s\"\";/\$wgDBuser = \"${mysql_user}\";/g" \
        --expression="s/\$wgDBpassword\s=\s\"\";/\$wgDBpassword = \"${mysql_user_password}\";/g" \
        --expression="s/\$wgDBprefix\s=\s\"\";/\$wgDBprefix = \"${software_dbprefix}\";/g" \
        /catapult/provisioners/redhat/installers/software/${software}/LocalSettings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "moodle3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$CFG->dbhost\s=\s'localhost';/\$CFG->dbhost = '${redhat_mysql_ip}';/g" \
        --expression="s/\$CFG->dbname\s=\s'moodle';/\$CFG->dbname = '${1}_${domain_valid_db_name}';/g" \
        --expression="s/\$CFG->dbuser\s=\s'username';/\$CFG->dbuser = '${mysql_user}';/g" \
        --expression="s/\$CFG->dbpass\s=\s'password';/\$CFG->dbpass = '${mysql_user_password}';/g" \
        --expression="s/\$CFG->prefix\s=\s'mdl_';/\$CFG->prefix = '${software_dbprefix}';/g" \
        --expression="s/\$CFG->wwwroot\s=\s'';/\$CFG->wwwroot = '${domain_expanded_protocol}';/g" \
        --expression="s/\$CFG->dataroot\s=\s'moodledata';/\$CFG->dataroot = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}moodledata';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "silverstripe3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'server'\s=>\s''/'server' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domain_valid_db_name}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/_config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "suitecrm7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$sugar_config\['dbconfig'\]\['db_host_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_host_name'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_user_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_user_name'\] = '${mysql_user}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_password'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_name'\] = '${1}_${domain_valid_db_name}';/g" \
        --expression="s/\$sugar_config\['site_url'\]\s=\s'';/\$sugar_config\['site_url'\] = '${domain_expanded_protocol}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config_override.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "wordpress4" ]; then

    if ([ "$1" = "dev" ] || [ "$1" = "test" ]); then
        debug="true"
    else
        debug="false"
    fi
    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/database_name_here/${1}_${domain_valid_db_name}/g" \
        --expression="s/username_here/${mysql_user}/g" \
        --expression="s/password_here/${mysql_user_password}/g" \
        --expression="s/localhost/${redhat_mysql_ip}/g" \
        --expression="s/'wp_'/'${software_dbprefix}'/g" \
        --expression="s/'put your unique phrase here'/'${unique_hash}'/g" \
        --expression="s/false/${debug}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/wp-config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "wordpress5" ]; then

    if ([ "$1" = "dev" ] || [ "$1" = "test" ]); then
        debug="true"
    else
        debug="false"
    fi
    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/database_name_here/${1}_${domain_valid_db_name}/g" \
        --expression="s/username_here/${mysql_user}/g" \
        --expression="s/password_here/${mysql_user_password}/g" \
        --expression="s/localhost/${redhat_mysql_ip}/g" \
        --expression="s/'wp_'/'${software_dbprefix}'/g" \
        --expression="s/'put your unique phrase here'/'${unique_hash}'/g" \
        --expression="s/false/${debug}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/wp-config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "xenforo1" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" \
        --expression="s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domain_valid_db_name}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "xenforo2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" \
        --expression="s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domain_valid_db_name}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "zendframework2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/zf2tutorial/${1}_${domain_valid_db_name}/g" \
        --expression="s/localhost/${redhat_mysql_ip}/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/global.php > "${file}"
    sudo chmod 0444 "${file}"

fi


touch "/catapult/provisioners/redhat/logs/software_config.$(catapult websites.apache.$5.domain).complete"
