source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "${1}" == "dev" ]; then
    test_redhat_ip=$(catapult environments.test.servers.redhat.ip)
    production_redhat_ip=$(catapult environments.production.servers.redhat.ip)
    test_redhat_mysql_ip=$(catapult environments.test.servers.redhat_mysql.ip)
    production_redhat_mysql_ip=$(catapult environments.production.servers.redhat_mysql.ip)
else
    test_redhat_ip=$(catapult environments.test.servers.redhat.ip_private)
    production_redhat_ip=$(catapult environments.production.servers.redhat.ip_private)
    test_redhat_mysql_ip=$(catapult environments.test.servers.redhat_mysql.ip_private)
    production_redhat_mysql_ip=$(catapult environments.production.servers.redhat_mysql.ip_private)
fi

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_workflow=$(catapult websites.apache.$5.software_workflow)
softwareroot=$(provisioners software.apache.${software}.softwareroot)
webroot=$(catapult websites.apache.$5.webroot)

if [ -z "$(provisioners_array software.apache.${software}.file_stores)" ]; then

    echo "this software has no file stores"
    
else

    # define a maximum directory size
    directory_size_maximum=$(( 1024 * 750 ))

    # create temp file to define rsync exclusions
    tmpfile_rsync_exclusions=$(mktemp /tmp/catapult.rsync.$domain.XXXXXXXXXX)

    if [ "$(provisioners_array software.apache.${software}.file_stores_rsync_exclude)" ]; then
        cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_stores_rsync_exclude |
        while read -r -d $'\0' file_stores_rsync_exclude; do
            echo -e "exclude from file store sync: ${file_stores_rsync_exclude}"
            echo "${file_stores_rsync_exclude}" >> "$tmpfile_rsync_exclusions"
        done
    fi

    # loop through each software file store
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_stores |
    while read -r -d $'\0' file_store; do

        file_store="/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store}/"
        echo -e "software file store: ${file_store}"

        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
                
            file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -n -q root@${production_redhat_ip} "du --summarize ${file_store} 2>&1")
            file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

            if (echo $file_store_size | grep --extended-regexp --quiet --regexp="du"); then
                echo -e "- production:downstream file store does not exist"
            else
                echo -e "- production:downstream file store size: $(( ${file_store_size} / 1024 ))MB"
                cd "/var/www/repositories/apache/${domain}" && git check-ignore --quiet "${file_store}" &> /dev/null
                if [ $? -ne 0 ]; then
                    echo -e "- this file store is tracked in git"
                    if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                        echo -e "- production:downstream file store is over the tracked limit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                        echo -e "- rsyncing..."
                        sudo rsync --delete --recursive --exclude-from="$tmpfile_rsync_exclusions" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${production_redhat_ip}:${file_store}" "${file_store}"
                    fi
                else
                    echo -e "- this file store is untracked in git"
                    echo -e "- rsyncing..."
                    sudo rsync --delete --recursive --exclude-from="$tmpfile_rsync_exclusions" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${production_redhat_ip}:${file_store}" "${file_store}"
                fi
            fi
       
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            
            file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -n -q root@${test_redhat_ip} "du --summarize ${file_store} 2>&1")
            file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

            if (echo $file_store_size | grep --extended-regexp --quiet --regexp="du"); then
                echo -e "- test:upstream file store does not exist"
            else
                echo -e "- test:upstream file store size: $(( ${file_store_size} / 1024 ))MB"
                cd "/var/www/repositories/apache/${domain}" && git check-ignore --quiet "${file_store}" &> /dev/null
                if [ $? -ne 0 ]; then
                    echo -e "- this file store is tracked in git"
                    if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                        echo -e "- test:upstream file store is over the tracked limit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                        echo -e "- rsyncing..."
                        sudo rsync --delete --recursive --exclude-from="$tmpfile_rsync_exclusions" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${test_redhat_ip}:${file_store}" "${file_store}"
                    fi
                else
                    echo -e "- this file store is untracked in git"
                    echo -e "- rsyncing..."
                    sudo rsync --delete --recursive --exclude-from="$tmpfile_rsync_exclusions" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${test_redhat_ip}:${file_store}" "${file_store}"
                fi
            fi

        else

            echo -e "- this file store will be used as the source as software_workflow is set to ${software_workflow} and this is ${1}"

        fi

    done

    # clean up the rsync exclusions file
    rm "$tmpfile_rsync_exclusions"
fi

# rsync the always untracked _sql file store: YYYYMMDD.sql files
if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]) || ([ "${software_workflow}" = "downstream" ] && [ "$1" = "production" ] && [ "$4" = "apache" ]); then

    file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -n -q root@${production_redhat_mysql_ip} "du --summarize /var/www/repositories/apache/${domain}/_sql/ 2>&1")
    file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

    echo -e "sql file store: /var/www/repositories/apache/${domain}/_sql/"
    echo -e "- production:downstream file store size: $(( ${file_store_size} / 1024 ))MB"
    echo -e "- rsyncing YYYYMMDD.sql files..."
    # do a --size-only to help eleviate unnecessary copies of large files (with the risk of skipping byteless file changes to sql dumps)
    sudo rsync --delete --exclude '*.lock' --recursive --size-only -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${production_redhat_mysql_ip}:/var/www/repositories/apache/${domain}/_sql/" "/var/www/repositories/apache/${domain}/_sql/"

elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]) || ([ "${software_workflow}" = "upstream" ] && [ "$1" = "test" ] && [ "$4" = "apache" ]); then

    file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -n -q root@${test_redhat_mysql_ip} "du --summarize /var/www/repositories/apache/${domain}/_sql/ 2>&1")
    file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

    echo -e "sql file store: /var/www/repositories/apache/${domain}/_sql/"
    echo -e "- test:upstream file store size: $(( ${file_store_size} / 1024 ))MB"
    echo -e "- rsyncing YYYYMMDD.sql files..."
    # do a --size-only to help eleviate unnecessary copies of large files (with the risk of skipping byteless file changes to sql dumps)
    sudo rsync --delete --exclude '*.lock' --recursive --size-only -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${test_redhat_mysql_ip}:/var/www/repositories/apache/${domain}/_sql/" "/var/www/repositories/apache/${domain}/_sql/"

fi

# rsync the always untracked _sql file store: YYYYMMDD_software_dbtable_retain.sql files
if ([ "${software_workflow}" = "upstream" ] && [ "$1" != "production" ]); then

    echo -e "- rsyncing YYYYMMDD_software_dbtable_retain.sql files..."
    # do a --size-only to help eleviate unnecessary copies of large files (with the risk of skipping byteless file changes to sql dumps)
    sudo rsync --delete --include '*_software_dbtable_retain.sql' --exclude '*' --recursive --size-only -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa -q" "root@${production_redhat_mysql_ip}:/var/www/repositories/apache/${domain}/_sql/" "/var/www/repositories/apache/${domain}/_sql/"

fi

touch "/catapult/provisioners/redhat/logs/rsync.$(catapult websites.apache.$5.domain).complete"
