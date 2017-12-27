source "/catapult/provisioners/redhat/modules/catapult.sh"

# http://php.net/manual/en/extensions.membership.php

#################
# PHP 7.0 PHP_FPM
# /opt/rh/rh-php70/root/usr/bin/php
# /etc/opt/rh/rh-php70/php.ini
# sudo yum list \*-php70-\*
#################

# core extensions
sudo yum install -y centos-release-scl
sudo yum install -y rh-php70
# These are not actual extensions. They are part of the PHP core and cannot be left out of a PHP binary with compilation options.

# configure php-fpm
if ([ "${4}" == "apache" ]); then
    sudo yum install -y rh-php70-php-fpm
    sed -i -e "s#^listen = 127.0.0.1:9000#listen = 127.0.0.1:9700#g" /etc/opt/rh/rh-php70/php-fpm.d/www.conf
    sudo systemctl enable rh-php70-php-fpm
    sudo systemctl start rh-php70-php-fpm
fi

# php.ini configuration options
# set the timezone
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(catapult company.timezone_redhat)\"#g" /etc/opt/rh/rh-php70/php.ini
# increase the upload_max_filesize
sed -i -e "s#^upload_max_filesize.*#upload_max_filesize = 10M#g" /etc/opt/rh/rh-php70/php.ini
# hide x-powered-by
sed -i -e "s#^expose_php.*#expose_php = Off#g" /etc/opt/rh/rh-php70/php.ini
# increase php memory limit for tools like composer
sed -i -e "s#^memory_limit.*#memory_limit = 256M#g" /etc/opt/rh/rh-php70/php.ini
# display errors on screen using the default recommendations for development and production
if [ "$1" = "dev" ]; then
    sed -i -e "s#^display_errors.*#display_errors = On#g" /etc/opt/rh/rh-php70/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL#g" /etc/opt/rh/rh-php70/php.ini
else
    sed -i -e "s#^display_errors.*#display_errors = Off#g" /etc/opt/rh/rh-php70/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT#g" /etc/opt/rh/rh-php70/php.ini
fi

# bundled extensions
# These extensions are bundled with PHP.
sudo yum install -y rh-php70-php-gd
sudo yum install -y rh-php70-php-intl
sudo yum install -y rh-php70-php-mbstring
sudo yum install -y rh-php70-php-opcache
# disable opcache for dev
if [ "$1" = "dev" ]; then
    sudo bash -c 'echo "/var/www" > /etc/opt/rh/rh-php70/php.d/opcache-default.blacklist'
else
    sudo bash -c 'echo "" > /etc/opt/rh/rh-php70/php.d/opcache-default.blacklist'
fi
sudo yum install -y rh-php70-php-soap
sudo yum install -y rh-php70-php-xmlrpc

# external extensions
# These extensions are bundled with PHP but in order to compile them, external libraries will be needed.
sudo yum install -y rh-php70-php-gmp
sudo yum install -y rh-php70-php-mysqlnd

# pecl extensions
# https://blog.remirepo.net/post/2017/02/23/Additional-PHP-packages-for-RHSCL
curl --output /etc/yum.repos.d/rhscl-centos-release-scl-epel-7.repo wget https://copr.fedorainfracloud.org/coprs/rhscl/centos-release-scl/repo/epel-7/rhscl-centos-release-scl-epel-7.repo
sudo yum install -y centos-release-scl
# These extensions are available from » PECL. They may require external libraries. More PECL extensions exist but they are not documented in the PHP manual yet.
sudo yum install -y sclo-php70-php-pecl-geoip
sudo yum install -y sclo-php70-php-pecl-uploadprogress


#################
# PHP 5.6 PHP_FPM
# /opt/rh/rh-php56/root/usr/bin/php
# /etc/opt/rh/rh-php56/php.ini
# sudo yum list \*-php56-\*
#################

# core extensions
sudo yum install -y centos-release-scl
sudo yum install -y rh-php56
# These are not actual extensions. They are part of the PHP core and cannot be left out of a PHP binary with compilation options.

# configure php-fpm
if ([ "${4}" == "apache" ]); then
    sudo yum install -y rh-php56-php-fpm
    sed -i -e "s#^listen = 127.0.0.1:9000#listen = 127.0.0.1:9560#g" /etc/opt/rh/rh-php56/php-fpm.d/www.conf
    sudo systemctl enable rh-php56-php-fpm
    sudo systemctl start rh-php56-php-fpm
fi

