#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance
# $5 => software_validation



echo -e "==> Updating existing packages and installing utilities"
start=$(date +%s)
# only allow authentication via ssh key pair
# suppress this - There were 34877 failed login attempts since the last successful login.
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sudo systemctl stop sshd.service
sudo systemctl start sshd.service
# update yum
sudo yum update -y
# git clones
sudo yum install -y git
# parse yaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
configuration=$(gpg --batch --passphrase ${3} --decrypt /catapult/secrets/configuration.yml.gpg)
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa --decrypt /catapult/secrets/id_rsa.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa.pub --decrypt /catapult/secrets/id_rsa.pub.gpg
chmod 700 /catapult/secrets/id_rsa
chmod 700 /catapult/secrets/id_rsa.pub
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring time"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/time.sh
provisionstart=$(date +%s)
sudo touch /catapult/provisioners/redhat/logs/apache.log
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing PHP"
start=$(date +%s)
#@todo think about having directive per website that lists php module dependancies
sudo yum install -y php
sudo yum install -y php-mysql
sudo yum install -y php-curl
sudo yum install -y php-gd
sudo yum install -y php-dom
sudo yum install -y php-mbstring
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(echo "${configuration}" | shyaml get-value company.timezone_redhat)\"#g" /etc/php.ini
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing software tools"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/software_tools.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing Apache"
start=$(date +%s)
# install httpd
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring git repositories (This may take a while...)"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/git.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> RSYNCing files"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/rsync.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Generating software database config files"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/software_database_config.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring CloudFlare"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/cloudflare.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring Apache"
start=$(date +%s)
# set variables from secrets/configuration.yml
mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat.ip)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(echo "${configuration}" | shyaml get-value company.email)"

# configure vhosts
# this is a debianism - but it makes things easier for cross-distro
sudo mkdir -p /etc/httpd/sites-available
sudo mkdir -p /etc/httpd/sites-enabled
if ! grep -q "IncludeOptional sites-enabled/*.conf" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "IncludeOptional sites-enabled/*.conf" >> "/etc/httpd/conf/httpd.conf"'
fi
# define the server's servername
# suppress this - httpd: Could not reliably determine the server's fully qualified domain name, using localhost.localdomain. Set the 'ServerName' directive globally to suppress this message
if ! grep -q "ServerName localhost" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf'
fi

