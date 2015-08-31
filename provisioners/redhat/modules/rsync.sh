echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    if ([ -z "${software}" ] || [ "${software}" = "codeigniter2" ] || [ "${software}" = "silverstripe" ] || [ "${software}" = "xenforo" ]); then
        echo -e "\t * no rsync needed, skipping..."
    elif [ "${software}" = "drupal6" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from production..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
        fi
    elif [ "${software}" = "drupal7" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from production..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
        fi
    elif [ "${software}" = "wordpress" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from production..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from test..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ 2>&1 | sed "s/^/\t\t/"
        fi
    else
        echo -e "\t * software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

done