source "/catapult/provisioners/redhat/modules/catapult.sh"

# install mariadb
sudo yum -y install mariadb mariadb-server
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service

# configure mysql conf so user/pass isn't logged in shell history or memory
sudo cat > "/catapult/provisioners/redhat/installers/${1}.cnf" << EOF
[client]
host = "localhost"
user = "root"
password = "$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.root_password)"
EOF
dbconf="/catapult/provisioners/redhat/installers/${1}.cnf"

# only set root password on fresh install of mysql
if mysqladmin --defaults-extra-file=$dbconf ping 2>&1 | grep -q "failed"; then
    sudo mysqladmin -u root password "$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.root_password)"
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
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    domainvaliddbnames+=(${1}_${domainvaliddbname})
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup databases from domainvaliddbnames array
for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
    if ! [[ ${domainvaliddbnames[*]} =~ $database ]]; then
        echo "Cleaning up websites that no longer exist..."
        mysql --defaults-extra-file=$dbconf -e "DROP DATABASE $database";
    fi
done

# clear and create mysql user
# @todo user per db? 16 char limit
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO '$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user)'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER '$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user)'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER '$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user)'@'%' IDENTIFIED BY '$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user_password)'"

# clear and create maintenance user
mysql --defaults-extra-file=$dbconf -e "GRANT USAGE ON *.* TO 'maintenance'@'%'"
mysql --defaults-extra-file=$dbconf -e "DROP USER 'maintenance'@'%'"
mysql --defaults-extra-file=$dbconf -e "CREATE USER 'maintenance'@'%'"

# apply mysql and maintenance user grant to website => software databases
echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")

    if test -n "${software}"; then
        # grant mysql user to database
        mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON ${1}_${domainvaliddbname}.* TO '$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.mysql.user)'@'%'";
        # grant maintenance user to database
        mysql --defaults-extra-file=$dbconf -e "GRANT ALL ON ${1}_${domainvaliddbname}.* TO 'maintenance'@'%'";
    fi

done

# flush privileges
mysql --defaults-extra-file=$dbconf -e "FLUSH PRIVILEGES"

