source "/catapult/provisioners/redhat/modules/catapult.sh"


# install dependencies, relies on php.sh
sudo yum install -y mariadb
sudo yum install -y unzip


echo "> configuring composer"
if [ ! -f /usr/bin/composer ]; then
    mkdir --parents /usr/local/src/composer
    cd /usr/local/src/composer && curl --silent --show-error --connect-timeout 5 --max-time 5 --retry 5 --location --url https://getcomposer.org/installer | php
    ln -s /usr/local/src/composer/composer.phar /usr/bin/composer
fi
# update to latest composer
composer self-update
# output the version
composer --version


echo "> configuring composer-php71"
# configure php version
if ! grep -q "alias composer-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/composer/composer.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias composer-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/composer/composer.phar'\" >> ~/.bashrc"
fi
# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
# output the version
composer-php71 --version


echo "> configuring composer-php72"
# configure php version
if ! grep -q "alias composer-php72='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/composer/composer.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias composer-php72='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/composer/composer.phar'\" >> ~/.bashrc"
fi
# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
# output the version
composer-php72 --version


echo "> configuring drush"
if [ ! -f /usr/bin/drush ]; then
    mkdir --parents /usr/local/src/drush
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
    ln -s /usr/local/src/drush/drush /usr/bin/drush
fi
# update to specific drush version
cd /usr/local/src/drush \
    && git fetch \
    && git checkout --force 8.4.8 \
    && composer-php71 install
# configure php version
# http://docs.drush.org/en/master/install/
if ! grep -q "export DRUSH_PHP='/opt/rh/rh-php71/root/usr/bin/php'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nexport DRUSH_PHP='/opt/rh/rh-php71/root/usr/bin/php'\" >> ~/.bashrc"
fi
# output the version
drush --version


echo "> configuring drush10"
if [ ! -f /usr/bin/drush10 ]; then
    mkdir --parents /usr/local/src/drush10
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush10
    ln -s /usr/local/src/drush10/drush /usr/bin/drush10
fi
# update to specific drush version
cd /usr/local/src/drush10 \
    && git fetch \
    && git checkout --force 10.4.0 \
    && composer-php72 install
if ! grep -q "alias drush10='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/drush10/drush'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias drush10='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/drush10/drush'\" >> ~/.bashrc"
fi
# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
# output the version
drush10 --version


echo "> configuring wp-cli"
if [ ! -f /usr/bin/wp-cli ]; then
    mkdir --parents /usr/local/src/wp-cli
    cd /usr/local/src/wp-cli && curl --silent --show-error --connect-timeout 5 --max-time 5 --output wp-cli.phar --retry 5 --location --url https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    # wp-cli requires special permissions
    cd /usr/local/src/wp-cli && chmod +x wp-cli.phar
    ln -s /usr/local/src/wp-cli/wp-cli.phar /usr/bin/wp-cli
fi
# update to latest wp-cli
wp-cli --allow-root cli update --yes
# output the version
wp-cli --allow-root cli version


echo "> configuring wp-cli-php71"
if ! grep -q "alias wp-cli-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias wp-cli-php71='/opt/rh/rh-php71/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'\" >> ~/.bashrc"
fi
# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
# output the version
wp-cli-php71 --allow-root cli version


echo "> configuring wp-cli-php72"
if ! grep -q "alias wp-cli-php72='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'" ~/.bashrc; then
    sudo bash -c "echo -e \"\nalias wp-cli-php72='/opt/rh/rh-php72/root/usr/bin/php /usr/local/src/wp-cli/wp-cli.phar'\" >> ~/.bashrc"
fi
# expose the alternate software tool version aliases
shopt -s expand_aliases
source ~/.bashrc
# output the version
wp-cli-php72 --allow-root cli version
