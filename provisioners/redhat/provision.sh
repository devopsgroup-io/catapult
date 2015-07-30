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
settings_software_validation=$3
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
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    repo=$(echo "$key" | grep -w "repo" | cut -d ":" -f 2,3 | tr -d " ")
    echo -e "\nNOTICE: $domain"
    if [ -d "/var/www/repositories/apache/$domain/.git" ]; then
        if [ "$(cd /var/www/repositories/apache/$domain && git config --get remote.origin.url)" != "$repo" ]; then
            echo "the repo has changed in configuration.yml, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git clone --recursive -b $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
        elif [ "$(cd /var/www/repositories/apache/$domain && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/$domain && git rev-list origin/master | tail -n 1 )" ]; then
            echo "the repo has changed, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git clone --recursive -b $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
        elif [ "$settings_git_pull" = true ]; then
            cd /var/www/repositories/apache/$domain && git checkout $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch)
            cd /var/www/repositories/apache/$domain && sudo ssh-agent bash -c "ssh-add /vagrant/provisioners/.ssh/id_rsa; git pull origin $(cat /vagrant/configuration.yml | shyaml get-value environments.$1.branch)" | sed "s/^/\t/"
        elif [ "$settings_git_pull" = false ]; then
            echo "[provisioner argument false!] skipping git pull" | sed "s/^/\t/"
        fi
    else
        if [ -d "/var/www/repositories/apache/$domain" ]; then
            echo "the .git folder is missing, removing the directory and re-cloning the repository." | sed "s/^/\t/"
            sudo chmod 0777 -R /var/www/repositories/apache/$domain
            sudo rm -rf /var/www/repositories/apache/$domain
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
redhat_ip="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat.ip)"
redhat_mysql_ip="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(cat /vagrant/configuration.yml | shyaml get-value company.email)"
cloudflare_api_key="$(cat /vagrant/configuration.yml | shyaml get-value company.cloudflare_api_key)"
cloudflare_email="$(cat /vagrant/configuration.yml | shyaml get-value company.cloudflare_email)"

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

# start fresh remove all logs, vhosts, and kill the welcome file
sudo rm -rf /var/log/httpd/*
sudo rm -rf /etc/httpd/sites-available/*
sudo rm -rf /etc/httpd/sites-enabled/*
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

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
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    # configure apache
    if [ "$1" = "production" ]; then
        echo -e "\nNOTICE: ${domain}"
    else
        echo -e "\nNOTICE: ${1}.${domain}"
    fi

    # configure cloudflare dns
    if [ "$1" != "dev" ]; then
        echo -e "\t * configuring cloudflare dns"
        IFS=. read -a domain_levels <<< "$domain"
        if [ "${#domain_levels[@]}" = "2" ]; then

            # ie: $domain_levels[0] => devopsgroup, $domain_levels[1] => io

            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[0]}.${domain_levels[1]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[0]}.${domain_levels[1]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        elif [ "${#domain_levels[@]}" = "3" ]; then

            # ie: $domain_levels[0] => drupal7, $domain_levels[1] => devopsgroup, $domain_levels[2] => io
        
            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[1]}.${domain_levels[2]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[1]}.${domain_levels[2]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[1]}.${domain_levels[2]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        fi

        # set cloudflare ssl setting per zone
        curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/ssl"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"value\":\"full\"}"\
        | sed "s/^/\t\t/"

        # set cloudflare tls setting per zone
        curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/tls_client_auth"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"value\":\"on\"}"\
        | sed "s/^/\t\t/"

        # purge cloudflare cache per zone
        echo "clearing cloudflare cache" | sed "s/^/\t\t/"
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"purge_everything\":true}"\
        | sed "s/^/\t\t/"

        # throw a new line
        echo -e "\n"

    fi

    # configure vhost
    echo -e "\t * configuring vhost"
    sudo mkdir -p /var/log/httpd/${domain_environment}
    sudo touch /var/log/httpd/${domain_environment}/access.log
    sudo touch /var/log/httpd/${domain_environment}/error.log
    if [ "${force_https}" = true ]; then
        # rewrite all http traffic to https
        force_https_value="Redirect Permanent / https://${domain_environment}"
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
        </VirtualHost>
    </IfModule>

    # allow .htaccess in apache 2.4+
    <Directory "/var/www/repositories/apache/$domain/${webroot}">
        AllowOverride All
        Options -Indexes +FollowSymlinks
    </Directory>

    # deny access to _sql folders
    <Directory "/var/www/repositories/apache/$domain/${webroot}_sql">
        Order Deny,Allow
        Deny From All
    </Directory>

EOF

    # enable vhost
    sudo ln -s /etc/httpd/sites-available/$domain_environment.conf /etc/httpd/sites-enabled/$domain_environment.conf

    # configure software
    if [ "$software" = "codeigniter2" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
            fi
            sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" /vagrant/provisioners/redhat/installers/codeigniter2_database.php > "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    elif [ "$software" = "drupal6" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" /vagrant/provisioners/redhat/installers/drupal6_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            echo -e "\t\trysncing $software ~/sites/default/files/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.redhat.ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.test.servers.redhat.ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
                echo "$software core-requirements:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
                echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
            fi
    elif [ "$software" = "drupal7" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" /vagrant/provisioners/redhat/installers/drupal7_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            echo -e "\t\trysncing $software ~/sites/default/files/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.redhat.ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.test.servers.redhat.ip):/var/www/html/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
                echo "$software core-requirements:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
                echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
                cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
            fi
    elif [ "$software" = "wordpress" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}wp-config.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            fi
            sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" -e "s/username_here/${mysql_user}/g" -e "s/password_here/${mysql_user_password}/g" -e "s/localhost/${redhat_mysql_ip}/g" -e "s/'wp_'/'${software_dbprefix}'/g" /vagrant/provisioners/redhat/installers/wp-config.php > "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            echo -e "\t\trysncing $software ~/wp-content/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.production.servers.redhat.ip):/var/www/html/${domain}/${webroot}wp-content/ /var/www/repositories/apache/${domain}/${webroot}wp-content/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete --verbose -e "ssh -oStrictHostKeyChecking=no -i /vagrant/provisioners/.ssh/id_rsa" root@$(cat /vagrant/configuration.yml | shyaml get-value environments.test.servers.redhat.ip):/var/www/html/${domain}/${webroot}wp-content/ /var/www/repositories/apache/${domain}/${webroot}wp-content/ 2>&1 | sed "s/^/\t\t/"
            fi
            if [ "$settings_software_validation" = false ]; then
                echo -e "\t\t[provisioner argument false!] skipping $software information"
            else
                echo "$software core version:" | sed "s/^/\t/\t"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core version 2>&1 | sed "s/^/\t\t\t/"
                echo "$software core verify-checksums:" | sed "s/^/\t\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core verify-checksums 2>&1 | sed "s/^/\t\t\t/"
                echo "$software core check-update:" | sed "s/^/\t\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core check-update 2>&1 | sed "s/^/\t\t\t/"
                echo "$software plugin list:" | sed "s/^/\t\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" plugin list 2>&1 | sed "s/^/\t\t\t/"
                echo "$software theme list:" | sed "s/^/\t\t/"
                php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" theme list 2>&1 | sed "s/^/\t\t\t/"
            fi
    elif [ "$software" = "xenforo" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}library/config.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
            fi
            sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" /vagrant/provisioners/redhat/installers/xenforo_config.php > "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
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