# this overwrite all items in cron, we write stdout to > /dev/null so that we only get emailed stderr
cat <(echo "0 3 * * * mysqlcheck -u maintenance --all-databases --auto-repair --optimize > /dev/null") | crontab -
# adding more cron tasks would look like this
# cat <(crontab -l) <(echo "0 4 * * * mysqldump...") | crontab -

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    software_db=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${1}_${domainvaliddbname}'")
    software_db_tables=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${1}_${domainvaliddbname}'")    
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    if [ "${1}" = "production" ]; then
        echo -e "\nNOTICE: ${domain}"
    else
        echo -e "\nNOTICE: ${1}.${domain}"
    fi
    if ! test -n "${software}"; then
        echo -e "\t* this website has no software setting, skipping database workflow"
    else
        # respect software_workflow option
        if ([ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]) || ([ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]); then
            echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, performing a database backup"
            # dump the database as long as it hasn't been dumped for the day already
            # @todo this is intended so that a developer can commit a dump from active work in localdev then the process detect this and kick off the restore rather than dump workflow
            if ! [ -f /var/www/repositories/apache/${domain}/_sql/$(date +"%Y%m%d").sql ]; then
                # create the _sql directory if it does not exist
                mkdir -p "/var/www/repositories/apache/${domain}/_sql"
                # dump the database
                mysqldump --defaults-extra-file=$dbconf --single-transaction --quick ${1}_${domainvaliddbname} > /var/www/repositories/apache/${domain}/_sql/$(date +"%Y%m%d").sql
                # ensure no more than 500mb or at least the one, newest, .sql file exists
                directory_size=$(du --null "/var/www/repositories/apache/${domain}/_sql" | awk '{ print $1 }')
                directory_size_maximum=$(( 1024 * 500 ))
                echo -e "\t* the _sql folder is $(( ${directory_size} / 1024 ))MB, the maximum is $(( ${directory_size_maximum} / 1024 ))MB or the one, newest, .sql file"
                if [ "${directory_size}" -gt "${directory_size_maximum}" ]; then
                    echo -e "\t\t removing the oldest database dumps to get just under the $(( ${directory_size_maximum} / 1024 ))MB maximum or the one, newest, .sql file"
                    directory_size_count=0
                    file_newest=$(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql$ | sort --numeric-sort | tail -1)
                    # add up each file from newest to oldest and remove files that push the total past the maximum _sql directory size
                    for file in $(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql$ | sort --numeric-sort --reverse); do
                        file_size=$(du --null "/var/www/repositories/apache/${domain}/_sql/${file}" | awk '{ print $1 }')
                        directory_size_count=$(( ${directory_size_count} +  ${file_size} ))
                        if [ "${directory_size_count}" -gt "${directory_size_maximum}" ]; then
                            # keep at least the newest file, in case the database dump is greater than the maximum _sql directory size
                            if [[ "$(basename "$file")" != "${file_newest}" ]]; then
                                echo -e "\t\t removing /var/www/repositories/apache/${domain}/_sql/${file}..."
                                sudo rm -f "/var/www/repositories/apache/${domain}/_sql/${file}"
                            fi
                        fi
                    done
                fi
                # git add and commit the _sql folder changes
                cd "/var/www/repositories/apache/${domain}" && git add --all "/var/www/repositories/apache/${domain}/_sql" 2>&1 | sed "s/^/\t/"
                cd "/var/www/repositories/apache/${domain}" && git commit --message="Catapult auto-commit ${1}:${software_workflow}:software_database" 2>&1 | sed "s/^/\t/"
                cd "/var/www/repositories/apache/${domain}" && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git push origin $(catapult environments.$1.branch)" 2>&1 | sed "s/^/\t/"
            else
                echo -e "\t\ta backup was already performed today"
            fi
        else
            if [ -z "${software_db}" ]; then
                echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, however, the database does not exist. performing a database restore..."
            elif [ -z "${software_db_tables}" ]; then
                echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, however, the database exists but contains no tables. performing a database restore..."
            else
                echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, performing a database restore..."
            fi
            # drop the database
            # the loop is necessary just in case the database doesn't yet exist
            for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
                if [ ${database} = ${1}_${domainvaliddbname} ]; then
                    mysql --defaults-extra-file=$dbconf -e "DROP DATABASE ${1}_${domainvaliddbname}";
                fi
            done
            # create database
            mysql --defaults-extra-file=$dbconf -e "CREATE DATABASE ${1}_${domainvaliddbname}"
            # confirm we have a usable database backup
            if ! [ -d "/var/www/repositories/apache/${domain}/_sql" ]; then
                echo -e "\t* ~/_sql directory does not exist, ${software} will not function"
            else
                echo -e "\t* ~/_sql directory exists, looking for a valid database dump to restore from"
                filenewest=$(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql$ | sort --numeric-sort | tail -1)
                for file in /var/www/repositories/apache/${domain}/_sql/*.*; do
                    if [[ "${file}" != *.sql ]]; then
                        echo -e "\t\t[invalid] [ ].sql [ ]YYYYMMDD.sql [ ]newest => $file"
                    elif ! [[ "$(basename "${file}")" =~ ^[0-9]{8}.sql$ ]]; then
                        echo -e "\t\t[invalid] [x].sql [ ]YYYYMMDD.sql [ ]newest => $file"
                    elif [[ "$(basename "$file")" != "${filenewest}" ]]; then
                        echo -e "\t\t[invalid] [x].sql [x]YYYYMMDD.sql [ ]newest => $file"
                    else
                        echo -e "\t\t[valid]   [x].sql [x]YYYYMMDD.sql [x]newest => $file"
                        echo -e "\t\t\trestoring..."
                        # support domain_tld_override for URL replacements
                        if [ -z "${domain_tld_override}" ]; then
                            # create replace string and make sure to escape periods
                            domain_url_replace=$(echo -e "${domain}" | sed 's/\./\\./g')
                            # create string of final url
                            if [ "${1}" = "production" ]; then
                                domain_url="${domain}"
                            else
                                domain_url="${1}.${domain}"
                            fi
                        else
                            # create replace string and make sure to escape periods
                            domain_url_replace=$(echo -e "${domain}.${domain_tld_override}|${domain}" | sed 's/\./\\./g')
                            # create string of final url
                            if [ "${1}" = "production" ]; then
                                domain_url="${domain}.${domain_tld_override}"
                            else
                                domain_url="${1}.${domain}.${domain_tld_override}"
                            fi
                        fi
                        # replace variances of the following urls during a restore to match the environment
                        # pay attention to the order of the (${domain}.${domain_tld_override|${domain}}) rule
                        # https://regex101.com/r/vF7hY9/2
                        # :\/\/(www\.)?(dev\.|test\.|qc\.)?(devopsgroup\.io\.example.com|devopsgroup\.io)
                        # ://dev.devopsgroup.io
                        # ://www.dev.devopsgroup.io
                        # ://test.devopsgroup.io
                        # ://www.test.devopsgroup.io
                        # ://devopsgroup.io
                        # ://www.devopsgroup.io
                        # ://dev.devopsgroup.io.example.com
                        # ://www.dev.devopsgroup.io.example.com
                        # ://test.devopsgroup.io.example.com
                        # ://www.test.devopsgroup.io.example.com
                        # ://devopsgroup.io.example.com
                        # ://www.devopsgroup.io.example.com
                        # for software without a cli tool, use sed via the sql file to replace urls
                        if ([ "${software}" = "codeigniter2" ] || [ "${software}" = "codeigniter3" ] || [ "${software}" = "drupal6" ] || [ "${software}" = "drupal7" ] || [ "${software}" = "silverstripe" ] || [ "${software}" = "xenforo" ]); then
                            echo -e "\t* replacing URLs in the database to align with the enivronment..."
                            sed -r --expression="s/:\/\/(www\.)?(dev\.|test\.|qc\.)?(${domain_url_replace})/:\/\/\1${domain_url}/g" "/var/www/repositories/apache/${domain}/_sql/$(basename "$file")" > "/var/www/repositories/apache/${domain}/_sql/${1}.$(basename "$file")"
                        else
                            cp "/var/www/repositories/apache/${domain}/_sql/$(basename "$file")" "/var/www/repositories/apache/${domain}/_sql/${1}.$(basename "$file")"
                        fi
                        # restore the database
                        mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} < "/var/www/repositories/apache/${domain}/_sql/${1}.$(basename "$file")"
                        rm -f "/var/www/repositories/apache/${domain}/_sql/${1}.$(basename "$file")"
                        # for software with a cli tool, use cli tool to replace urls
                        if [[ "${software}" = "wordpress" ]]; then
                            echo -e "\t* replacing URLs in the database to align with the enivronment..."
                            php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" search-replace ":\/\/(www\.)?(dev\.|test\.|qc\.)?(${domain_url_replace})" "://\$1${domain_url}" --regex | sed "s/^/\t\t/"
                            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "UPDATE ${software_dbprefix}options SET option_value='$(echo "${configuration}" | shyaml get-value company.email)' WHERE option_name = 'admin_email';"
                        fi
                    fi
                done
            fi
        fi
        # reset admin credentials every provision
        if [[ "${software}" = "drupal6" ]]; then
            echo -e "\t* resetting ${software} admin password..."
            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "INSERT INTO ${software_dbprefix}users (uid, pass, mail, status) VALUES ('1',MD5('$(echo "${configuration}" | shyaml get-value environments.${1}.software.drupal.admin_password)'),'$(echo "${configuration}" | shyaml get-value company.email)','1') ON DUPLICATE KEY UPDATE name='admin', mail='$(echo "${configuration}" | shyaml get-value company.email)', pass=MD5('$(echo "${configuration}" | shyaml get-value environments.${1}.software.drupal.admin_password)'), status='1';"
            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "INSERT INTO ${software_dbprefix}users_roles (uid, rid) VALUES ('1','3') ON DUPLICATE KEY UPDATE rid='3';"
        elif [[ "${software}" = "drupal7" ]]; then
            echo -e "\t* resetting ${software} admin password..."
            password_hash=$(cd "/var/www/repositories/apache/${domain}/${webroot}" && php ./scripts/password-hash.sh $(echo "${configuration}" | shyaml get-value environments.${1}.software.drupal.admin_password))
            password_hash=$(echo "${password_hash}" | awk '{ print $4 }' | tr -d " " | tr -d "\n")
            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "INSERT INTO ${software_dbprefix}users (uid, pass, mail, status) VALUES ('1','${password_hash}','$(echo "${configuration}" | shyaml get-value company.email)','1') ON DUPLICATE KEY UPDATE name='admin', mail='$(echo "${configuration}" | shyaml get-value company.email)', pass='${password_hash}', status='1';"
            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "INSERT INTO ${software_dbprefix}users_roles (uid, rid) VALUES ('1','3') ON DUPLICATE KEY UPDATE rid='3';"
        elif [[ "${software}" = "wordpress" ]]; then
            echo -e "\t* resetting ${software} admin password..."
            mysql --defaults-extra-file=$dbconf ${1}_${domainvaliddbname} -e "INSERT INTO ${software_dbprefix}users (id, user_login, user_pass, user_nicename, user_email, user_status, display_name) VALUES ('1', 'admin', MD5('$(echo "${configuration}" | shyaml get-value environments.${1}.software.wordpress.admin_password)'), 'admin', '$(echo "${configuration}" | shyaml get-value company.email)', '0', 'admin') ON DUPLICATE KEY UPDATE user_login='admin', user_pass=MD5('$(echo "${configuration}" | shyaml get-value environments.${1}.software.wordpress.admin_password)'), user_nicename='admin', user_email='$(echo "${configuration}" | shyaml get-value company.email)', user_status='0', display_name='admin';"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" user add-role 1 administrator
        fi  
    fi

done

# remove .cnf file after usage
rm -f /catapult/provisioners/redhat/installers/${1}.cnf
