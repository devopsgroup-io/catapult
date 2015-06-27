#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive


if ! [ -e "/vagrant/configuration.yml" ]; then
    echo -e "Cannot read from /vagrant/configuration.yml, please vagrant reload the virtual machine."
    exit 1
fi


provisionstart=$(date +%s)
sudo touch /vagrant/provisioners/redhat/logs/provision.log


echo -e "==> Updating existing packages and installing utilities"
start=$(date +%s)
# set human friendly variables inbound from provisioner args
settings_environment=$1
settings_git_pull=$2
settings_production_rsync=$3
settings_software_validation=$4
# update yum
sudo yum update -y
# git clones
sudo yum install -y git
# parse yaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
end=$(date +%s)
echo "[$(date)] Updating existing packages and installing utilities ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


echo -e "\n\n==> Configuring time"
start=$(date +%s)
# set timezone
sudo timedatectl set-timezone "$(cat /vagrant/configuration.yml | shyaml get-value company.timezone_redhat)"
# configure ntp
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service
# echo datetimezone
date
end=$(date +%s)
echo "[$(date)] Configuring time ($(($end - $start)) seconds" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


echo -e "\n\n==> Installing PHP"
start=$(date +%s)
#@todo think about having directive per website that lists php module dependancies
sudo yum install -y php
sudo yum install -y php-mysql
sudo yum install -y php-curl
sudo yum install -y php-gd
sudo yum install -y php-dom
sudo yum install -y php-mbstring
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(cat /vagrant/configuration.yml | shyaml get-value company.timezone_redhat)\"#g" /etc/php.ini
end=$(date +%s)
echo "[$(date)] Installing PHP ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


echo -e "\n\n==> Installing Drush and WP-CLI"
start=$(date +%s)
sudo yum install -y php-cli # wp-cli dependancy
sudo yum install -y mariadb # drush dependeancy
# install drush
if [ ! -f /usr/bin/drush  ]; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
    cd /usr/local/src/drush
    git checkout 7.0.0-rc1
    ln -s /usr/local/src/drush/drush /usr/bin/drush
    composer install
fi
drush --version
end=$(date +%s)
echo "[$(date)] Installing Drush and WP-CLI ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


echo -e "\n\n==> Installing Apache"
start=$(date +%s)
# install httpd
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"
end=$(date +%s)
echo "[$(date)] Installing Apache ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


echo -e "\n\n==> Configuring git repositories (This may take a while...)"
start=$(date +%s)
# clone/pull necessary repos
sudo mkdir -p ~/.ssh
sudo touch ~/.ssh/known_hosts
sudo ssh-keyscan bitbucket.org > ~/.ssh/known_hosts
sudo ssh-keyscan github.com >> ~/.ssh/known_hosts
# link /vagrant/repositories to webroot if not in dev, otherwise dev will use vagrant synced folder
if [ "$1" != "dev" ]; then
    sudo ln -s /vagrant/repositories /var/www/repositories
fi
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    repo=$(echo "$key" | grep -w "repo" | cut -d ":" -f 2,3 | tr -d " ")
    echo "NOTICE: $domain"
    if [ -d "/var/www/repositories/apache/$domain/.git" ]; then
        if [ "$(cd /var/www/repositories/apache/$domain && git config --get remote.origin.url)" != "$repo" ]; then
            echo "the repo has changed in configuration.yml, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git clone --recursive -b $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
        elif [ "$(cd /vagrant/repositories/apache/$domain && git rev-list HEAD | tail -n 1 )" != "$(cd /vagrant/repositories/apache/$domain && git rev-list origin/master | tail -n 1 )" ]; then
            echo "the repo has changed, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /vagrant/repositories/apache/$domain
            git clone --recursive -b $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch) $repo /vagrant/repositories/apache/$domain | sed "s/^/\t/"
        elif [ "$settings_git_pull" = true ]; then
            cd /var/www/repositories/apache/$domain && sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git pull origin $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch)" | sed "s/^/\t/"
        elif [ "$settings_git_pull" = false ]; then
            echo "[provisioner argument false!] skipping git pull" | sed "s/^/\t/"
        fi
    else
        if [ -d "/vagrant/repositories/apache/$domain" ]; then
            echo "the .git folder is missing, removing the directory and re-cloning the repository." | sed "s/^/\t/"
            sudo chmod 0777 -R /vagrant/repositories/apache/$domain
            sudo rm -rf /vagrant/repositories/apache/$domain
        fi
        sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git clone --recursive -b $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
    fi
done < <(cat /vagrant/configuration.yml | shyaml get-values-0 websites.apache)

