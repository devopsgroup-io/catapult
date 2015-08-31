mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.ip)"

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    if [ -z "${software}" ]; then
        echo -e "\t * no database configuration file needed, skipping..."
    elif [ "${software}" = "codeigniter2" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}application/config/database.php..."
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
        fi
        sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" /catapult/provisioners/redhat/installers/codeigniter2_database.php > "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    elif [ "${software}" = "drupal6" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php..."
        connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
        fi
        sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal6_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
    elif [ "${software}" = "drupal7" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php..."
        connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
        fi
        sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal7_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
    elif [ "${software}" = "silverstripe" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}mysite/_config.php..."
        connectionstring="\$databaseConfig = array(\"type\" => \"MySQLDatabase\",\"server\" => \"${redhat_mysql_ip}\",\"username\" => \"${mysql_user}\",\"password\" => \"${mysql_user_password}\",\"database\" => \"${1}_${domainvaliddbname}\");"
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}mysite/_config.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}mysite/_config.php"
        fi
        sed -e "s/\$databaseConfig\s=\sarray();/${connectionstring}/g" /catapult/provisioners/redhat/installers/silverstripe__config.php > "/var/www/repositories/apache/${domain}/${webroot}mysite/_config.php"
    elif [ "${software}" = "wordpress" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}library/config.php..."
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}wp-config.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
        fi
        sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" -e "s/username_here/${mysql_user}/g" -e "s/password_here/${mysql_user_password}/g" -e "s/localhost/${redhat_mysql_ip}/g" -e "s/'wp_'/'${software_dbprefix}'/g" /catapult/provisioners/redhat/installers/wp-config.php > "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
    elif [ "${software}" = "xenforo" ]; then
        echo -e "\t * generating ${software} /var/www/repositories/apache/${domain}/${webroot}library/config.php..."
        if [ -f "/var/www/repositories/apache/${domain}/${webroot}library/config.php" ]; then
            sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
        fi
        sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" /catapult/provisioners/redhat/installers/xenforo_config.php > "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
    fi

done
