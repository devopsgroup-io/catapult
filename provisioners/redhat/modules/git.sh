# clone/pull repositories into /var/www/repositories/apache/
instance=$5
branch=$6
domain=$7
repo=$8

if [ -d "/var/www/repositories/apache/$domain/.git" ]; then
    if [ "$(cd /var/www/repositories/apache/$domain && git config --get remote.origin.url)" != "$repo" ]; then
        echo "the repo has changed in secrets/configuration.yml, removing and cloning the new repository."
        sudo rm -rf /var/www/repositories/apache/$domain
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $branch $repo /var/www/repositories/apache/$domain"
    elif [ "$(cd /var/www/repositories/apache/$domain && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/$domain && git rev-list origin/master | tail -n 1 )" ]; then
        echo "the repo has changed, removing and cloning the new repository."
        sudo rm -rf /var/www/repositories/apache/$domain
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $branch $repo /var/www/repositories/apache/$domain"
    else
        cd /var/www/repositories/apache/$domain \
            && git reset -q --hard HEAD -- \
            && git checkout . \
            && git clean -fd \
            && git checkout $branch \
            && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" \
            && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $branch"
    fi
else
    if [ -d "/var/www/repositories/apache/$domain" ]; then
        echo "the .git folder is missing, removing the directory and re-cloning the repository."
        sudo chmod 0777 -R /var/www/repositories/apache/$domain
        sudo rm -rf /var/www/repositories/apache/$domain
    fi
    sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b $branch $repo /var/www/repositories/apache/$domain"
fi

touch "/catapult/provisioners/redhat/logs/${instance}.${domain}.complete"
