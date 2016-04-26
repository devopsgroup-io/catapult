source "/catapult/provisioners/redhat/modules/catapult.sh"

# install dependancies
sudo yum install -y php
sudo yum install -y php-cli
sudo yum install -y php-dom
sudo yum install -y php-gd
sudo yum install -y php-mbstring
sudo yum install -y php-mysql
sudo yum install -y php-posix
sudo yum install -y mariadb

# install drush
if [ ! -f /usr/bin/drush ]; then
    curl --silent --show-error --connect-timeout 5 --max-time 5 https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
    cd /usr/local/src/drush \
        && ln -s /usr/local/src/drush/drush /usr/bin/drush
fi
composer self-update
cd /usr/local/src/drush \
    && git fetch \
    && git checkout --force 7.1.0 \
    && composer install
echo -e "\nDRUSH $(drush --version --format=string)"

# install wp-cli
php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --version
