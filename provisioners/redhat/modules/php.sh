source "/catapult/provisioners/redhat/modules/catapult.sh"

#@todo think about having directive per website that lists php module dependancies
sudo yum install -y php
sudo yum install -y php-curl
sudo yum install -y php-dom
sudo yum install -y php-gd
sudo yum install -y php-mbstring
sudo yum install -y php-mysql
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(catapult company.timezone_redhat)\"#g" /etc/php.ini
