source "/catapult/provisioners/redhat/modules/catapult.sh"

mysql_user="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.root_password)"
if [ "${1}" == "dev" ]; then
    redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.ip)"
else
    redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.ip_private)"
fi

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    # generate database config files
    if [ -z "${software}" ]; then
        echo -e "\t * no database configuration file needed, skipping..."
    elif [ "${software}" = "codeigniter2" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
        echo -e "\t * generating ${software} ${file}..."
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" /catapult/provisioners/redhat/installers/codeigniter2_database.php > "${file}"
        sudo chmod 0444 "${file}"
    elif [ "${software}" = "drupal6" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
        echo -e "\t * generating ${software} ${file}..."
        connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal6_settings.php > "${file}"
        sudo chmod 0444 "${file}"
    elif [ "${software}" = "drupal7" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
        echo -e "\t * generating ${software} ${file}..."
        connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal7_settings.php > "${file}"
        sudo chmod 0444 "${file}"
    elif [ "${software}" = "silverstripe" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}mysite/_config.php"
        echo -e "\t * generating ${software} ${file}..."
        connectionstring="\$databaseConfig = array(\"type\" => \"MySQLDatabase\",\"server\" => \"${redhat_mysql_ip}\",\"username\" => \"${mysql_user}\",\"password\" => \"${mysql_user_password}\",\"database\" => \"${1}_${domainvaliddbname}\");"
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/\$databaseConfig\s=\sarray();/${connectionstring}/g" /catapult/provisioners/redhat/installers/silverstripe__config.php > "${file}"
        sudo chmod 0444 "${file}"
    elif [ "${software}" = "wordpress" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
        echo -e "\t * generating ${software} ${file}..."
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" -e "s/username_here/${mysql_user}/g" -e "s/password_here/${mysql_user_password}/g" -e "s/localhost/${redhat_mysql_ip}/g" -e "s/'wp_'/'${software_dbprefix}'/g" /catapult/provisioners/redhat/installers/wp-config.php > "${file}"
        sudo chmod 0444 "${file}"
    elif [ "${software}" = "xenforo" ]; then
        file="/var/www/repositories/apache/${domain}/${webroot}library/config.php"
        echo -e "\t * generating ${software} ${file}..."
        if [ -f "${file}" ]; then
            sudo chmod 0777 "${file}"
        fi
        sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" /catapult/provisioners/redhat/installers/xenforo_config.php > "${file}"
        sudo chmod 0444 "${file}"
    fi

    # set ownership of uploads directory in upstream servers
    if [ "$1" != "dev" ]; then
        if [ "$software" = "drupal6" ]; then
            if [ -d "/var/www/repositories/apache/${domain}/${webroot}sites/default/files" ]; then
                echo -e "\t * setting permissions for $software upload directory ~/sites/default/files"
                sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default/files
                sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default/files
            fi
        elif [ "$software" = "drupal7" ]; then
            if [ -d "/var/www/repositories/apache/${domain}/${webroot}sites/default/files" ]; then
                echo -e "\t * setting permissions for $software upload directory ~/sites/default/files"
                sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default/files
                sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default/files
            fi
        elif [ "$software" = "wordpress" ]; then
            if [ -d "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads" ]; then
                echo -e "\t * setting permissions for $software upload directory ~/wp-content/uploads"
                sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
                sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
            fi
        fi
    fi

done
