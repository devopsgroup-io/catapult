#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance
# $5 => software_validation



echo -e "==> Updating existing packages and installing utilities"
start=$(date +%s)
# only allow authentication via ssh key pair
# suppress this - There were 34877 failed login attempts since the last successful login.
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sudo systemctl stop sshd.service
sudo systemctl start sshd.service
# update yum
sudo yum update -y
# git clones
sudo yum install -y git
# parse yaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
configuration=$(gpg --batch --passphrase ${3} --decrypt /catapult/secrets/configuration.yml.gpg)
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa --decrypt /catapult/secrets/id_rsa.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa.pub --decrypt /catapult/secrets/id_rsa.pub.gpg
chmod 700 /catapult/secrets/id_rsa
chmod 700 /catapult/secrets/id_rsa.pub
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring time"
start=$(date +%s)
# set timezone
sudo timedatectl set-timezone "$(echo "${configuration}" | shyaml get-value company.timezone_redhat)"
# install ntp
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service
# echo datetimezone
date
provisionstart=$(date +%s)
sudo touch /catapult/provisioners/redhat/logs/mysql.log
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing Drush and WP-CLI"
start=$(date +%s)
sudo yum install -y php-cli
sudo yum install -y mariadb
# install drush
if [ ! -f /usr/bin/drush  ]; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
    cd /usr/local/src/drush
    git checkout 7.0.0-rc1
    ln -s /usr/local/src/drush/drush /usr/bin/drush
    composer install
fi
drush --version
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing MySQL"
start=$(date +%s)
# install mariadb
sudo yum -y install mariadb mariadb-server
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring git repositories (This may take a while...)"
start=$(date +%s)
source ./modules/git.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring MySQL"
start=$(date +%s)
# set variables from secrets/configuration.yml
mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
drupal_admin_password="$(echo "${configuration}" | shyaml get-value environments.$1.software.drupal.admin_password)"
wordpress_admin_password="$(echo "${configuration}" | shyaml get-value environments.$1.software.wordpress.admin_password)"
company_email="$(echo "${configuration}" | shyaml get-value company.email)"

# configure mysql conf so user/pass isn't logged in shell history or memory
sudo cat > "/catapult/provisioners/redhat/installers/$1.cnf" << EOF
[client]
host = "localhost"
user = "root"
password = "$mysql_root_password"
EOF
dbconf="/catapult/provisioners/redhat/installers/$1.cnf"

# only set root password on fresh install of mysql
if mysqladmin --defaults-extra-file=$dbconf ping 2>&1 | grep -q "failed"; then
    sudo mysqladmin -u root password "$mysql_root_password"
fi

# disable remote root login
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1')"
# remove anonymous user
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user=''"

# configure outside access to mysql
iptables -I INPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -I OUTPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

# clear out all users except root
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user!='root'"

# create an array of domainvaliddbnames
while IFS='' read -r -d '' key; do
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    domainvaliddbnames+=($1_$domainvaliddbname)
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup databases from domainvaliddbnames array
for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
    if ! [[ ${domainvaliddbnames[*]} =~ $database ]]; then
        echo "Cleaning up websites that no longer exist..."
        mysql --defaults-extra-file=$dbconf -e "DROP DATABASE $database";
    fi
done

# create global user
# @ todo user per db? 16 char limit
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO '$mysql_user'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER '$mysql_user'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER '$mysql_user'@'%' IDENTIFIED BY '$mysql_user_password'"

