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

# generate database config files
if [ -z "${software}" ]; then
    echo -e "no database configuration file needed, skipping..."
elif [ "${software}" = "codeigniter2" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" \
        -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" \
        -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" \
        -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" \
        -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" \
        /catapult/provisioners/redhat/installers/software/codeigniter2/database.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "codeigniter3" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    sed -e "s/'hostname'\s=>\s'localhost'/'hostname' => '${redhat_mysql_ip}'/g" \
        -e "s/'username'\s=>\s''/'username' => '${mysql_user}'/g" \
        -e "s/'password'\s=>\s''/'password' => '${mysql_user_password}'/g" \
        -e "s/'database'\s=>\s''/'database' => '${1}_${domainvaliddbname}'/g" \
        -e "s/'dbprefix'\s=>\s''/'dbprefix' => '${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/codeigniter3/database.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "drupal6" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
    sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/drupal6/settings.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "drupal7" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
    sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/drupal7/settings.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "silverstripe" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}mysite/_config.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    connectionstring="\$databaseConfig = array(\"type\" => \"MySQLDatabase\",\"server\" => \"${redhat_mysql_ip}\",\"username\" => \"${mysql_user}\",\"password\" => \"${mysql_user_password}\",\"database\" => \"${1}_${domainvaliddbname}\");"
    sed -e "s/\$databaseConfig\s=\sarray();/${connectionstring}/g" \
        /catapult/provisioners/redhat/installers/software/silverstripe/_config.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "wordpress" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" \
        -e "s/username_here/${mysql_user}/g" \
        -e "s/password_here/${mysql_user_password}/g" \
        -e "s/localhost/${redhat_mysql_ip}/g" \
        -e "s/'wp_'/'${software_dbprefix}'/g" \
        /catapult/provisioners/redhat/installers/software/wordpress/wp-config.php > "${file}"
    sudo chmod 0444 "${file}"
elif [ "${software}" = "xenforo" ]; then
    file="/var/www/repositories/apache/${domain}/${webroot}library/config.php"
    echo -e "generating ${software} ${file}..."
    if [ -f "${file}" ]; then
        sudo chmod 0777 "${file}"
    fi
    sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" \
        -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" \
        -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" \
        -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" \
        /catapult/provisioners/redhat/installers/software/xenforo/config.php > "${file}"
    sudo chmod 0444 "${file}"
fi

# set ownership of user generated directories
if [ "$software" = "drupal6" ]; then
    if [ -d "/var/www/repositories/apache/${domain}/${webroot}sites/default/files" ]; then
        echo -e "setting permissions for $software upload directory ~/sites/default/files"
        if [ "$1" != "dev" ]; then
            sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default
        fi
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default
    fi
elif [ "$software" = "drupal7" ]; then
    if [ -d "/var/www/repositories/apache/${domain}/${webroot}sites/default/files" ]; then
        echo -e "setting permissions for $software upload directory ~/sites/default/files"
        if [ "$1" != "dev" ]; then
            sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default
        fi
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default
    fi
elif [ "$software" = "wordpress" ]; then
    if [ -d "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads" ]; then
        echo -e "setting permissions for $software upload directory ~/wp-content/uploads"
        if [ "$1" != "dev" ]; then
            sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
        fi
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
    fi
fi

# run updatedb
if [ "$software" = "drupal6" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush updatedb -y
elif [ "$software" = "drupal7" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}" && drush updatedb -y
fi

touch "/catapult/provisioners/redhat/logs/software_config.$(catapult websites.apache.$5.domain).complete"
