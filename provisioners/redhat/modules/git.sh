source "/catapult/provisioners/redhat/modules/catapult.sh"

# remove directories from /var/www/repositories/apache/ that no longer exist in configuration
# create an array of domains
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domains+=($domain)
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup directories from domains array
for directory in /var/www/repositories/apache/*/; do
    # on a new provision, there will be no directories
    if [ -e "$directory" ]; then
        domain=$(basename $directory)
        if ! [[ ${domains[*]} =~ $domain ]]; then
            echo "Cleaning up the ${domain} repo because it has been removed from your configuration..."
            sudo chmod 0777 -R $directory
            sudo rm -rf $directory
        fi
    fi
done

# clone/pull repositories into /var/www/repositories/apache/
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    repo=$(echo "$key" | grep -w "repo" | cut -d ":" -f 2,3 | tr -d " ")

    echo -e "\nNOTICE: $domain"

    if [ -d "/var/www/repositories/apache/$domain/.git" ]; then
        if [ "$(cd /var/www/repositories/apache/$domain && git config --get remote.origin.url)" != "$repo" ]; then
            echo "the repo has changed in secrets/configuration.yml, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" 2>&1 | sed "s/^/\t/"
        elif [ "$(cd /var/www/repositories/apache/$domain && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/$domain && git rev-list origin/master | tail -n 1 )" ]; then
            echo "the repo has changed, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" 2>&1 | sed "s/^/\t/"
        else
            cd /var/www/repositories/apache/$domain && git reset -q --hard HEAD -- 2>&1 | sed "s/^/\t/"
            cd /var/www/repositories/apache/$domain && git checkout . 2>&1 | sed "s/^/\t/"
            cd /var/www/repositories/apache/$domain && git clean -fd 2>&1 | sed "s/^/\t/"
            cd /var/www/repositories/apache/$domain && git checkout $(echo "${configuration}" | shyaml get-value environments.$1.branch) 2>&1 | sed "s/^/\t/"
            cd /var/www/repositories/apache/$domain && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" 2>&1 | sed "s/^/\t/"
            cd /var/www/repositories/apache/$domain && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $(echo "${configuration}" | shyaml get-value environments.$1.branch)" 2>&1 | sed "s/^/\t/"
        fi
    else
        if [ -d "/var/www/repositories/apache/$domain" ]; then
            echo "the .git folder is missing, removing the directory and re-cloning the repository." | sed "s/^/\t/"
            sudo chmod 0777 -R /var/www/repositories/apache/$domain
            sudo rm -rf /var/www/repositories/apache/$domain
        fi
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" 2>&1 | sed "s/^/\t/"
    fi

done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
