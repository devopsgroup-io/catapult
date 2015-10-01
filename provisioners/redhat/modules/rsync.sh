source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "${1}" == "dev" ]; then
    test_redhat_ip="$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip)"
    production_redhat_ip="$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip)"
else
    test_redhat_ip="$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip_private)"
    production_redhat_ip="$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip_private)"
fi

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
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" 2>&1 | sed "s/^/\t\t/"
        else
            echo -e "\t * software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    elif [ "${software}" = "drupal7" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from production..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" 2>&1 | sed "s/^/\t\t/"
        else
            echo -e "\t * software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    elif [ "${software}" = "wordpress" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from production..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" 2>&1 | sed "s/^/\t\t/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "\t * rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from test..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" 2>&1 | sed "s/^/\t\t/"
        else
            echo -e "\t * software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    fi

done
