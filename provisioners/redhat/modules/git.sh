source "/catapult/provisioners/redhat/modules/catapult.sh"

# clone/pull repositories into /var/www/repositories/apache/
if [ -d "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/.git" ]; then
    if [ "$(cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) && git config --get remote.origin.url)" != "$(catapult websites.apache.$5.repo)" ]; then
        echo "the repo has changed in secrets/configuration.yml, removing and cloning the new repository..."
        sudo rm -rf /var/www/repositories/apache/$(catapult websites.apache.$5.domain)
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(catapult environments.$1.branch) $(catapult websites.apache.$5.repo) /var/www/repositories/apache/$(catapult websites.apache.$5.domain)"
    elif [ "$(cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) && ls -afq .git/refs/heads | wc -l )" == "2" ]; then
        echo "the repo appears to be empty, removing and re-cloning the repository..."
        sudo rm -rf /var/www/repositories/apache/$(catapult websites.apache.$5.domain)
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(catapult environments.$1.branch) $(catapult websites.apache.$5.repo) /var/www/repositories/apache/$(catapult websites.apache.$5.domain)"
    elif [ "$(cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) && git rev-list origin/master | tail -n 1 )" ]; then
        echo "the repo has changed, removing and cloning the new repository..."
        sudo rm -rf /var/www/repositories/apache/$(catapult websites.apache.$5.domain)
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(catapult environments.$1.branch) $(catapult websites.apache.$5.repo) /var/www/repositories/apache/$(catapult websites.apache.$5.domain)"
    else
        # stash any pending work in localdev as a courtesy
        if [ $1 = "dev" ]; then
            cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
                && git config --global user.name "Catapult" \
                && git config --global user.email "$(catapult company.email)" \
                && git stash save
        fi
        cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
            && git reset -q --hard HEAD -- \
            && git checkout . \
            && git clean -fd \
            && git checkout $(catapult environments.$1.branch) \
            && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" \
            && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $(catapult environments.$1.branch)"
    fi
else
    if [ -d "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" ]; then
        echo "the .git folder is missing, removing the directory and re-cloning the repository."
        sudo chmod 0777 -R /var/www/repositories/apache/$(catapult websites.apache.$5.domain)
        sudo rm -rf /var/www/repositories/apache/$(catapult websites.apache.$5.domain)
    fi
    sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $(catapult environments.$1.branch) $(catapult websites.apache.$5.repo) /var/www/repositories/apache/$(catapult websites.apache.$5.domain)"
fi

touch "/catapult/provisioners/redhat/logs/git.$(catapult websites.apache.$5.domain).complete"
