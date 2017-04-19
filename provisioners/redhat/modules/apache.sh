source "/catapult/provisioners/redhat/modules/catapult.sh"

# install apache
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service

# install mod_security
# note enabled by default: see /etc/httpd/conf.d/mod_security.conf
sudo yum install -y mod_security

# install mod_ssl and create self-signed cert
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"

# prevent the httpoxy vulnerability
# https://www.apache.org/security/asf-httpoxy-response.txt
if ! grep -q "RequestHeader unset Proxy early" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo -e "\nRequestHeader unset Proxy early" >> /etc/httpd/conf/httpd.conf'
fi

# do not expose server information
# https://httpd.apache.org/docs/2.4/mod/core.html#servertokens
if ! grep -q "ServerTokens Prod" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo -e "\nServerTokens Prod" >> /etc/httpd/conf/httpd.conf'
fi

# define the server's servername
# suppress this - httpd: Could not reliably determine the server's fully qualified domain name, using localhost.localdomain. Set the 'ServerName' directive globally to suppress this message
if ! grep -q "ServerName localhost" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo -e "\nServerName localhost" >> /etc/httpd/conf/httpd.conf'
fi

# use sites-available, sites-enabled convention. this is a debianism - but the convention is common and easy to understand
sudo mkdir --parents /etc/httpd/sites-available
sudo mkdir --parents /etc/httpd/sites-enabled
if ! grep -q "IncludeOptional sites-enabled/\*.conf" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo -e "\nIncludeOptional sites-enabled/*.conf" >> "/etc/httpd/conf/httpd.conf"'
fi
if ! grep -q "IncludeOptional sites-enabled/\*.conf" "/etc/httpd/conf.d/ssl.conf"; then
   sudo bash -c 'echo -e "\nIncludeOptional sites-enabled/*.conf" >> "/etc/httpd/conf.d/ssl.conf"'
fi

# define the default ssl protocols
# SSLv2: FUBAR
# SSLv3: POODLE
if ! grep -q "SSLProtocol all -SSLv2 -SSLv3" "/etc/httpd/conf.d/ssl.conf"; then
    sudo bash -c 'echo -e "\nSSLProtocol all -SSLv2 -SSLv3" >> /etc/httpd/conf.d/ssl.conf'
fi

# 80: remove the default vhost
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

# 443: remove the default vhost
sed -i '/<VirtualHost _default_:443>/,$d' "/etc/httpd/conf.d/ssl.conf"

# 80/443: create a _default_ catchall
# if the vhost has not been linked, link the vhost
# to test this visit the ip address of the respective environment redhat public ip via http:// or https://
if [ ! -e /var/www/repositories/apache/_default_ ]; then
    sudo ln -s /catapult/repositories/apache/_default_ /var/www/repositories/apache/
fi

# renew self-signed key/cert
sh /etc/ssl/certs/renew-dummy-cert /etc/ssl/certs/httpd-dummy-cert.key.cert

# support letsencrypt
sudo mkdir --parents /var/www/dehydrated
# initalize the domains.txt file for certificates cron job
cat /dev/null > /catapult/provisioners/redhat/installers/dehydrated/domains.txt

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

# configure log rotation for apache
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

# configure log rotation for apache vhosts
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

# add support for cloudflare and report real user IP addresses
# also helps resolve redirect loops when HSTS is enabled
# https://www.cloudflare.com/technical-resources/
# new versions released here https://github.com/cloudflare/mod_cloudflare
sudo yum install -y libtool httpd-devel
sudo apxs -a -i -c /catapult/provisioners/redhat/installers/cloudflare/mod_cloudflare.c

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
