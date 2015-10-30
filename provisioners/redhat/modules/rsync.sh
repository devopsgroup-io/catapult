source "/catapult/provisioners/redhat/modules/catapult.sh"

software=$(catapult "websites.apache.$5.software")

if ([ -z "${software}" ] || [ "${software}" = "codeigniter2" ] || [ "${software}" = "codeigniter3" ] || [ "${software}" = "silverstripe" ] || [ "${software}" = "xenforo" ]); then

    echo -e "no rsync needed, skipping..."

else

    if [ "${1}" == "dev" ]; then
        test_redhat_ip=$(catapult "environments.test.servers.redhat.ip")
        production_redhat_ip=$(catapult "environments.production.servers.redhat.ip")
    else
        test_redhat_ip=$(catapult "environments.test.servers.redhat.ip_private")
        production_redhat_ip=$(catapult "environments.production.servers.redhat.ip_private")
    fi

    domain=$(catapult "websites.apache.$5.domain")
    software_workflow=$(catapult "websites.apache.$5.software_workflow")
    webroot=$(catapult "websites.apache.$5.webroot")

    if [ "${software}" = "drupal6" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from production..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/"
        else
            echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    elif [ "${software}" = "drupal7" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from production..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ from test..."
            sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}sites/default/files/" "/var/www/repositories/apache/${domain}/${webroot}sites/default/files/"
        else
            echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    elif [ "${software}" = "wordpress" ]; then
        if ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from production..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/"
        elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
            echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/ from test..."
            sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/" "/var/www/repositories/apache/${domain}/${webroot}wp-content/uploads/"
        else
            echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
        fi
    fi

fi

touch "/catapult/provisioners/redhat/logs/rsync.$(catapult "websites.apache.$5.domain").complete"
