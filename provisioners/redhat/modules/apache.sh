source "/catapult/provisioners/redhat/modules/catapult.sh"

# 80: install httpd
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service

# 80: /etc/httpd/conf/httpd.conf customizations
# https://httpd.apache.org/docs/2.4/mod/core.html
sudo mkdir --parents /etc/httpd/sites-available
sudo mkdir --parents /etc/httpd/sites-enabled
sudo cat > /etc/httpd/conf.d/httpd_custom.conf << EOF
# prevent the httpoxy vulnerability
# https://www.apache.org/security/asf-httpoxy-response.txt
RequestHeader unset Proxy early

# do not expose server information
# https://httpd.apache.org/docs/2.4/mod/core.html#servertokens
ServerTokens Prod

# define the server's servername
# suppress this - httpd: Could not reliably determine the server's fully qualified domain name, using localhost.localdomain. Set the 'ServerName' directive globally to suppress this message
ServerName localhost

# use sites-available, sites-enabled convention. this is a debianism - but the convention is common and easy to understand
IncludeOptional sites-enabled/*.conf

# prevent proxy timeouts
# https://forum.remirepo.net/viewtopic.php?id=3240
# specifically necessary for concrete5 install (long running php script with multiple XHR requests)
<Proxy fcgi://127.0.0.1:9720>
    ProxySet timeout=300
</Proxy>
<Proxy fcgi://127.0.0.1:9710>
    ProxySet timeout=300
</Proxy>
<Proxy fcgi://127.0.0.1:9700>
    ProxySet timeout=300
</Proxy>
<Proxy fcgi://127.0.0.1:9540>
    ProxySet timeout=300
</Proxy>
EOF

# 443: install mod_security
sudo yum install -y mod_security

# 443: /etc/httpd/conf.d/mod_security.conf customizations
# https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-%28v2.x%29
sudo cat > /etc/httpd/conf.d/mod_security_custom.conf << EOF
<IfModule mod_security2.c>
    SecRequestBodyLimit 67108864
</IfModule>
EOF

# 443: install mod_ssl and create self-signed cert
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"

# 443: /etc/httpd/conf/ssl.conf customizations
# https://httpd.apache.org/docs/2.4/mod/mod_ssl.html
sudo cat > /etc/httpd/conf.d/ssl_custom.conf << EOF
<IfModule mod_ssl.c>
    # define the default ssl protocols and disable: SSLv2 - FUBAR, SSLv3 - POODLE
    SSLProtocol all -SSLv2 -SSLv3
</IfModule>
EOF

# 80: remove the default vhost
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

# 443: remove the default vhost
sed -i '/<VirtualHost _default_:443>/,$d' "/etc/httpd/conf.d/ssl.conf"

# 443: renew self-signed key/cert
sh /etc/ssl/certs/renew-dummy-cert /etc/ssl/certs/httpd-dummy-cert.key.cert

# 443: support letsencrypt
sudo mkdir --parents /var/www/dehydrated
# initalize the domains.txt file for certificates cron job
cat /dev/null > /catapult/provisioners/redhat/installers/dehydrated/domains.txt

# 443: add support for cloudflare and report real user IP addresses
# also helps resolve redirect loops when HSTS is enabled
# https://www.cloudflare.com/technical-resources/
# new versions released here https://github.com/cloudflare/mod_cloudflare
sudo yum install -y libtool httpd-devel
sudo apxs -a -i -c /catapult/provisioners/redhat/installers/cloudflare/mod_cloudflare.c

# 80/443: create a _default_ catchall
# if the vhost has not been linked, link the vhost
# to test this visit the ip address of the respective environment redhat public ip via http:// or https://
if [ ! -e /var/www/repositories/apache/_default_ ]; then
    sudo ln -s /catapult/repositories/apache/_default_ /var/www/repositories/apache/
fi

# 80/443: create vhosts
sudo cat > /etc/httpd/sites-enabled/_default_.conf << EOF
<VirtualHost *:80>
  DocumentRoot /var/www/repositories/apache/_default_/
</VirtualHost>
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        DocumentRoot /var/www/repositories/apache/_default_/
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/httpd-dummy-cert.key.cert
        SSLCertificateKeyFile /etc/ssl/certs/httpd-dummy-cert.key.cert
    </VirtualHost>
</IfModule>
# accomodate letsencrypt
Alias /.well-known/acme-challenge /var/www/dehydrated
<Directory /var/www/dehydrated>
    AllowOverride None
    Options None
    <IfModule mod_authz_core.c>
        Satisfy Any
        Allow from all
    </IfModule>
</Directory>
EOF

# 80/443: configure log rotation for apache
sudo cat > /etc/logrotate.d/httpd << EOF
/var/log/httpd/*log {
    daily
    delaycompress
    notifempty
    maxage 7
    missingok
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# 80/443: configure log rotation for apache vhosts
sudo cat > /etc/logrotate.d/httpd_vhosts << EOF
/var/log/httpd/*/*log {
    daily
    delaycompress
    notifempty
    maxage 7
    missingok
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
