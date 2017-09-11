source "/catapult/provisioners/redhat/modules/catapult.sh"

# remove directories from /var/www/repositories/apache/ that no longer exist in configuration
# create an array of domains
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domains+=($domain)
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup directories from domains array
for directory in /var/www/repositories/apache/*/; do
    # on a new provision, there will be no directories and an empty for loop returns itself
    if [ -e "${directory}" ]; then
        folder=$(basename "${directory}")
        if ! ([[ ${domains[*]} =~ "${folder}" ]] || [ "_default_" == "${folder}" ]); then
            echo "Removing the ${directory} directory as it does not exist in your configuration..."
            sudo chown -R root:root * "${directory}"
            sudo chmod 0777 -R "${directory}"
            sudo rm -rf "${directory}"
        fi
    fi
done
