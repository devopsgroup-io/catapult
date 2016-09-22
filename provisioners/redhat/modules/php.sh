source "/catapult/provisioners/redhat/modules/catapult.sh"

# http://php.net/manual/en/extensions.membership.php

# core extensions
sudo yum install -y php
sudo yum install -y php-cli
# These are not actual extensions. They are part of the PHP core and cannot be left out of a PHP binary with compilation options.

# php.ini configuration options
# set the timezone
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(catapult company.timezone_redhat)\"#g" /etc/php.ini
# increase the upload_max_filesize
sed -i -e "s#^upload_max_filesize.*#upload_max_filesize = 10M#g" /etc/php.ini
# hide x-powered-by
sed -i -e "s#^expose_php.*#expose_php = Off#g" /etc/php.ini
# increase php memory limit for tools like composer
sed -i -e "s#^memory_limit.*#memory_limit = 256M#g" /etc/php.ini
# display errors on screen using the default recommendations for development and production
if [ "$1" = "dev" ]; then
    sed -i -e "s#^display_errors.*#display_errors = On#g" /etc/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL#g" /etc/php.ini
else
    sed -i -e "s#^display_errors.*#display_errors = Off#g" /etc/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT#g" /etc/php.ini
fi

# bundled extensions
# These extensions are bundled with PHP.
sudo yum install -y php-gd
sudo yum install -y php-mbstring
sudo yum install -y php-posix

# external extensions
# These extensions are bundled with PHP but in order to compile them, external libraries will be needed.
sudo yum install -y php-curl
sudo yum install -y php-dom
sudo yum install -y php-mysql

# epel extensions
sudo yum install -y epel-release
# Extra Packages for Enterprise Linux (or EPEL) is a Fedora Special Interest Group that creates, maintains, and manages a high quality set of additional packages for Enterprise Linux, including, but not limited to, Red Hat Enterprise Linux (RHEL), CentOS and Scientific Linux (SL), Oracle Linux (OL).
sudo yum install -y php-mcrypt

# pecl extensions
sudo yum install -y php-pear
sudo yum install -y php-devel
sudo pear config-set php_ini /etc/php.ini
sudo yum install -y gcc
# These extensions are available from » PECL. They may require external libraries. More PECL extensions exist but they are not documented in the PHP manual yet.
#################
# pecl extension: php-pecl-zendopcache
# https://pecl.php.net/package/ZendOpcache
sudo yum install -y php-pecl-zendopcache
# disable cache for dev
if [ "$1" = "dev" ]; then
    sudo bash -c 'echo "/var/www" > /etc/php.d/opcache-default.blacklist'
else
    sudo bash -c 'echo "" > /etc/php.d/opcache-default.blacklist'
fi
#################
# pecl extension: yaml
# https://pecl.php.net/package/yaml
sudo yum install -y libyaml-devel
echo autodetect | sudo pecl upgrade yaml
#################
# pecl extension: geoip
# https://pecl.php.net/package/geoip
sudo yum install -y geoip-devel
# this is a beta release but includes a 3 year gap of bug fixes and new functions
sudo pecl install geoip-1.1.0
echo autodetect | sudo pecl upgrade geoip
# http://dev.maxmind.com/geoip/legacy/geolite/
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIP.dat.gz" --request GET "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIP.dat.gz"
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIPCity.dat.gz" --request GET "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIPCity.dat.gz"
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIPASNum.dat.gz" --request GET "http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIPASNum.dat.gz"
#################
# pecl extension: uploadprogress
# http://pecl.php.net/package/uploadprogress
sudo pecl upgrade uploadprogress
#################
# output installed pecl extensions once finished
sudo pecl list

# reload httpd configuration for changes to reflect
# reload httpd to clear zend opcache
systemctl reload httpd.service
