#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive


provisionstart=$(date +%s)
sudo touch /vagrant/provisioners/redhat_mysql/logs/provision.log


echo -e "==> Updating existing packages and installing utilities"
start=$(date +%s)
# update yum
sudo yum update -y
# git clones
sudo yum install -y git
# parse yaml
sudo easy_install pip
sudo pip install shyaml
# wpi-cli dependancies
sudo yum install -y php-cli
sudo yum install -y php-mysql
end=$(date +%s)
echo "[$(date)] Updating existing packages and installing utilities ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


echo -e "\n\n==> Configuring time"
start=$(date +%s)
# set timezone
sudo timedatectl set-timezone "$(cat /vagrant/configuration.yml | shyaml get-value company.timezone_redhat)"
# install ntp
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service
# echo datetimezone
date
end=$(date +%s)
echo "[$(date)] Configuring time ($(($end - $start)) seconds" >> /vagrant/provisioners/redhat_mysql/logs/provision.log
    

echo -e "\n\n==> Installing MySQL"
start=$(date +%s)
# install mariadb
sudo yum -y install mariadb mariadb-server
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
end=$(date +%s)
echo "[$(date)] Installing MySQL ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


echo -e "\n\n==> Configuring MySQL"
start=$(date +%s)
# set variables from configuration.yml
mysql_user="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
drupal_admin_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.software.drupal.admin_password)"
wordpress_admin_password="$(cat /vagrant/configuration.yml | shyaml get-value environments.$1.software.wordpress.admin_password)"
company_email="$(cat /vagrant/configuration.yml | shyaml get-value company.email)"

# configure mysql conf so user/pass isn't logged in shell history or memory
sudo cat > "/vagrant/provisioners/redhat_mysql/installers/$1.cnf" << EOF
[client]
host = "localhost"
user = "root"
password = "$mysql_root_password"
EOF
dbconf="/vagrant/provisioners/redhat_mysql/installers/$1.cnf"

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
# clear out all of the databases except default
for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema");
    do mysql --defaults-extra-file=$dbconf -e "drop database $database";
done

# create global user
# @ todo user per db? 16 char limit
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO '$mysql_user'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER '$mysql_user'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER '$mysql_user'@'%' IDENTIFIED BY '$mysql_user_password'"

# flush privileges
mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"

cat /vagrant/configuration.yml | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")

    if test -n "$software"; then
        if [ "$software" = "codeigniter2" ] || [ "$software" = "drupal6" ] || [ "$software" = "drupal7" ] || [ "$software" = "wordpress" ]; then
            # create database
            mysql --defaults-extra-file=$dbconf -e "CREATE DATABASE $1_$domainvaliddbname"
            # grant user to database
            mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON $1_$domainvaliddbname.* TO '$mysql_user'@'%'";
            # flush privileges
            mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"
            # confirm we have a usable database backup
            if [ -d "/vagrant/repositories/apache/$domain/_sql" ]; then
                echo -e "NOTICE: $1.$domain"
                echo -e "\t/repositories/$domain/_sql directory exists"
                filenewest=$(ls "/vagrant/repositories/apache/$domain/_sql" | grep \.sql$ | sort -n | tail -1)
                for file in /vagrant/repositories/apache/$domain/_sql/*.*; do
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
                            sed -r -e "s/:\/\/(www\.)?${domain}/:\/\/\1${1}\.${domain}/g" "/vagrant/repositories/apache/$domain/_sql/$(basename "$file")" > "/vagrant/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        else
                            cp "/vagrant/repositories/apache/$domain/_sql/$(basename "$file")" "/vagrant/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        fi
                        mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname < "/vagrant/repositories/apache/$domain/_sql/$1.$(basename "$file")"
                        rm -f "/vagrant/repositories/apache/$domain/_sql/$1.$(basename "$file")"
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
                            php /vagrant/provisioners/redhat/installers/wp-cli.phar --path="/vagrant/repositories/apache/$domain/" search-replace "$domain" "$1.$domain" | sed "s/^/\t\t/"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='$company_email' WHERE option_name = 'admin_email';"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='http://$1.$domain' WHERE option_name = 'home';"
                            mysql --defaults-extra-file=$dbconf $1_$domainvaliddbname -e "UPDATE ${software_dbprefix}options SET option_value='http://$1.$domain' WHERE option_name = 'siteurl';"
                        fi
                    fi
                done
            else
                echo -e "WARNING: $1.$domain"
                echo -e "\t/repositories/$domain/_sql does not exist - $software will not function"
            fi
        fi
    fi

done
# remove .cnf file after usage
sudo rm -f /vagrant/provisioners/redhat_mysql/installers/$1.cnf
end=$(date +%s)
echo "[$(date)] Configuring MySQL ($(($end - $start)) seconds)" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) seconds)"
echo -e "[$(date)] Provision complete ($(($provisionend - $provisionstart)) total seconds)\n" >> /vagrant/provisioners/redhat_mysql/logs/provision.log


exit 0