# php.ini configuration options
# set the timezone
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(catapult company.timezone_redhat)\"#g" /etc/opt/rh/rh-php56/php.ini
# increase the upload_max_filesize
sed -i -e "s#^upload_max_filesize.*#upload_max_filesize = 10M#g" /etc/opt/rh/rh-php56/php.ini
# hide x-powered-by
sed -i -e "s#^expose_php.*#expose_php = Off#g" /etc/opt/rh/rh-php56/php.ini
# increase php memory limit for tools like composer
sed -i -e "s#^memory_limit.*#memory_limit = 256M#g" /etc/opt/rh/rh-php56/php.ini
# display errors on screen using the default recommendations for development and production
if [ "$1" = "dev" ]; then
    sed -i -e "s#^display_errors.*#display_errors = On#g" /etc/opt/rh/rh-php56/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL#g" /etc/opt/rh/rh-php56/php.ini
else
    sed -i -e "s#^display_errors.*#display_errors = Off#g" /etc/opt/rh/rh-php56/php.ini
    sed -i -e "s#^error_reporting.*#error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT#g" /etc/opt/rh/rh-php56/php.ini
fi

# bundled extensions
# These extensions are bundled with PHP.
sudo yum install -y rh-php56-php-gd
sudo yum install -y rh-php56-php-intl
sudo yum install -y rh-php56-php-mbstring
sudo yum install -y rh-php56-php-opcache
# disable opcache for dev
if [ "$1" = "dev" ]; then
    sudo bash -c 'echo "/var/www" > /etc/opt/rh/rh-php56/php.d/opcache-default.blacklist'
else
    sudo bash -c 'echo "" > /etc/opt/rh/rh-php56/php.d/opcache-default.blacklist'
fi
sudo yum install -y rh-php56-php-soap
sudo yum install -y rh-php56-php-xmlrpc

# external extensions
# These extensions are bundled with PHP but in order to compile them, external libraries will be needed.
sudo yum install -y rh-php56-php-gmp
sudo yum install -y rh-php56-php-mysqlnd

# pecl extensions
# https://blog.remirepo.net/post/2017/02/23/Additional-PHP-packages-for-RHSCL
curl --output /etc/yum.repos.d/rhscl-centos-release-scl-epel-7.repo wget https://copr.fedorainfracloud.org/coprs/rhscl/centos-release-scl/repo/epel-7/rhscl-centos-release-scl-epel-7.repo
sudo yum install -y centos-release-scl
# These extensions are available from » PECL. They may require external libraries. More PECL extensions exist but they are not documented in the PHP manual yet.
sudo yum install -y sclo-php56-php-pecl-geoip
sudo yum install -y sclo-php56-php-pecl-uploadprogress


#################
# PHP 5.4 MOD_PHP
# /usr/bin/php
# /etc/php.ini
# sudo yum list php-\*
#################

# core extensions
sudo yum install -y php
sudo yum install -y php-cli
# These are not actual extensions. They are part of the PHP core and cannot be left out of a PHP binary with compilation options.

# configure php-fpm
if ([ "${4}" == "apache" ]); then
    sudo yum install -y php-fpm
    sed -i -e "s#^listen = 127.0.0.1:9000#listen = 127.0.0.1:9540#g" /etc/php-fpm.d/www.conf
    sudo systemctl enable php-fpm
    sudo systemctl start php-fpm
fi

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
sudo yum install -y php-intl
sudo yum install -y php-mbstring
sudo yum install -y php-posix
sudo yum install -y php-soap
sudo yum install -y php-xmlrpc

# external extensions
# These extensions are bundled with PHP but in order to compile them, external libraries will be needed.
sudo yum install -y php-curl
sudo yum install -y php-dom
sudo yum install -y php-gmp
sudo yum install -y php-mysql

# epel extensions
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
# disable opcache for dev
if [ "$1" = "dev" ]; then
    sudo bash -c 'echo "/var/www" > /etc/php.d/opcache-default.blacklist'
else
    sudo bash -c 'echo "" > /etc/php.d/opcache-default.blacklist'
fi
#################
# pecl extension: yaml
# https://pecl.php.net/package/yaml
sudo yum install -y libyaml-devel
echo autodetect | sudo pecl upgrade yaml-1.3.1
#################
# pecl extension: geoip
# https://pecl.php.net/package/geoip
sudo yum install -y geoip-devel
# this is a beta release but includes a 3 year gap of bug fixes and new functions
sudo pecl install geoip-1.1.0
echo autodetect | sudo pecl upgrade geoip
#################
# pecl extension: uploadprogress
# http://pecl.php.net/package/uploadprogress
sudo pecl upgrade uploadprogress
#################
# output installed pecl extensions once finished
sudo pecl list