# start fresh remove all logs, vhosts, and kill the welcome file
sudo rm -rf /var/log/httpd/*
sudo rm -rf /etc/httpd/sites-available/*
sudo rm -rf /etc/httpd/sites-enabled/*
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
    if [ ! -z "${domain_tld_override}" ]; then
        domain_root="${domain}.${domain_tld_override}"
    else
        domain_root="${domain}"
    fi
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
    force_auth_exclude=$(echo "$key" | grep -w "force_auth_exclude" | tr -d " ")
    force_https=$(echo "$key" | grep -w "force_https" | cut -d ":" -f 2 | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    # configure apache
    if [ "$1" = "production" ]; then
        echo -e "\nNOTICE: ${domain_root}"
    else
        echo -e "\nNOTICE: ${1}.${domain_root}"
    fi

    # configure vhost
    echo -e "\t * configuring vhost"
    sudo mkdir -p /var/log/httpd/${domain_environment}
    sudo touch /var/log/httpd/${domain_environment}/access.log
    sudo touch /var/log/httpd/${domain_environment}/error.log
    # set domain_tld_override_alias_additions for vhost
    if [ -z "${domain_tld_override}" ]; then
        domain_tld_override_alias_additions=""
    else
        domain_tld_override_alias_additions="ServerAlias ${domain_environment}.${domain_tld_override}
        ServerAlias www.${domain_environment}.${domain_tld_override}"
    fi
    # handle the force_auth option
    if ([ ! -z "${force_auth}" ]) && ([ "$1" = "test" ] || [ "$1" = "qc" ] || [ "$1" = "production" ]); then
        if ([ ! -z "${force_auth_exclude}" ]); then
            force_auth_excludes=( $(echo "${key}" | shyaml get-values force_auth_exclude) )
            if ([[ "${force_auth_excludes[@]}" =~ "$1" ]]); then
                force_auth_value=""
            else
                sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1 | sed "s/^/\t\t\t/"
                force_auth_value="<Location />
                    # Force HTTP authentication
                    AuthType Basic
                    AuthName \"Authentication Required\"
                    AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
                    Require valid-user
                </Location>"
            fi
        else
            sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1 | sed "s/^/\t\t\t/"
            force_auth_value="<Location />
                # Force HTTP authentication
                AuthType Basic
                AuthName \"Authentication Required\"
                AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
                Require valid-user
            </Location>"
        fi
    else
        # never force_auth in dev
        force_auth_value=""
    fi
    # handle the force_https option
    if [ "${force_https}" = true ]; then
        force_https_value="Redirect Permanent / https://${domain_environment}"
    else
        force_https_value=""
    fi
    # write vhost apache conf file
    sudo cat > /etc/httpd/sites-available/$domain_environment.conf << EOF

    RewriteEngine On

    <VirtualHost *:80> # must listen * to support cloudflare
        ServerAdmin $company_email
        ServerName $domain_environment
        ServerAlias www.$domain_environment
        $domain_tld_override_alias_additions
        DocumentRoot /var/www/repositories/apache/$domain/$webroot
        ErrorLog /var/log/httpd/$domain_environment/error.log
        CustomLog /var/log/httpd/$domain_environment/access.log combined
        $force_auth_value
        $force_https_value
    </VirtualHost> 

    <IfModule mod_ssl.c>
        <VirtualHost *:443> # must listen * to support cloudflare
            ServerAdmin $company_email
            ServerName $domain_environment
            ServerAlias www.$domain_environment
            DocumentRoot /var/www/repositories/apache/$domain/$webroot
            ErrorLog /var/log/httpd/$domain_environment/error.log
            CustomLog /var/log/httpd/$domain_environment/access.log combined
            SSLEngine on
            SSLCertificateFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            SSLCertificateKeyFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            $force_auth_value
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
    if [ "$software" = "drupal6" ]; then
        echo "setting permissions for $software upload directory ~/sites/default/files" | sed "s/^/\t\t/"
        sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default/files
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default/files
        echo "$software core version:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
        echo "$software core-requirements:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
        echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
    elif [ "$software" = "drupal7" ]; then
        echo "setting permissions for $software upload directory ~/sites/default/files" | sed "s/^/\t\t/"
        sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}sites/default/files
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}sites/default/files
        echo "$software core version:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
        echo "$software core-requirements:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
        echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
        cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
    elif [ "$software" = "wordpress" ]; then
        echo "setting permissions for $software upload directory ~/wp-content/uploads" | sed "s/^/\t\t/"
        sudo chown -R apache /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
        sudo chmod -R 0700 /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads
        echo "$software core version:" | sed "s/^/\t\t/"
        php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" core version 2>&1 | sed "s/^/\t\t\t/"
        echo "$software core verify-checksums:" | sed "s/^/\t\t/"
        php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" core verify-checksums 2>&1 | sed "s/^/\t\t\t/"
        echo "$software core check-update:" | sed "s/^/\t\t/"
        php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" core check-update 2>&1 | sed "s/^/\t\t\t/"
        echo "$software plugin list:" | sed "s/^/\t\t/"
        php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" plugin list 2>&1 | sed "s/^/\t\t\t/"
        echo "$software theme list:" | sed "s/^/\t\t/"
        php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" theme list 2>&1 | sed "s/^/\t\t\t/"
    fi

done

end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Restarting Apache"
start=$(date +%s)
sudo apachectl stop
sudo apachectl start
sudo apachectl configtest
sudo systemctl is-active httpd.service
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) total seconds)"


exit 0