# create an array of domains
domains=()
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domains+=($domain)
done < <(cat /vagrant/configuration.yml | shyaml get-values-0 websites.apache)
# cleanup directories from domains array
for directory in /var/www/repositories/apache/*/; do
    domain=$(basename $directory)
    if ! [[ ${domains[*]} =~ $domain ]]; then
        echo "Website does not exist in configuration.yaml, removing $directory ..."
        sudo chmod 0777 -R $directory
        sudo rm -rf $directory
    fi
done
end=$(date +%s)
echo "[$(date)] Configuring git repositories ($(($end - $start)) seconds" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


echo -e "\n\n==> Configuring Apache"
start=$(date +%s)
# set variables from configuration.yml
mysql_user="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_mysql_ip="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(cat /vagrant/configuration.yml | shyaml get-value company.email)"
cloudflare_api_key="$(cat /vagrant/configuration.yml | shyaml get-value company.cloudflare_api_key)"
cloudflare_email="$(cat /vagrant/configuration.yml | shyaml get-value company.cloudflare_email)"

# rackspace web1 - are we connected to do rsync of drupal and wordpress files?
# one time copy ssh key to rackspace web1 while vagrant ssh redhat
# ssh-copy-id -i /vagrant/provisioners/.ssh/id_rsa.pub 172.17.100.153
# prime rackspace ping
ping -c 1 $(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ip) &> /dev/null
if ping -c 1 $(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ip) &> /dev/null
then
  rackspace=true
else
  rackspace=false
fi

# configure vhosts
# this is a debianism - but it makes things easier for cross-distro
sudo mkdir -p /etc/httpd/sites-available
sudo mkdir -p /etc/httpd/sites-enabled
if ! grep -q "IncludeOptional sites-enabled/*.conf" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "IncludeOptional sites-enabled/*.conf" >> "/etc/httpd/conf/httpd.conf"'
fi
# supress the following message
# httpd: Could not reliably determine the server's fully qualified domain name, using localhost.localdomain. Set the 'ServerName' directive globally to suppress this message
if ! grep -q "ServerName localhost" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf'
fi

# @todo mod_ssl functionality: need certificate configured

# start fresh remove all logs, vhosts, and kill the welcome file
sudo rm -rf /var/log/httpd/*
sudo rm -rf /etc/httpd/sites-available/*
sudo rm -rf /etc/httpd/sites-enabled/*
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf
sudo apachectl stop
sudo apachectl start
sudo apachectl configtest
sudo systemctl is-active httpd.service

cat /vagrant/configuration.yml | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    force_https=$(echo "$key" | grep -w "force_https" | cut -d ":" -f 2 | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    curl https://www.cloudflare.com/api_json.html \
      -d "a=full_zone_set" \
      -d "tkn=$cloudflare_api_key" \
      -d "email=$cloudflare_email" \
      -d "zone_name=$domain"

    curl https://www.cloudflare.com/api_json.html \
      -d "a=rec_new" \
      -d "tkn=$cloudflare_api_key" \
      -d "email=$cloudflare_email" \
      -d "z=$domain" \
      -d "type=A" \
      -d "name=$domain" \
      -d "content=45.55.231.36" \
      -d "ttl=1"

    # configure apache
    echo -e "NOTICE: $1.$domain"
    echo -e "\tconfiguring vhost"

    sudo mkdir -p /var/log/httpd/$domain_environment
    sudo touch /var/log/httpd/$domain_environment/access.log
    sudo touch /var/log/httpd/$domain_environment/error.log
    if [ "$force_https" = true ]; then
        # rewrite all http traffic to https
        force_https_value="Redirect Permanent / https://$domain_environment"
    else
        force_https_value=""
    fi
    sudo cat > /etc/httpd/sites-available/$domain_environment.conf << EOF

    RewriteEngine On

    # must listen * to support cloudflare
    <VirtualHost *:80>

        ServerAdmin $company_email
        ServerName $domain_environment
        ServerAlias www.$domain_environment
        DocumentRoot /var/www/repositories/apache/$domain/$webroot
        ErrorLog /var/log/httpd/$domain_environment/error.log
        CustomLog /var/log/httpd/$domain_environment/access.log combined

        $force_https_value

    </VirtualHost> 

    <IfModule mod_ssl.c>
        # must listen * to support cloudflare
        <VirtualHost *:443>

            ServerAdmin $company_email
            ServerName $domain_environment
            ServerAlias www.$domain_environment
            DocumentRoot /var/www/repositories/apache/$domain/$webroot
            ErrorLog /var/log/httpd/$domain_environment/error.log
            CustomLog /var/log/httpd/$domain_environment/access.log combined

            SSLEngine on
            SSLCertificateFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            SSLCertificateKeyFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            #<FilesMatch "\.(cgi|shtml|phtml|php)$">
            #    SSLOptions +StdEnvVars
            #</FilesMatch>
            #<Directory /usr/lib/cgi-bin>
            #    SSLOptions +StdEnvVars
            #</Directory>

        </VirtualHost>
    </IfModule>

    # allow .htaccess in apache 2.4+
    <Directory "/var/www/repositories/apache/$domain/$webroot">
        AllowOverride All
        Options -Indexes +FollowSymlinks
    </Directory>

    # deny access to _sql folders
    <Directory "/var/www/repositories/apache/$domain/$webroot_sql">
        Order Deny,Allow
        Deny From All
    </Directory>

EOF

    # enable vhost
    sudo ln -s /etc/httpd/sites-available/$domain_environment.conf /etc/httpd/sites-enabled/$domain_environment.conf

    # configure software
    if [ "$software" = "codeigniter2" ]; then
            echo -e "\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
            fi
            sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" /vagrant/provisioners/redhat/installers/codeigniter2_database.php > "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    elif [ "$software" = "drupal6" ]; then
            echo -e "\tgenerating $software database configuration file"
            connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" /vagrant/provisioners/redhat/installers/drupal6_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            if [ "$settings_production_rsync" = false ]; then
              echo -e "\t[provisioner argument false!] skipping $software ~/sites/default/files/ file sync"
            elif [ "$rackspace" = false ]; then
              echo -e "\t[not connected to rackspace vpn!] skipping $software ~/sites/default/files/ file sync"
            else
              echo -e "\tconnected to rackspace vpn - rysncing $software ~/sites/default/files/"
              rsync -rz -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" $(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ssh_user)@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/$domain/sites/default/files/
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t/"
                echo "$software core-requirements:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t/"
                echo "$software pm-updatestatus:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t/"
            fi
    elif [ "$software" = "drupal7" ]; then
            echo -e "\tgenerating $software database configuration file"
            connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" /vagrant/provisioners/redhat/installers/drupal7_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            if [ "$settings_production_rsync" = false ]; then
              echo -e "\t[provisioner argument false!] skipping $software ~/sites/default/files/ file sync"
            elif [ "$rackspace" = false ]; then
              echo -e "\t[not connected to rackspace vpn!] skipping $software ~/sites/default/files/ file sync"
            else
              echo -e "\tconnected to rackspace vpn - rysncing $software ~/sites/default/files/"
              rsync -rz -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" $(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ssh_user)@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/$domain/sites/default/files/
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t/"
                echo "$software core-requirements:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t/"
                echo "$software pm-updatestatus:" | sed "s/^/\t/"
                cd "/vagrant/repositories/apache/$domain/" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t/"
            fi
    elif [ "$software" = "wordpress" ]; then
            echo -e "\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}wp-config.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            fi
            sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" -e "s/username_here/${mysql_user}/g" -e "s/password_here/${mysql_user_password}/g" -e "s/localhost/${redhat_mysql_ip}/g" -e "s/'wp_'/'${software_dbprefix}'/g" /vagrant/provisioners/redhat/installers/wp-config.php > "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            if [ "$settings_production_rsync" = false ]; then
              echo -e "\t[provisioner argument false!] skipping $software ~/sites/default/files/ file sync"
            elif [ "$rackspace" = false ]; then
              echo -e "\t[not connected to rackspace vpn!] skipping $software ~/sites/default/files/ file sync"
            else
              echo -e "\tconnected to rackspace vpn - rysncing $software ~/wp-content/"
              rsync -rz -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" $(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ssh_user)@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.rackspace.web1_ip):/var/www/html/$domain/wp-content/ /var/www/repositories/apache/$domain/wp-content/
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" core version 2>&1 | sed "s/^/\t\t/"
                echo "$software core verify-checksums:" | sed "s/^/\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" core verify-checksums 2>&1 | sed "s/^/\t\t/"
                echo "$software core check-update:" | sed "s/^/\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" core check-update 2>&1 | sed "s/^/\t\t/"
                echo "$software plugin list:" | sed "s/^/\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" plugin list 2>&1 | sed "s/^/\t\t/"
                echo "$software theme list:" | sed "s/^/\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" theme list 2>&1 | sed "s/^/\t\t/"
            fi
    fi

done

end=$(date +%s)
echo "[$(date)] Configuring Apache ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


echo -e "\n\n==> Restarting Apache"
start=$(date +%s)
sudo apachectl stop
sudo apachectl start
sudo apachectl configtest
sudo systemctl is-active httpd.service
end=$(date +%s)
echo "[$(date)] Restarting Apache ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat/logs/provision.log


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) seconds)"
echo -e "[$(date)] Provision complete ($(($provisionend - $provisionstart)) total seconds)\n" >> /vagrant/provisioners/redhat/logs/provision.log


exit 0
