source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
software=$(catapult websites.apache.$5.software)
software_auto_update=$(catapult websites.apache.$5.software_auto_update)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

softwareroot=$(provisioners software.apache.${software}.softwareroot)

# reference: https://www.drupal.org/node/244924#script-based-on-guidelines-given-above

# set ownership of repository [directory]
if [ "$1" != "dev" ]; then
    chown root:root "/var/www/repositories/apache/${domain}"
fi

# set ownership of software [directories and files]
if [ "$1" != "dev" ]; then
    cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" \
        && chown -R root:apache .
fi

# set permissions of software [directories and files]
cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}" \
    && find . -type d -exec chmod u=rwx,g=rx,o= '{}' \; \
    && find . -type f -exec chmod u=rw,g=r,o= '{}' \;

# set permissions of software file store containers
if [ ! -z "$(provisioners_array software.apache.${software}.file_store_containers)" ]; then
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_store_containers | while read -r -d $'\0' file_store_container; do

        # create the software file store container if it does not exist
        if [ ! -d "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store_container}" ]; then
            echo -e "- file store container does not exist, creating..."
            sudo mkdir --parents "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store_container}"
        fi

        # set permissions of file store container [directory]
        chmod ug=rwx,o= "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store_container}"

        # set permissions of contents of file store container [directories and files]
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store_container}" \
            && find . -type d -exec chmod ug=rwx,o= '{}' \; \
            && find . -type f -exec chmod ug=rw,o= '{}' \;

    done
fi

# set permissions of software file stores
if [ ! -z "$(provisioners_array software.apache.${software}.file_stores)" ]; then
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 software.apache.$(catapult websites.apache.$5.software).file_stores | while read -r -d $'\0' file_store; do

        # create the software file store if it does not exist
        if [ ! -d "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store}" ]; then
            echo -e "- file store container does not exist, creating..."
            sudo mkdir --parents "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store}"
        fi

        # set permissions of file store [directory]
        chmod ug=rwx,o= "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store}"

        # set permissions of contents of file store [directories and files]
        cd "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${file_store}" \
            && find . -type d -exec chmod ug=rwx,o= '{}' \; \
            && find . -type f -exec chmod ug=rw,o= '{}' \;

    done
fi

touch "/catapult/provisioners/redhat/logs/git_permissions.$(catapult websites.apache.$5.domain).complete"
