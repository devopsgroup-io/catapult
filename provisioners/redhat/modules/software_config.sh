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
domainvaliddbname=$(catapult websites.apache.$5.domain | tr "." "_")
software=$(catapult websites.apache.$5.software)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
webroot=$(catapult websites.apache.$5.webroot)
database_config_file=$(provisioners software.apache.${software}.database_config_file)

# generate database config files
if [ "${software}" = "codeigniter2" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" \
        -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" \
        -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" \
        -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" \
        -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "codeigniter3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/'hostname'\s=>\s'localhost'/'hostname' => '${redhat_mysql_ip}'/g" \
        -e "s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        -e "s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        -e "s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
        -e "s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/database.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "drupal6" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
    sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "drupal7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
    sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/settings.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "expressionengine3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/'hostname'\s=>\s''/'hostname' => '${redhat_mysql_ip}'/g" \
        -e "s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        -e "s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        -e "s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
        -e "s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "joomla3" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/public\s\$host\s=\s'';/public \$host = '${redhat_mysql_ip}';/g" \
        -e "s/public\s\$user\s=\s'';/public \$user = '${mysql_user}';/g" \
        -e "s/public\s\$password\s=\s'';/public \$password = '${mysql_user_password}';/g" \
        -e "s/public\s\$db\s=\s'';/public \$db = '${1}_${domainvaliddbname}';/g" \
        -e "s/public\s\$dbprefix\s=\s'';/public \$dbprefix = '${software_dbprefix}';/g" \
        -e "s/public\s\$log_path\s=\s'';/public \$log_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}logs';/g" \
        -e "s/public\s\$tmp_path\s=\s'';/public \$tmp_path = '\\/var\\/www\\/repositories\\/apache\\/${domain}\\/${webroot}tmp';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/configuration.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "silverstripe" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    connectionstring="\$databaseConfig = array(\"type\" => \"MySQLDatabase\",\"server\" => \"${redhat_mysql_ip}\",\"username\" => \"${mysql_user}\",\"password\" => \"${mysql_user_password}\",\"database\" => \"${1}_${domainvaliddbname}\");"
    sed -e "s/\$databaseConfig\s=\sarray();/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/${software}/_config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "suitecrm7" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/\$sugar_config\['dbconfig'\]\['db_host_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_host_name'\] = '${redhat_mysql_ip}';/g" \
        -e "s/\$sugar_config\['dbconfig'\]\['db_user_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_user_name'\] = '${mysql_user}';/g" \
        -e "s/\$sugar_config\['dbconfig'\]\['db_password'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_password'\] = '${mysql_user_password}';/g" \
        -e "s/\$sugar_config\['dbconfig'\]\['db_name'\]\s=\s'';/\$sugar_config\['dbconfig'\]\['db_name'\] = '${1}_${domainvaliddbname}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config_override.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "wordpress" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" \
        -e "s/username_here/${mysql_user}/g" \
        -e "s/password_here/${mysql_user_password}/g" \
        -e "s/localhost/${redhat_mysql_ip}/g" \
        -e "s/'wp_'/'${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/${software}/wp-config.php > "${file}"
    sudo chmod 0444 "${file}"

elif [ "${software}" = "xenforo" ]; then

    file="/var/www/repositories/apache/${domain}/${webroot}${database_config_file}"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    else
        mkdir --parents $(dirname "${file}")
    fi
    sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" \
        -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" \
        -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" \
        -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" \
        /catapult/provisioners/redhat/installers/software/${software}/config.php > "${file}"
    sudo chmod 0444 "${file}"
fi

# set directory permissions of software file store containers
if [ -z "$(provisioners_array software.apache.${software}.file_store_containers)" ]; then
    echo "this software has no file store containers"
else
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_store_containers |
    while read -r -d $'\0' file_store_container; do

        file_store_container="/var/www/repositories/apache/${domain}/${webroot}${file_store_container}"
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
