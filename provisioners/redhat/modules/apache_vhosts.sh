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

    # define variables
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
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_" | tr "-" "_")
    domainvalidcertname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    if [ "$1" != "production" ]; then
        domainvalidcertname="${1}_${domainvalidcertname}"
    fi
    force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
    force_auth_exclude=$(echo "$key" | grep -w "force_auth_exclude" | tr -d " ")
    force_https=$(echo "$key" | grep -w "force_https" | cut -d ":" -f 2 | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    # generate letsencrypt certificates for upstream
    if ([ "$1" != "dev" ]); then
        if [ -z "${domain_tld_override}" ]; then
            bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --domain "${domain_environment}" --domain "www.${domain_environment}" 2>&1
            sudo cat >> /catapult/provisioners/redhat/installers/dehydrated/domains.txt << EOF
${domain_environment} www.${domain_environment}
EOF
        else
            bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --domain "${domain_environment}.${domain_tld_override}" --domain "www.${domain_environment}.${domain_tld_override}" 2>&1
            sudo cat >> /catapult/provisioners/redhat/installers/dehydrated/domains.txt << EOF
${domain_environment}.${domain_tld_override} www.${domain_environment}.${domain_tld_override}
EOF
        fi
    fi

    # configure vhost
    echo -e "Configuring vhost for ${domain_environment}"
    sudo mkdir --parents /var/log/httpd/${domain_environment}
    sudo touch /var/log/httpd/${domain_environment}/access_log
    sudo touch /var/log/httpd/${domain_environment}/error_log
    # set domain_tld_override_alias_additions for vhost
    if [ -z "${domain_tld_override}" ]; then
        domain_tld_override_alias_additions=""
    else
        domain_tld_override_alias_additions="ServerAlias ${domain_environment}.${domain_tld_override}
        ServerAlias www.${domain_environment}.${domain_tld_override}"
    fi
    # handle the force_auth option
    if ([ ! -z "${force_auth}" ]); then
        if ([ ! -z "${force_auth_exclude}" ]); then
            force_auth_excludes=( $(echo "${key}" | shyaml get-values force_auth_exclude) )
            if ([[ "${force_auth_excludes[@]}" =~ "$1" ]]); then
                force_auth_value=""
            else
                sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1
                force_auth_value="
                    <Location />
                        # Force HTTP authentication
                        AuthType Basic
                        AuthName \"Authentication Required\"
                        AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
                        Require valid-user
                    </Location>
                "
            fi
        else
            sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd ${force_auth} ${force_auth} 2>&1
            force_auth_value="
                <Location />
                    # Force HTTP authentication
                    AuthType Basic
                    AuthName \"Authentication Required\"
                    AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
                    Require valid-user
                </Location>
            "
        fi
    else
        # never force_auth in dev
        force_auth_value=""
    fi
    # handle ssl certificates
    # if there is a specified custom certificate available
    if ([ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.ca-bundle" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.crt" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.csr" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.key" ]); then
        ssl_certificates="
        SSLCertificateFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.crt
        SSLCertificateKeyFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.key
        SSLCertificateChainFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.ca-bundle
        "
    # upstream without domain_tld_override and a letsencrypt cert available
    elif ([ "$1" != "dev" ]) && ([ -z "${domain_tld_override}" ]) && ([ -f /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/cert.pem ]); then
        ssl_certificates="
        SSLCertificateFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/cert.pem
        SSLCertificateKeyFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/privkey.pem
        SSLCertificateChainFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/chain.pem
        "
    # upstream with domain_tld_override and a letsencrypt cert available
    elif ([ "$1" != "dev" ]) && ([ ! -z "${domain_tld_override}" ]) && ([ -f /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/cert.pem ]); then
        ssl_certificates="
        SSLCertificateFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/cert.pem
        SSLCertificateKeyFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/privkey.pem
        SSLCertificateChainFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/chain.pem
        "
    # self-signed in localdev or if we do not have a letsencrypt cert
    else
        ssl_certificates="
        SSLCertificateFile /etc/ssl/certs/httpd-dummy-cert.key.cert
        SSLCertificateKeyFile /etc/ssl/certs/httpd-dummy-cert.key.cert
        "
    fi
    # handle the force_https option
    if [ "${force_https}" = true ]; then
        force_https_value="
        # use X-Forwarded-Proto to accomodate load balancers, proxies, etc
        # !https rather than =http to match when X-Forwarded-Proto is not set
        RewriteEngine On
        RewriteCond %{HTTP:X-Forwarded-Proto} !https
        RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
        "
        force_https_hsts="Header always set Strict-Transport-Security \"max-age=15768000\""
    else
        force_https_value="# HTTPS is only forced when force_https=true"
        force_https_hsts="# HSTS is only enabled when force_https=true"
    fi
    # write vhost apache conf file
    sudo cat > /etc/httpd/sites-available/${domain_environment}.conf << EOF

    RewriteEngine On

    <VirtualHost *:80> # must listen * to support cloudflare
        ServerAdmin ${company_email}
        ServerName ${domain_environment}
        ServerAlias www.${domain_environment}
        $domain_tld_override_alias_additions
        DocumentRoot /var/www/repositories/apache/${domain}/${webroot}
        ErrorLog /var/log/httpd/${domain_environment}/error_log
        CustomLog /var/log/httpd/${domain_environment}/access_log combined
        LogLevel warn
        ${force_auth_value}
        ${force_https_value}
    </VirtualHost>

    <IfModule mod_ssl.c>
        <VirtualHost *:443> # must listen * to support cloudflare
            ServerAdmin ${company_email}
            ServerName ${domain_environment}
            ServerAlias www.${domain_environment}
            $domain_tld_override_alias_additions
            DocumentRoot /var/www/repositories/apache/${domain}/${webroot}
            ErrorLog /var/log/httpd/${domain_environment}/error_log
            CustomLog /var/log/httpd/${domain_environment}/access_log combined
            LogLevel warn
            SSLEngine on

            # SSLCompression: CRIME
            SSLCompression off

            # add support for HSTS
            # HSTS: SSLstrip, MITM
            # Firefox 4, Chrome 4, IE 11, Opera 12, Safari (OS X 10.9)
            $force_https_hsts

            # allow only secure ciphers that client can negotiate
            # https://wiki.mozilla.org/Security/Server_Side_TLS
            # https://mozilla.github.io/server-side-tls/ssl-config-generator/
            # Firefox 1, Chrome 1, IE 7, Opera 5, Safari 1, Windows XP IE8, Android 2.3, Java 7
            SSLHonorCipherOrder on
            SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS

            # disable the SSL_ environment variable (usually CGI and SSI requests only)
            SSLOptions -StdEnvVars

            # help old browsers
            BrowserMatch "MSIE [2-5]" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0

            # set the ssl certificates
            ${ssl_certificates}

            # force httpd basic auth if configured
            ${force_auth_value}

        </VirtualHost>
    </IfModule>

    # allow .htaccess in apache 2.4+
    <Directory "/var/www/repositories/apache/${domain}/${webroot}">
        AllowOverride All
        Options -Indexes +FollowSymlinks
        # define new relic appname
        <IfModule php5_module>
            php_value newrelic.appname "${domain_environment};$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat"
        </IfModule>
    </Directory>

    # deny access to _sql folders
    <Directory "/var/www/repositories/apache/${domain}/${webroot}_sql">
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
