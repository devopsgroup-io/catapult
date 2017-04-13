source "/catapult/provisioners/redhat/modules/catapult.sh"

# set a variable to the .cnf
dbconf="/catapult/provisioners/redhat/installers/temp/${1}.cnf"

domain=$(catapult websites.apache.$5.domain)
domainvaliddbname=$(catapult websites.apache.$5.domain | tr "." "_" | tr "-" "_")
software=$(catapult websites.apache.$5.software)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
software_workflow=$(catapult websites.apache.$5.software_workflow)
software_db=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${1}_${domainvaliddbname}'")
software_db_tables=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${1}_${domainvaliddbname}'")

# @todo create workflow so that a developer can commit a dump from active work in localdev then the process detect this and kick off the restore rather than dump workflow


# respect software_workflow
if ([ ! -z "${software}" ]); then

    if ([ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]) || ([ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]); then
        # dump the database as long as it hasn't already been dumped for the day
        if ! [ -f /var/www/repositories/apache/${domain}/_sql/$(date +"%Y%m%d").sql ]; then
            echo -e "\t* performing a database backup"
            # create the _sql directory if it does not exist
            mkdir --parents "/var/www/repositories/apache/${domain}/_sql"
            # dump the database
            mysqldump --defaults-extra-file=$dbconf --single-transaction --quick ${1}_${domainvaliddbname} > /var/www/repositories/apache/${domain}/_sql/$(date +"%Y%m%d").sql
            # ensure no more than 250mb or at least the one, newest, YYYYMMDD.sql file exists
            sql_files_size_maximum=$(( 1024 * 250 ))
            sql_files_size_total=0
            file_newest=$(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql$ | sort --numeric-sort | tail -1)
            # add up each file from newest to oldest and remove files that push the total past the maximum _sql directory size
            for file in $(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql$ | sort --numeric-sort --reverse); do
                file_size=$(du --null "/var/www/repositories/apache/${domain}/_sql/${file}" | awk '{ print $1 }')
                sql_files_size_total=$(( ${sql_files_size_total} + ${file_size} ))
                if [ "${sql_files_size_total}" -gt "${sql_files_size_maximum}" ]; then
                    # keep at least the newest file, in case the database sql file is greater than the maximum _sql directory size
                    if [[ "$(basename "$file")" != "${file_newest}" ]]; then
                        echo -e "\t\t removing the old /var/www/repositories/apache/${domain}/_sql/${file}..."
                        sudo rm --force "/var/www/repositories/apache/${domain}/_sql/${file}"
                    fi
                fi
            done
            # git add and commit the _sql folder changes
            cd "/var/www/repositories/apache/${domain}" && git add --all "/var/www/repositories/apache/${domain}/_sql" 2>&1
            cd "/var/www/repositories/apache/${domain}" && git commit --message="Catapult auto-commit ${1}:${software_workflow}:software_database" 2>&1
            cd "/var/www/repositories/apache/${domain}" && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git push origin $(catapult environments.$1.branch)" 2>&1
        else
            echo -e "\t* a database backup was already performed today"
        fi
    fi

fi

touch "/catapult/provisioners/redhat/logs/mysql_database_backup.$(catapult websites.apache.$5.domain).complete"
