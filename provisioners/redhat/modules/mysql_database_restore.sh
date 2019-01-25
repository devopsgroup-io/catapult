source "/catapult/provisioners/redhat/modules/catapult.sh"

# set a variable to the .cnf
dbconf="/catapult/provisioners/redhat/installers/temp/${1}.cnf"

domain=$(catapult websites.apache.$5.domain)
domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
domain_valid_db_name=$(catapult websites.apache.$5.domain | tr "." "_" | tr "-" "_")
software=$(catapult websites.apache.$5.software)
software_dbprefix=$(catapult websites.apache.$5.software_dbprefix)
software_workflow=$(catapult websites.apache.$5.software_workflow)
software_db=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${1}_${domain_valid_db_name}'")
software_db_tables=$(mysql --defaults-extra-file=$dbconf --silent --skip-column-names --execute "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${1}_${domain_valid_db_name}'")
softwareroot=$(provisioners software.apache.${software}.softwareroot)
webroot=$(catapult websites.apache.$5.webroot)


# respect software_workflow and restore the database if appropriate
if ([ ! -z "${software}" ]); then

    if ([ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]) || ([ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]); then
        : #no-op
    else
        if [ -z "${software_db}" ]; then
            echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, however, the database does not exist. performing a database restore..."
        elif [ -z "${software_db_tables}" ]; then
            echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, however, the database exists but contains no tables. performing a database restore..."
        else
            echo -e "\t* workflow is set to ${software_workflow} and this is the ${1} environment, performing a database restore..."
        fi
        # confirm we have a usable database backup
        if ! [ -d "/var/www/repositories/apache/${domain}/_sql" ]; then
            echo -e "\t* ~/_sql directory does not exist, ${software} may not function properly"
        else
            echo -e "\t* ~/_sql directory exists, looking for a valid database dump to restore from"
            filenewest_lock=$(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}\.sql\.lock$ | sort --numeric-sort | tail -1)
            filenewest=${filenewest_lock::-5}

            if ([ -f "/var/www/repositories/apache/${domain}/_sql/${filenewest}" ] && [ -f "/var/www/repositories/apache/${domain}/_sql/${filenewest_lock}" ]); then
                # drop the database
                for database in $(mysql --defaults-extra-file=$dbconf -e "show databases" | egrep -v "Database|mysql|information_schema|performance_schema"); do
                    if [ ${database} = ${1}_${domain_valid_db_name} ]; then
                        mysql --defaults-extra-file=$dbconf -e "DROP DATABASE ${1}_${domain_valid_db_name}";
                    fi
                done
                # create database
                mysql --defaults-extra-file=$dbconf -e "CREATE DATABASE ${1}_${domain_valid_db_name}"
                # restore database
                echo -e "\t- found ${filenewest_lock}"
                echo -e "\t- found ${filenewest}"
                echo -e "\t- restoring..."
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

                # pre-process database sql file
                # for software without a cli tool for database url reference replacements, use sed to pre-process sql file and replace url references
                if ([ "${software}" = "codeigniter2" ] \
                 || [ "${software}" = "codeigniter3" ] \
                 || [ "${software}" = "concrete58" ] \
                 || [ "${software}" = "drupal6" ] \
                 || [ "${software}" = "drupal7" ] \
                 || [ "${software}" = "drupal8" ] \
                 || [ "${software}" = "elgg1" ] \
                 || [ "${software}" = "elgg2" ] \
                 || [ "${software}" = "expressionengine3" ] \
                 || [ "${software}" = "joomla3" ] \
                 || [ "${software}" = "laravel5" ] \
                 || [ "${software}" = "mediawiki1" ] \
                 || [ "${software}" = "moodle3" ] \
                 || [ "${software}" = "silverstripe3" ] \
                 || [ "${software}" = "suitecrm7" ] \
                 || [ "${software}" = "xenforo1" ] \
                 || [ "${software}" = "xenforo2" ] \
                 || [ "${software}" = "zendframework2" ]); then
                    echo -e "\t- replacing URLs in the database to align with the enivronment..."
                    replacements=$(grep --extended-regexp --only-matching --regexp=":\/\/(www\.)?(dev\.|test\.|qc\.)?(${domain_url_replace})" "/var/www/repositories/apache/${domain}/_sql/${filenewest}" | wc --lines)
                    sed --regexp-extended --expression="s/:\/\/(www\.)?(dev\.|test\.|qc\.)?(${domain_url_replace})/:\/\/\1${domain_url}/g" "/var/www/repositories/apache/${domain}/_sql/${filenewest}" > "/var/www/repositories/apache/${domain}/_sql/${1}.${filenewest}"
                    echo -e "\t- found and replaced ${replacements} occurrences"
                else
                    cp "/var/www/repositories/apache/${domain}/_sql/${filenewest}" "/var/www/repositories/apache/${domain}/_sql/${1}.${filenewest}"
                fi

                # restore the full database sql file
                mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} < "/var/www/repositories/apache/${domain}/_sql/${1}.${filenewest}"
                rm --force "/var/www/repositories/apache/${domain}/_sql/${1}.${filenewest}"

                # post-process the database
                # necessary for PHP serialized arrays
                # for software with a cli tool for database url reference replacements, use cli tool to post-process database and replace url references
                if ([ "${software}" = "wordpress4" ] \
                 || [ "${software}" = "wordpress5" ]); then
                    echo -e "\t- replacing URLs in the database to align with the enivronment..."
                    wp-cli --allow-root --path="/var/www/repositories/apache/${domain}/${webroot}" search-replace ":\/\/(www\.)?(dev\.|test\.|qc\.)?(${domain_url_replace})" "://\$1${domain_url}" --regex | sed "s/^/\t\t/"
                fi
            fi
        fi
    fi

    # restore the software_dbtable_retain database sql file
    # we do not respect the software_workflow in the scenario and restore the _software_dbtable_retain in any environment if a _software_dbtable_retain db sql file exists
    # we look for the newest possible _software_dbtable_retain database sql file and restore
    if ([ ! -z "${software}" ] && [ "${software_workflow}" = "upstream" ] && [ "${software_db}" != "" ] && [ "${software_db_tables}" != "0" ]); then
        filenewest_lock=$(ls "/var/www/repositories/apache/${domain}/_sql" | grep -E ^[0-9]{8}_software_dbtable_retain\.sql\.lock$ | sort --numeric-sort | tail -1)
        filenewest=${filenewest_lock::-5}
        if ([ -f "/var/www/repositories/apache/${domain}/_sql/${filenewest}" ] && [ -f "/var/www/repositories/apache/${domain}/_sql/${filenewest_lock}" ]); then
            echo -e "\t- found ${filenewest_lock}"
            echo -e "\t- found ${filenewest}"
            echo -e "\t- restoring..."
            mysql --defaults-extra-file=$dbconf ${1}_${domain_valid_db_name} < "/var/www/repositories/apache/${domain}/_sql/${filenewest}"
        fi
    fi

fi

touch "/catapult/provisioners/redhat/logs/mysql_database_restore.$(catapult websites.apache.$5.domain).complete"
