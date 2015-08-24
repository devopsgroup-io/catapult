# clone/pull necessary repos
sudo mkdir -p ~/.ssh
sudo touch ~/.ssh/known_hosts
sudo ssh-keyscan bitbucket.org > ~/.ssh/known_hosts
sudo ssh-keyscan github.com >> ~/.ssh/known_hosts

while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    repo=$(echo "$key" | grep -w "repo" | cut -d ":" -f 2,3 | tr -d " ")

    echo -e "\nNOTICE: $domain"

    if [ -d "/var/www/repositories/apache/$domain/.git" ]; then
        if [ "$(cd /var/www/repositories/apache/$domain && git config --get remote.origin.url)" != "$repo" ]; then
            echo "the repo has changed in secrets/configuration.yml, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
        elif [ "$(cd /var/www/repositories/apache/$domain && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/$domain && git rev-list origin/master | tail -n 1 )" ]; then
            echo "the repo has changed, removing and cloning the new repository." | sed "s/^/\t/"
            sudo rm -rf /var/www/repositories/apache/$domain
            sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
        else
            cd /var/www/repositories/apache/$domain && git checkout $(echo "${configuration}" | shyaml get-value environments.$1.branch)
            cd /var/www/repositories/apache/$domain && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $(echo "${configuration}" | shyaml get-value environments.$1.branch)" | sed "s/^/\t/"
        fi
    else
        if [ -d "/var/www/repositories/apache/$domain" ]; then
            echo "the .git folder is missing, removing the directory and re-cloning the repository." | sed "s/^/\t/"
            sudo chmod 0777 -R /var/www/repositories/apache/$domain
            sudo rm -rf /var/www/repositories/apache/$domain
        fi
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(echo "${configuration}" | shyaml get-value environments.$1.branch) $repo /var/www/repositories/apache/$domain" | sed "s/^/\t/"
    fi

done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)

# create an array of domains
while IFS='' read -r -d '' key; do
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domains+=($domain)
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
# cleanup directories from domains array
for directory in /var/www/repositories/apache/*/; do
    domain=$(basename $directory)
    if ! [[ ${domains[*]} =~ $domain ]]; then
        echo "Cleaning up websites that no longer exist..."
        sudo chmod 0777 -R $directory
        sudo rm -rf $directory
    fi
done
