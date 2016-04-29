source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "${1}" == "dev" ]; then
    test_redhat_ip=$(catapult environments.test.servers.redhat.ip)
    production_redhat_ip=$(catapult environments.production.servers.redhat.ip)
else
    test_redhat_ip=$(catapult environments.test.servers.redhat.ip_private)
    production_redhat_ip=$(catapult environments.production.servers.redhat.ip_private)
fi

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

if [ -z $(provisioners_array software.apache.${software}.file_stores) ]; then

    echo "this software has no file stores"
    
else

    # define a maximum directory size
    directory_size_maximum=$(( 1024 * 750 ))

    # loop through each required module
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_stores |
    while read -r -d $'\0' file_store; do

        file_store="/var/www/repositories/apache/${domain}/${webroot}${file_store}/"
        echo -e "software file store: ${file_store}"

        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
                
            file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa root@${production_redhat_ip} "du --summarize ${file_store} 2>&1")
            file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

            if echo $file_store_size | grep --extended-regexp --quiet --regexp="du"; then
                echo -e "- production:downstream file store does not exist"
            else
                echo -e "- production:downstream file store size: $(( ${file_store_size} / 1024 ))MB"
                cd "/var/www/repositories/apache/${domain}" && git check-ignore --quiet "${file_store}"
                if [ $? -ne 0 ]; then
                    echo -e "- this file store is tracked in git"
                    if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                        echo -e "- test:production file store is over the tracked limit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                        echo -e "- rsyncing..."
                        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:${file_store}" "${file_store}"
                    fi
                else
                    echo -e "- this file store is untracked in git"
                    echo -e "- rsyncing..."
                    sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:${file_store}" "${file_store}"
                fi
            fi
        
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            
            file_store_size=$(ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa root@${test_redhat_ip} "du --summarize ${file_store} 2>&1")
            file_store_size=$(echo -e "${file_store_size}" | awk '{ print $1 }')

            if echo $file_store_size | grep --extended-regexp --quiet --regexp="du"; then
                echo -e "- test:upstream file store does not exist"
            else
                echo -e "- test:upstream file store size: $(( ${file_store_size} / 1024 ))MB"
                cd "/var/www/repositories/apache/${domain}" && git check-ignore --quiet "${file_store}"
                if [ $? -ne 0 ]; then
                    echo -e "- this file store is tracked in git"
                    if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                        echo -e "- test:upstream file store is over the tracked limit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                        echo -e "- rsyncing..."
                        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:${file_store}" "${file_store}"
                    fi
                else
                    echo -e "- this file store is untracked in git"
                    echo -e "- rsyncing..."
                    sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:${file_store}" "${file_store}"
                fi
            fi

        else

            echo -e "- this file store will be used as the source as software_workflow is set to ${software_workflow} and this is ${1}"

        fi

    done
fi

touch "/catapult/provisioners/redhat/logs/rsync.$(catapult websites.apache.$5.domain).complete"
