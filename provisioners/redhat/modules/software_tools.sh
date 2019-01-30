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
# configure php version
if ! grep -q "alias composer-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/composer/composer.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias composer-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/composer/composer.phar'\" >> ~/.bashrc"
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
# configure php version
# http://docs.drush.org/en/master/install/
if ! grep -q "export DRUSH_PHP='/opt/rh/rh-php71/root/usr/bin/php'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nexport DRUSH_PHP='/opt/rh/rh-php71/root/usr/bin/php'\" >> ~/.bashrc"
fi
# update to specific drush version
cd /usr/local/src/drush \
    && git fetch \
    && git checkout --force 8.1.18 \
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
# configure php version
# https://github.com/wp-cli/wp-cli#installing
# https://make.wordpress.org/cli/handbook/installing/#using-a-custom-php-binary
if ! grep -q "alias wp-cli-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias wp-cli-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'\" >> ~/.bashrc"
fi
# update to latest wp-cli
wp-cli --allow-root cli update --yes
wp-cli --allow-root cli version


# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
