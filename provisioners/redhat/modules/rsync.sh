source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "${1}" == "dev" ]; then
    test_redhat_ip=$(catapult "environments.test.servers.redhat.ip")
    production_redhat_ip=$(catapult "environments.production.servers.redhat.ip")
else
    test_redhat_ip=$(catapult "environments.test.servers.redhat.ip_private")
    production_redhat_ip=$(catapult "environments.production.servers.redhat.ip_private")
fi

domain=$(catapult "websites.apache.$5.domain")
software=$(catapult "websites.apache.$5.software")
software_workflow=$(catapult "websites.apache.$5.software_workflow")
webroot=$(catapult "websites.apache.$5.webroot")

if [ "${software}" = "codeigniter2" ]; then

    folder="uploads/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

elif [ "${software}" = "codeigniter3" ]; then

    folder="uploads/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

elif [ "${software}" = "drupal6" ]; then

    folder="sites/default/files/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

elif [ "${software}" = "drupal7" ]; then

    folder="sites/default/files/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive --exclude="css/" --exclude="js/" -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

elif [ "${software}" = "wordpress" ]; then

    folder="wp-content/uploads/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

elif [ "${software}" = "xenforo" ]; then

    folder="data/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

    folder="internal_data/"
    cd "/var/www/repositories/apache/${domain}/${webroot}" && git check-ignore --quiet "${folder}"
    if [ $? -ne 0 ]; then
        echo -e "/var/www/repositories/apache/${domain}/${webroot}${folder} seems to be tracked - no rsync needed, skipping..."
    elif ([ "${software_workflow}" = "downstream" ] && [ "$1" != "production" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from production..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${production_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    elif ([ "${software_workflow}" = "upstream" ] && [ "$1" != "test" ]); then
        echo -e "rysncing /var/www/repositories/apache/${domain}/${webroot}${folder} from test..."
        sudo rsync --compress --delete --recursive -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" "root@${test_redhat_ip}:/var/www/repositories/apache/${domain}/${webroot}${folder}" "/var/www/repositories/apache/${domain}/${webroot}${folder}"
    else
        echo -e "software_workflow is set to ${software_workflow} and this is ${1} - no rsync needed, skipping..."
    fi

fi

touch "/catapult/provisioners/redhat/logs/rsync.$(catapult "websites.apache.$5.domain").complete"
