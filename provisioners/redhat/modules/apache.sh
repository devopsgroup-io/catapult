source "/catapult/provisioners/redhat/modules/catapult.sh"

# install apache
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"

# use sites-available, sites-enabled convention. this is a debianism - but the convention is common and easy understand
sudo mkdir -p /etc/httpd/sites-available
sudo mkdir -p /etc/httpd/sites-enabled
if ! grep -q "IncludeOptional sites-enabled/\*.conf" "/etc/httpd/conf/httpd.conf"; then
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

# null the welcome conf
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

# create a _default_ catchall
# if the vhost has not been linked, link the vhost
# to test this visit the ip address of the respective environment redhat public ip via http://
if [ ! -f /var/www/repositories/apache/_default_ ]; then
    sudo ln -s /catapult/repositories/apache/_default_ /var/www/repositories/apache/
fi
sudo cat > /etc/httpd/sites-enabled/_default_.conf << EOF
<VirtualHost *:80>
  DocumentRoot /var/www/repositories/apache/_default_/
</VirtualHost>
EOF

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
