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
domainvaliddbname=$(catapult websites.apache.$5.domain | tr "." "_")
software=$(catapult websites.apache.$5.software)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
softwareroot=$(provisioners software.apache.${software}.softwareroot)
webroot=$(catapult websites.apache.$5.webroot)
database_config_file=$(provisioners software.apache.${software}.database_config_file)

# generate database config files
if [ "${software}" = "codeigniter2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" \
        --expression="s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" \
        --expression="s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "codeigniter3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'hostname'\s=>\s'localhost'/'hostname' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
        --expression="s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "drupal6" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
    sed --expression="s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "drupal7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
    sed --expression="s/\$databases\s=\sarray();/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "expressionengine3" ]; then

    # https://docs.expressionengine.com/latest/general/system_configuration_overrides.html

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'hostname'\s=>\s''/'hostname' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
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
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/public\s\$host\s=\s'';/public \$host = '${redhat_mysql_ip}';/g" \
        --expression="s/public\s\$user\s=\s'';/public \$user = '${mysql_user}';/g" \
        --expression="s/public\s\$password\s=\s'';/public \$password = '${mysql_user_password}';/g" \
        --expression="s/public\s\$db\s=\s'';/public \$db = '${1}_${domainvaliddbname}';/g" \
        --expression="s/public\s\$dbprefix\s=\s'';/public \$dbprefix = '${software_dbprefix}';/g" \
        --expression="s/public\s\$log_path\s=\s'';/public \$log_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}logs';/g" \
        --expression="s/public\s\$tmp_path\s=\s'';/public \$tmp_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}tmp';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/configuration.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "laravel5" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/env('DB_HOST',\s'localhost')/'${redhat_mysql_ip}'/g" \
        --expression="s/env('DB_DATABASE',\s'forge')/'${1}_${domainvaliddbname}'/g" \
        --expression="s/env('DB_USERNAME',\s'forge')/'${mysql_user}'/g" \
        --expression="s/env('DB_PASSWORD',\s'')/'${mysql_user_password}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "mediawiki1" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$wgScriptPath\s=\s\"\";/\$wgScriptPath = \"${domain_expanded_protocol}\";/g" \
        --expression="s/\$wgDBserver\s=\s\"\";/\$wgDBserver = \"${redhat_mysql_ip}\";/g" \
        --expression="s/\$wgDBname\s=\s\"\";/\$wgDBname = \"${1}_${domainvaliddbname}\";/g" \
        --expression="s/\$wgDBuser\s=\s\"\";/\$wgDBuser = \"${mysql_user}\";/g" \
        --expression="s/\$wgDBpassword\s=\s\"\";/\$wgDBpassword = \"${mysql_user_password}\";/g" \
        --expression="s/\$wgDBprefix\s=\s\"\";/\$wgDBprefix = \"${software_dbprefix}\";/g" \
        /catapult/provisioners/redhat/installers/software/${software}/LocalSettings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "moodle3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$CFG->dbhost\s=\s'localhost';/\$CFG->dbhost = '${redhat_mysql_ip}';/g" \
        --expression="s/\$CFG->dbname\s=\s'moodle';/\$CFG->dbname = '${1}_${domainvaliddbname}';/g" \
        --expression="s/\$CFG->dbuser\s=\s'username';/\$CFG->dbuser = '${mysql_user}';/g" \
        --expression="s/\$CFG->dbpass\s=\s'password';/\$CFG->dbpass = '${mysql_user_password}';/g" \
        --expression="s/\$CFG->prefix\s=\s'mdl_';/\$CFG->prefix = '${software_dbprefix}';/g" \
        --expression="s/\$CFG->wwwroot\s=\s'';/\$CFG->wwwroot = '${domain_expanded_protocol}';/g" \
        --expression="s/\$CFG->dataroot\s=\s'moodledata';/\$CFG->dataroot = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}moodledata';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "silverstripe3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/'server'\s=>\s''/'server' => '${redhat_mysql_ip}'/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        --expression="s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/_config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "suitecrm7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$sugar_config\['dbconfig'\]\['db_host_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_host_name'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_user_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_user_name'\] = '${mysql_user}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_password'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$sugar_config\['dbconfig'\]\['db_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_name'\] = '${1}_${domainvaliddbname}';/g" \
        --expression="s/\$sugar_config\['site_url'\]\s=\s'';/\$sugar_config\['site_url'\] = '${domain_expanded_protocol}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config_override.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "wordpress" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/database_name_here/${1}_${domainvaliddbname}/g" \
        --expression="s/username_here/${mysql_user}/g" \
        --expression="s/password_here/${mysql_user_password}/g" \
        --expression="s/localhost/${redhat_mysql_ip}/g" \
        --expression="s/'wp_'/'${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/wp-config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "xenforo" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" \
        --expression="s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" \
        --expression="s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" \
        --expression="s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "zendframework2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed --expression="s/zf2tutorial/${1}_${domainvaliddbname}/g" \
        --expression="s/localhost/${redhat_mysql_ip}/g" \
        --expression="s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        --expression="s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/global.php > "${file}"
    sudo chmod 0444 "${file}"

fi

# set directory permissions of software file store containers
if [ -z "$(provisioners_array software.apache.${software}.file_store_containers)" ]; then
    echo "this software has no file store containers"
else
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_store_containers |
    while read -r -d $'\0' file_store_container; do

        file_store_container="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store_container}"
        echo -e "software file store container: ${file_store_container}"

        # if the file store container does not exist, create it
        if [ ! -d "${file_store_container}" ]; then
            echo -e "- file store container does not exist, creating..."
            sudo mkdir --parents "${file_store_container}"
        fi

        # set the file store container permissions
        echo -e "- setting directory permissions..."
        if [ "$1" != "dev" ]; then
            sudo chown -R apache "${file_store_container}"
        fi
        sudo chmod -R 0700 "${file_store_container}"
    done

fi

touch "/catapult/provisioners/redhat/logs/software_config.$(catapult websites.apache.$5.domain).complete"
