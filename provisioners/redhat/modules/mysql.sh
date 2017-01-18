source "/catapult/provisioners/redhat/modules/catapult.sh"

# install mariadb
sudo yum -y install mariadb mariadb-server
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service

# configure mysql conf so user/pass isn't logged in shell history or memory
sudo cat > "/catapult/provisioners/redhat/installers/temp/${1}.cnf" << EOF
[client]
host = "localhost"
user = "root"
password = "$(catapult environments.${1}.servers.redhat_mysql.mysql.root_password)"
EOF
# set a variable to the .cnf
dbconf="/catapult/provisioners/redhat/installers/temp/${1}.cnf"

# only set root password on fresh install of mysql
if mysqladmin --defaults-extra-file=$dbconf ping 2>&1 | grep -q "failed"; then
    sudo mysqladmin -u root password "$(catapult environments.${1}.servers.redhat_mysql.mysql.root_password)"
fi

# disable remote root login
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1')"

# remove anonymous user
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user=''"

# clear out all users except root
mysql --defaults-extra-file=$dbconf -e "DELETE FROM mysql.user WHERE user!='root'"

# tune mysql
mysql --defaults-extra-file=$dbconf -e "SET global max_allowed_packet=1024 * 1024 * 64;"

# create an array of domainvaliddbnames
while IFS='' read -r -d '' key; do
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_" | tr "-" "_")
    domainvaliddbnames+=(${1}_${domainvaliddbname})
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup databases from domainvaliddbnames array
for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
    if ! [[ ${domainvaliddbnames[*]} =~ $database ]]; then
        echo "Removing the ${database} database as it does not exist in your configuration..."
        mysql --defaults-extra-file=$dbconf -e "DROP DATABASE $database";
    fi
done

# clear and create mysql user
# @todo user per db? 16 char limit
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO '$(catapult environments.${1}.servers.redhat_mysql.mysql.user)'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER '$(catapult environments.${1}.servers.redhat_mysql.mysql.user)'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER '$(catapult environments.${1}.servers.redhat_mysql.mysql.user)'@'%' IDENTIFIED BY '$(catapult environments.${1}.servers.redhat_mysql.mysql.user_password)'"

# clear and create maintenance user
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO 'maintenance'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER 'maintenance'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER 'maintenance'@'%'"

# apply mysql and maintenance user grant to website => software databases
echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_" | tr "-" "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")

    if test -n "${software}"; then
        # grant mysql user to database
        mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON ${1}_${domainvaliddbname}.* TO '$(catapult environments.${1}.servers.redhat_mysql.mysql.user)'@'%'";
        # grant maintenance user to database
        mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON ${1}_${domainvaliddbname}.* TO 'maintenance'@'%'";
    fi

done

# flush privileges
mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"