# flush privileges
mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    software_dbexist=$(mysql --defaults-extra-file=$dbconf -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$1_$domainvaliddbname'")

    if [ "$1" = "production" ]; then
        echo -e "\nNOTICE: ${domain}"
    else
        echo -e "\nNOTICE: ${1}.${domain}"
    fi
    if ! test -n "$software"; then
        echo -e "\t* skipping database creation/restore as this website does not require a database"
    else
        # respect software_workflow option
        if ([ "$1" = "production" ] && [ "$software_workflow" = "downstream" ] && [ "$software_dbexist" != "" ]) || ([ "$1" = "test" ] && [ "$software_workflow" = "upstream" ] && [ "$software_dbexist" != "" ]); then
            echo -e "\t* skipping database creation/restore as this website's software_workflow is set to ${software_workflow} and this is the ${1} environment"
        else
            # drop the database
            for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
                if [ ${database} = ${1}_${domainvaliddbname} ]; then
                    mysql --defaults-extra-file=$dbconf -e "DROP DATABASE $1_$domainvaliddbname";
                fi
            done
            # create database
            mysql --defaults-extra-file=$dbconf -e "CREATE DATABASE $1_$domainvaliddbname"
            # confirm we have a usable database backup
            if ! [ -d "/var/www/repositories/apache/$domain/_sql" ]; then
                echo -e "\t* /repositories/$domain/_sql does not exist - $software will not function"
            else
                echo -e "\t* /repositories/$domain/_sql directory exists"
                filenewest=$(ls "/var/www/repositories/apache/$domain/_sql" | grep -E ^[0-9]{8}\.sql$ | sort -n | tail -1)
                for file in /var/www/repositories/apache/$domain/_sql/*.*; do
                    filename=$(basename "$file")
                    filename="${filename%.*}"
                    if [[ "$file" != *.sql ]]; then
                        echo -e "\t[invalid] [ ].sql [ ]YYYYMMDD.sql [ ]newest => $file"
                    elif ! [[ "$filename" =~ ^[0-9]{8}$ ]]; then
                        echo -e "\t[invalid] [x].sql [ ]YYYYMMDD.sql [ ]newest => $file"
                    elif [[ $(basename "$file") != "$filenewest" ]]; then
                        echo -e "\t[invalid] [x].sql [x]YYYYMMDD.sql [ ]newest => $file"
                    else
                        echo -e "\t[valid]   [x].sql [x]YYYYMMDD.sql [x]newest => $file"
                        echo -e "\t\trestoring..."
                        # match http:// and optionally www. then replace with http:// + optionally www. + either dev., test., or the production domain
                        if [[ "$software" != "wordpress" ]]; then
                            sed -r -e "s/:\/\/(www\.)?${domain}/:\/\/\1${1}\.${domain}/g" "/var/www/repositories/apache/$domain/_sql/$(basename "$file")" > "/var/www/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        else
                            cp "/var/www/repositories/apache/$domain/_sql/$(basename "$file")" "/var/www/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        fi
                        mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname < "/var/www/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        rm -f "/var/www/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        if [[ "$software" = "drupal6" ]]; then
                            echo -e "\t\tresetting ${software} admin password..."
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}users SET name='admin', mail='$company_email', pass=MD5('$drupal_admin_password'), status='1' WHERE uid = 1;"
                        fi
                        if [[ "$software" = "drupal7" ]]; then
                            echo -e "\t\tresetting ${software} admin password..."
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}users SET name='admin', mail='$company_email', pass='\$S\$D149zKa2wanV2uiRSpTuhD.hiIiFo0rRmxrRLTQjtM4VV5xtNKPR', status='1' WHERE uid = 1;"
                        fi
                        if [[ "$software" = "wordpress" ]]; then
                            echo -e "\t\tresetting ${software} admin password..."
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}users SET user_login='admin', user_email='$company_email', user_pass=MD5('$wordpress_admin_password'), user_status='0' WHERE id = 1;"
                            echo -e "\t\tupdating $software database with ${1}.${domainvaliddbname} URL"
                            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/$domain/" search-replace "$domain" "$1.$domain" | sed "s/^/\t\t/"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='$company_email' WHERE option_name = 'admin_email';"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='http://$1.$domain' WHERE option_name = 'home';"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='http://$1.$domain' WHERE option_name = 'siteurl';"
                        fi
                    fi
                done
            fi
        fi
        # grant user to database
        mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON $1_$domainvaliddbname.* TO '$mysql_user'@'%'";
        # flush privileges
        mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"
    fi

done
# remove .cnf file after usage
sudo rm -f /catapult/provisioners/redhat/installers/$1.cnf
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) total seconds)"


exit 0
