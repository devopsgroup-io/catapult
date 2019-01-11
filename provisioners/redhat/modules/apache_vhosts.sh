source "/catapult/provisioners/redhat/modules/catapult.sh"

# set variables from secrets/configuration.yml
company_email="$(catapult company.email)"

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
    domainvalidcertname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    if [ "$1" != "production" ]; then
        domainvalidcertname="${1}_${domainvalidcertname}"
    fi
    force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
    force_auth_exclude=$(echo "$key" | grep -w "force_auth_exclude" | tr -d " ")
    force_https=$(echo "$key" | grep -w "force_https" | cut -d ":" -f 2 | tr -d " ")
    force_ip=$(echo "$key" | grep -w "force_ip" | tr -d " ")
    force_ip_exclude=$(echo "$key" | grep -w "force_ip_exclude" | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_php_version=$(provisioners software.apache.${software}.php_version)
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
        force_auth_value=""
    fi
    # handle the force_ip option
    if ([ ! -z "${force_ip}" ]); then
        if ([ ! -z "${force_ip_exclude}" ]); then
            force_ip_excludes=($(echo "${key}" | shyaml get-values force_ip_exclude))
            if ([[ "${force_ip_excludes[@]}" =~ "$1" ]]); then
                force_ip_value=""
            else
                force_ip_value="
                    <Location />
                        Require all denied
                "
                while IFS='' read -r -d '' ip; do
                    force_ip_value+="
                        Require ip ${ip}
                    "
                done < <(echo "${key}" | shyaml get-values-0 force_ip)
                force_ip_value+="
                    </Location>
                "
            fi
        else
            force_ip_value="
                <Location />
                    Require all denied
            "
            while IFS='' read -r -d '' ip; do
                force_ip_value+="
                    Require ip ${ip}
                "
            done < <(echo "${key}" | shyaml get-values-0 force_ip)
            force_ip_value+="
                </Location>
            "
        fi
    else
        force_ip_value=""
    fi
    # handle https certificates
    # if there is a specified custom certificate available and it does not expire within the next 86400 seconds (1 day)
    if ([ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.ca-bundle" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.crt" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.csr" ] \
     && [ -f "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.key" ] \
     && [ $(openssl x509 -checkend 86400 -noout -in "/var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.crt") ]); then
        https_certificates="
        SSLCertificateFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.crt
        SSLCertificateKeyFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/server.key
        SSLCertificateChainFile /var/www/repositories/apache/${domain}/_cert/${domainvalidcertname}/${domainvalidcertname}.ca-bundle
        "
    # upstream without domain_tld_override and a letsencrypt cert available
    elif ([ "$1" != "dev" ]) && ([ -z "${domain_tld_override}" ]) && ([ -f /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/cert.pem ]); then
        https_certificates="
        SSLCertificateFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/cert.pem
        SSLCertificateKeyFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/privkey.pem
        SSLCertificateChainFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}/chain.pem
        "
    # upstream with domain_tld_override and a letsencrypt cert available
    elif ([ "$1" != "dev" ]) && ([ ! -z "${domain_tld_override}" ]) && ([ -f /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/cert.pem ]); then
        https_certificates="
        SSLCertificateFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/cert.pem
        SSLCertificateKeyFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/privkey.pem
        SSLCertificateChainFile /catapult/provisioners/redhat/installers/dehydrated/certs/${domain_environment}.${domain_tld_override}/chain.pem
        "
    # self-signed in localdev or if we do not have a letsencrypt cert
    else
        https_certificates="
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
    # handle the software php_version setting
    if [ "${software_php_version}" = "7.2" ]; then
        software_php_version_value="
        <FilesMatch \.php$>
            SetHandler \"proxy:fcgi://127.0.0.1:9720\"
        </FilesMatch>
        "
    elif [ "${software_php_version}" = "7.1" ]; then
        software_php_version_value="
        <FilesMatch \.php$>
            SetHandler \"proxy:fcgi://127.0.0.1:9710\"
        </FilesMatch>
        "
    elif [ "${software_php_version}" = "7.0" ]; then
        software_php_version_value="
        <FilesMatch \.php$>
            SetHandler \"proxy:fcgi://127.0.0.1:9700\"
        </FilesMatch>
        "
    elif [ "${software_php_version}" = "5.4" ]; then
        software_php_version_value="
        <FilesMatch \.php$>
            SetHandler \"proxy:fcgi://127.0.0.1:9540\"
        </FilesMatch>
        "
    else
        software_php_version_value="
        <FilesMatch \.php$>
            SetHandler \"proxy:fcgi://127.0.0.1:9540\"
        </FilesMatch>
        "
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

        # force http basic auth if configured
        ${force_auth_value}

        # force visitor ip address if configured
        ${force_ip_value}

        # force https if configured
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

            # set the https certificates
            ${https_certificates}

            # force http basic auth if configured
            ${force_auth_value}

            # force visitor ip address if configured
            ${force_ip_value}

        </VirtualHost>
    </IfModule>

    # define apache ruleset for the web root
    <Directory "/var/www/repositories/apache/${domain}/${webroot}">

        # allow .htaccess in apache 2.4+
        AllowOverride All
        Options -Indexes +FollowSymlinks

        # define the php version being used
        ${software_php_version_value}

        # allow /manifest.json to be accessed regardless of basic auth as /manifest.json is usually accessed out of basic auth context
        <Files "manifest.json">
            <IfModule mod_authz_core.c>
                Satisfy Any
                Allow from all
            </IfModule>
        </Files>

        # set security related response headers
        # https://www.owasp.org/index.php/OWASP_Secure_Headers_Project#tab=Headers
        # https://securityheaders.io/?q=devopsgroup.io&followRedirects=on
        # https://github.com/h5bp/server-configs-apache/tree/master/src/security
        <IfModule mod_headers.c>
            #Header set Content-Security-Policy "script-src 'self'; object-src 'self'"
            Header set X-Content-Type-Options: "nosniff"
            Header set X-Frame-Options: "sameorigin"
            Header set X-XSS-Protection: "1; mode=block"
        </IfModule>

        # compress certain content types before being sent to the client over the network
        # https://github.com/h5bp/server-configs-apache
        # https://httpd.apache.org/docs/current/mod/mod_filter.html#addoutputfilterbytype
        <IfModule mod_deflate.c>
            <IfModule mod_filter.c>
                AddOutputFilterByType DEFLATE "application/atom+xml"
                AddOutputFilterByType DEFLATE "application/javascript"
                AddOutputFilterByType DEFLATE "application/json"
                AddOutputFilterByType DEFLATE "application/ld+json"
                AddOutputFilterByType DEFLATE "application/manifest+json"
                AddOutputFilterByType DEFLATE "application/rdf+xml"
                AddOutputFilterByType DEFLATE "application/rss+xml"
                AddOutputFilterByType DEFLATE "application/schema+json"
                AddOutputFilterByType DEFLATE "application/vnd.geo+json"
                AddOutputFilterByType DEFLATE "application/vnd.ms-fontobject"
                AddOutputFilterByType DEFLATE "application/x-font-ttf"
                AddOutputFilterByType DEFLATE "application/x-javascript"
                AddOutputFilterByType DEFLATE "application/x-web-app-manifest+json"
                AddOutputFilterByType DEFLATE "application/xhtml+xml"
                AddOutputFilterByType DEFLATE "application/xml"
                AddOutputFilterByType DEFLATE "font/eot"
                AddOutputFilterByType DEFLATE "font/opentype"
                AddOutputFilterByType DEFLATE "image/bmp"
                AddOutputFilterByType DEFLATE "image/svg+xml"
                AddOutputFilterByType DEFLATE "image/vnd.microsoft.icon"
                AddOutputFilterByType DEFLATE "image/x-icon"
                AddOutputFilterByType DEFLATE "text/cache-manifest"
                AddOutputFilterByType DEFLATE "text/css"
                AddOutputFilterByType DEFLATE "text/html"
                AddOutputFilterByType DEFLATE "text/javascript"
                AddOutputFilterByType DEFLATE "text/plain"
                AddOutputFilterByType DEFLATE "text/vcard"
                AddOutputFilterByType DEFLATE "text/vnd.rim.location.xloc"
                AddOutputFilterByType DEFLATE "text/vtt"
                AddOutputFilterByType DEFLATE "text/x-component"
                AddOutputFilterByType DEFLATE "text/x-cross-domain-policy"
                AddOutputFilterByType DEFLATE "text/xml"
            </IfModule>
        </IfModule>

        # allow ETags as there is only one data store (Apache does a file stat so serving the same file from multiple servers would invalidate ETags)
        # https://github.com/expressjs/express/issues/2445
        # https://gist.github.com/6a68/4971859
        # https://github.com/h5bp/server-configs-apache
        # https://tools.ietf.org/html/rfc7232#section-2.3
        # https://httpd.apache.org/docs/2.4/mod/core.html#fileetag
        FileETag MTime Size

        # serve resources with far-future expires headers
        # (!) if you don't control versioning with filename-based cache busting, you should consider lowering the cache times to something like one week
        # (!) cloudflare uses 4 hours as a default cache expiration
        # https://support.cloudflare.com/hc/en-us/articles/200172516-Which-file-extensions-does-Cloudflare-cache-for-static-content-
        # https://support.cloudflare.com/hc/en-us/article_attachments/212266867/cachable.txt
        # (!) cloudflare automatically respects longer cache expiration specified by the server
        # https://support.cloudflare.com/hc/en-us/articles/200168276
        # (!) google pagespeed insights requires the cache level to be set to at least 7 days to pass the test
        # https://github.com/h5bp/server-configs-apache
        # https://httpd.apache.org/docs/current/mod/mod_expires.html
        <IfModule mod_expires.c>
            ExpiresActive on
            ExpiresDefault                                      "access plus 1 week"
          # CSS
            ExpiresByType text/css                              "access plus 1 week"
          # Data interchange
            ExpiresByType application/atom+xml                  "access plus 1 hour"
            ExpiresByType application/rdf+xml                   "access plus 1 hour"
            ExpiresByType application/rss+xml                   "access plus 1 hour"
            ExpiresByType application/json                      "access plus 0 seconds"
            ExpiresByType application/ld+json                   "access plus 0 seconds"
            ExpiresByType application/schema+json               "access plus 0 seconds"
            ExpiresByType application/vnd.geo+json              "access plus 0 seconds"
            ExpiresByType application/xml                       "access plus 0 seconds"
            ExpiresByType text/xml                              "access plus 0 seconds"
          # Favicon (cannot be renamed!) and cursor images
            ExpiresByType image/vnd.microsoft.icon              "access plus 1 week"
            ExpiresByType image/x-icon                          "access plus 1 week"
          # HTML
            ExpiresByType text/html                             "access plus 0 seconds"
          # JavaScript
            ExpiresByType application/javascript                "access plus 1 week"
            ExpiresByType application/x-javascript              "access plus 1 week"
            ExpiresByType text/javascript                       "access plus 1 week"
          # Manifest files
            ExpiresByType application/manifest+json             "access plus 1 week"
            ExpiresByType application/x-web-app-manifest+json   "access plus 0 seconds"
            ExpiresByType text/cache-manifest                   "access plus 0 seconds"
          # Media files
            ExpiresByType audio/ogg                             "access plus 1 week"
            ExpiresByType image/bmp                             "access plus 1 week"
            ExpiresByType image/gif                             "access plus 1 week"
            ExpiresByType image/jpeg                            "access plus 1 week"
            ExpiresByType image/png                             "access plus 1 week"
            ExpiresByType image/svg+xml                         "access plus 1 week"
            ExpiresByType image/webp                            "access plus 1 week"
            ExpiresByType video/mp4                             "access plus 1 week"
            ExpiresByType video/ogg                             "access plus 1 week"
            ExpiresByType video/webm                            "access plus 1 week"
          # Web fonts
            # Embedded OpenType (EOT)
            ExpiresByType application/vnd.ms-fontobject         "access plus 1 month"
            ExpiresByType font/eot                              "access plus 1 month"
            # OpenType
            ExpiresByType font/opentype                         "access plus 1 month"
            # TrueType
            ExpiresByType application/x-font-ttf                "access plus 1 month"
            # Web Open Font Format (WOFF) 1.0
            ExpiresByType application/font-woff                 "access plus 1 month"
            ExpiresByType application/x-font-woff               "access plus 1 month"
            ExpiresByType font/woff                             "access plus 1 month"
            # Web Open Font Format (WOFF) 2.0
            ExpiresByType application/font-woff2                "access plus 1 month"
          # Other
            ExpiresByType text/x-cross-domain-policy            "access plus 1 week"
        </IfModule>

    </Directory>

    # deny access to .git folder
    <Directory "/var/www/repositories/apache/${domain}/.git">
        Require all denied
    </Directory>

    # deny access to _append folder
    <Directory "/var/www/repositories/apache/${domain}/_append">
        Require all denied
    </Directory>

    # deny access to _cert folder
    <Directory "/var/www/repositories/apache/${domain}/_cert">
        Require all denied
    </Directory>

    # deny access to _sql folder
    <Directory "/var/www/repositories/apache/${domain}/_sql">
        Require all denied
    </Directory>

EOF

    # if the vhost has not been linked, link the vhost
    if [ ! -f /etc/httpd/sites-enabled/$domain_environment.conf ]; then
        sudo ln -s /etc/httpd/sites-available/$domain_environment.conf /etc/httpd/sites-enabled/$domain_environment.conf
    fi

    # set a .user.ini file for php-fpm to read
    sudo mkdir --parents /var/www/repositories/apache/${domain}/${webroot}
    sudo touch /var/www/repositories/apache/${domain}/${webroot}/.user.ini
    sudo cat > /var/www/repositories/apache/${domain}/${webroot}/.user.ini << EOF
newrelic.appname="${domain_environment};$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat"
EOF

done

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
