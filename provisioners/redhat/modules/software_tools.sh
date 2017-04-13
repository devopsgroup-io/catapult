source "/catapult/provisioners/redhat/modules/catapult.sh"


# install dependancies, relies on php.sh
sudo yum install -y mariadb


echo "> configuring composer"
if [ ! -f /usr/bin/composer ]; then

    mkdir --parents /usr/local/src/composer
    cd /usr/local/src/composer

    curl --silent --show-error --connect-timeout 5 --max-time 5 --retry 5 --location --url https://getcomposer.org/installer | php

    ln -s /usr/local/src/composer/composer.phar /usr/bin/composer

fi
# update to latest composer
composer self-update
composer --version


echo "> configuring drush"
if [ ! -f /usr/bin/drush ]; then

    mkdir --parents /usr/local/src/drush
    cd /usr/local/src/drush

    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush

    ln -s /usr/local/src/drush/drush /usr/bin/drush

fi
# update to specific drush version
cd /usr/local/src/drush \
    && git fetch \
    && git checkout --force 8.1.10 \
    && composer install
drush --version


echo "> configuring wp-cli"
if [ ! -f /usr/bin/wp-cli ]; then

    mkdir --parents /usr/local/src/wp-cli
    cd /usr/local/src/wp-cli

    curl --silent --show-error --connect-timeout 5 --max-time 5 --output wp-cli.phar --retry 5 --location --url https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    # wp-cli requires special permissions
    chmod +x wp-cli.phar

    ln -s /usr/local/src/wp-cli/wp-cli.phar /usr/bin/wp-cli

fi
# update to latest wp-cli
wp-cli --allow-root cli update --yes
wp-cli --allow-root cli version
