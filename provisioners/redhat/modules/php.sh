source "/catapult/provisioners/redhat/modules/catapult.sh"

# http://php.net/manual/en/extensions.membership.php

# core extensions
sudo yum install -y php
# These are not actual extensions. They are part of the PHP core and cannot be left out of a PHP binary with compilation options.
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(catapult company.timezone_redhat)\"#g" /etc/php.ini

# bundled extensions
# These extensions are bundled with PHP.
sudo yum install -y php-gd
sudo yum install -y php-mbstring

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
# pecl extension: yaml
# https://pecl.php.net/package/yaml
sudo yum install -y libyaml-devel
echo autodetect | sudo pecl upgrade yaml
# pecl extension: geoip
# https://pecl.php.net/package/geoip
sudo yum install -y geoip-devel
# this is a beta release but includes a 3 year gap of bug fixes and new functions
sudo pecl install geoip-1.1.0
echo autodetect | sudo pecl upgrade geoip
# http://dev.maxmind.com/geoip/legacy/geolite/
sudo wget --quiet --read-timeout=10 --tries=5 --output-document=/usr/share/GeoIP/GeoIP.dat.gz  http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
sudo gunzip --force /usr/share/GeoIP/GeoIP.dat.gz
sudo wget --quiet --read-timeout=10 --tries=5 --output-document=/usr/share/GeoIP/GeoIPCity.dat.gz  http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
sudo gunzip --force /usr/share/GeoIP/GeoIPCity.dat.gz
sudo wget --quiet --read-timeout=10 --tries=5 --output-document=/usr/share/GeoIP/GeoIPASNum.dat.gz  http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
sudo gunzip --force /usr/share/GeoIP/GeoIPASNum.dat.gz

# restart httpd for changes to reflect
systemctl reload httpd.service
