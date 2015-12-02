source "/catapult/provisioners/redhat/modules/catapult.sh"

# set variables from secrets/configuration.yml
mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat.ip)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(echo "${configuration}" | shyaml get-value company.email)"

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
    # enable cors for localdev http response codes from dashboard
    if [ "$1" = "dev" ]; then
        cors="SetEnvIf Origin \"^(.*\.?devopsgroup\.io)$\" ORIGIN_SUB_DOMAIN=\$1
        Header set Access-Control-Allow-Origin \"%{ORIGIN_SUB_DOMAIN}e\" env=ORIGIN_SUB_DOMAIN"
    else
        cors=""
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
        $cors
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

done

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
