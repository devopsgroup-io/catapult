# install apache
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"

# install php
#@todo think about having directive per website that lists php module dependancies
sudo yum install -y php
sudo yum install -y php-mysql
sudo yum install -y php-curl
sudo yum install -y php-gd
sudo yum install -y php-dom
sudo yum install -y php-mbstring
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(echo "${configuration}" | shyaml get-value company.timezone_redhat)\"#g" /etc/php.ini

# set variables from secrets/configuration.yml
mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat.ip)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(echo "${configuration}" | shyaml get-value company.email)"

# use sites-available, sites-enabled convention. this is a debianism - but the convention is common and easy understand
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

# null out httpd log files
sudo cat /dev/null > /var/log/httpd/access_log
sudo cat /dev/null > /var/log/httpd/error_log

# @todo null the welcome conf, ideally we should make a catapult welcome file, remember that conf files are read alpa
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

# remove directories from /var/www/repositories/apache/ that no longer exist in configuration
# create an array of domains
while IFS='' read -r -d '' key; do
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    array_domain_environment+=("${domain_environment}")
    array_conf_domain_environment+=("${domain_environment}.conf")
    array_htpasswd_domain_environment+=("${domain_environment}.htpasswd")
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup /var/log/httpd/*/access.log and /var/log/httpd/*/error.log
for directory in /var/log/httpd/*/; do
    # when there are no matches, for defaults to the match /var/log/httpd/*/, ignore this result
    # on a new provision, there will be no log directories
    if [ -e "$directory" ]; then
        folder_domain_environment=$(basename $directory)
        if ! [[ "${array_domain_environment[*]}" =~ "${folder_domain_environment}" ]]; then
            echo -e "\t * cleaning up /var/log/httpd/${folder_domain_environment}/ as the website has been removed for your configuration..."
            sudo chmod 0777 -R $directory
            sudo rm -rf $directory
        else
            echo -e "\t * emptying log files in /var/log/httpd/${folder_domain_environment}/..."
            sudo cat /dev/null > /var/log/httpd/${folder_domain_environment}/access.log
            sudo cat /dev/null > /var/log/httpd/${folder_domain_environment}/error.log
        fi
    fi
done
# cleanup /etc/httpd/sites-enabled/*.htpasswd files
for file in /etc/httpd/sites-enabled/*.htpasswd; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-enabled/*.htpasswd, ignore this result
    # there may not be a .htpasswd
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! [[ "${array_htpasswd_domain_environment[*]}" =~ "${file_domain_environment}" ]]; then
            echo -e "\t * cleaning up /etc/httpd/sites-enabled/${file_domain_environment} as the website has been removed for your configuration..."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done
# cleanup /etc/httpd/sites-enabled/*.conf files
for file in /etc/httpd/sites-enabled/*.conf; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-enabled/*.conf, ignore this result
    # on a new provision, the .conf files do not exist yet
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! [[ "${array_conf_domain_environment[*]}" =~ "${file_domain_environment}" ]]; then
            echo -e "\t * cleaning up /etc/httpd/sites-enabled/${file_domain_environment} as the website has been removed for your configuration..."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done
# cleanup /etc/httpd/sites-available/*.conf files
for file in /etc/httpd/sites-available/*.conf; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-available/*.conf, ignore this result
    # on a new provision, the .conf files do not exist yet
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! [[ "${array_conf_domain_environment[*]}" =~ "${file_domain_environment}" ]]; then
            echo -e "\t * cleaning up /etc/httpd/sites-available/${file_domain_environment} as the website has been removed for your configuration.."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done

# create a vhost per website
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

    # configure vhost
    if [ "$1" = "production" ]; then
        echo -e "\t * configuring vhost for ${domain_root}"
    else
        echo -e "\t * configuring vhost for ${1}.${domain_root}"
    fi
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
                sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1 | sed "s/^/\t\t/"
                force_auth_value="<Location />
                    # Force HTTP authentication
                    AuthType Basic
                    AuthName \"Authentication Required\"
                    AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
                    Require valid-user
                </Location>"
            fi
        else
            sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1 | sed "s/^/\t\t/"
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

    # if the vhost has not been linked, link the vhost
    if [ ! -f /etc/httpd/sites-enabled/$domain_environment.conf ]; then
        sudo ln -s /etc/httpd/sites-available/$domain_environment.conf /etc/httpd/sites-enabled/$domain_environment.conf
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

# reload apache
sudo systemctl reload httpd.service
if [ $? -eq 0 ]; then
  echo "'sudo systemctl reload httpd.service' was successful"
else
  echo "'sudo systemctl reload httpd.service' was unsuccessful, trying 'sudo apachectl -k graceful'"
  sudo apachectl -k graceful
fi
sudo systemctl status httpd.service
