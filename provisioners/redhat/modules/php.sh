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

# pecl extensions
sudo yum install -y php-pear
sudo yum install -y php-devel
sudo pear config-set php_ini /etc/php.ini
sudo yum install -y gcc
# These extensions are available from » PECL. They may require external libraries. More PECL extensions exist but they are not documented in the PHP manual yet.
sudo yum install -y libyaml-devel
echo autodetect | sudo pecl upgrade yaml

# restart httpd for changes to reflect
systemctl reload httpd.service