#################
# GEOIP DATA FILES
#################

# http://dev.maxmind.com/geoip/legacy/geolite/
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIP.dat.gz" --request GET "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIP.dat.gz"
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIPCity.dat.gz" --request GET "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIPCity.dat.gz"
curl --silent --show-error --connect-timeout 10 --max-time 20 --retry 5 --output "/usr/share/GeoIP/GeoIPASNum.dat.gz" --request GET "http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz"
sudo gunzip --force "/usr/share/GeoIP/GeoIPASNum.dat.gz"



if ([ "${4}" == "apache" ]); then
    #################
    # NEW RELIC PHP APM
    #################
    # add the new relic yum repository
    rpm --hash --upgrade --verbose https://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm
    # install the new relic apm php package
    sudo yum install -y newrelic-php5
    # set the apm php appname
    sed --in-place --expression "s#newrelic\.appname.*#newrelic.appname = \"$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat\"#g" "/etc/php.d/newrelic.ini"

    # manually configure rh-php70
    rm --force --recursive "/usr/share/newrelic"
    mkdir "/usr/share/newrelic"
    # https://download.newrelic.com/php_agent/release/
    cd "/usr/share/newrelic" && gzip --decompress --stdout "/catapult/provisioners/redhat/installers/newrelic/newrelic-php5-7.6.0.201-linux.tar.gz" | tar xf -
    rm --force "/opt/rh/rh-php70/root/usr/lib64/php/modules/newrelic.so"
    cp "/usr/share/newrelic/newrelic-php5-7.6.0.201-linux/agent/x64/newrelic-20151012.so" "/opt/rh/rh-php70/root/usr/lib64/php/modules/newrelic.so"
    sed --in-place --expression "s/\"REPLACE_WITH_REAL_KEY\"/\"$(catapult company.newrelic_license_key)\"/g" "/usr/share/newrelic/newrelic-php5-7.6.0.201-linux/scripts/newrelic.ini.template"
    sed --in-place --expression "s#newrelic\.appname.*#newrelic.appname = \"$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat\"#g" "/usr/share/newrelic/newrelic-php5-7.6.0.201-linux/scripts/newrelic.ini.template"
    cp "/usr/share/newrelic/newrelic-php5-7.6.0.201-linux/scripts/newrelic.ini.template" "/etc/opt/rh/rh-php70/php.d/newrelic.ini"

    # apm php installed but we need to set configuration
    NR_INSTALL_PHPLIST="/usr/bin:/opt/rh/rh-php56/root/usr/bin:/opt/rh/rh-php70/root/usr/bin", NR_INSTALL_SILENT="true", NR_INSTALL_KEY="$(catapult company.newrelic_license_key)" /usr/bin/newrelic-install install
    # ensure newrelic daemon is started with latest configuration
    /etc/init.d/newrelic-daemon start
    /etc/init.d/newrelic-daemon reload
    /etc/init.d/newrelic-daemon status
    tail /var/log/newrelic/newrelic-daemon.log
    tail /var/log/newrelic/php_agent.log

    echo -e "\n> php 7.0 configuration"
    /opt/rh/rh-php70/root/usr/bin/php --version
    /opt/rh/rh-php70/root/usr/bin/php --modules

    echo -e "\n> php 5.6 configuration"
    /opt/rh/rh-php56/root/usr/bin/php --version
    /opt/rh/rh-php56/root/usr/bin/php --modules

    echo -e "\n> php 5.4 configuration"
    /usr/bin/php --version
    /usr/bin/php --modules

    # reload php-fpm for configuration changes to take effect
    sudo systemctl reload rh-php70-php-fpm
    sudo systemctl reload rh-php56-php-fpm
    sudo systemctl reload php-fpm
    # reload httpd for configuration changes to take effect
    sudo systemctl reload httpd.service
    
    # a start may be needed if we've just installed php-fpm
    # cat /var/log/httpd/error_log
    # [Tue Dec 26 21:06:23.816950 2017] [mpm_prefork:notice] [pid 792] AH00171: Graceful restart requested, doing restart
    # [Tue Dec 26 21:06:24.648573 2017] [core:notice] [pid 792] AH00060: seg fault or similar nasty error detected in the parent process
    sudo systemctl start rh-php70-php-fpm
    sudo systemctl start rh-php56-php-fpm
    sudo systemctl start php-fpm
    sudo systemctl start httpd.service
fi
