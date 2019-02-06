source "/catapult/provisioners/redhat/modules/catapult.sh"

branch=$(catapult environments.$1.branch)

domain=$(catapult websites.apache.$5.domain)
repo=$(catapult websites.apache.$5.repo)
software=$(catapult websites.apache.$5.software)
software_workflow=$(catapult websites.apache.$5.software_workflow)
webroot=$(catapult websites.apache.$5.webroot)

database_config_file=$(provisioners software.apache.${software}.database_config_file)
softwareroot=$(provisioners software.apache.${software}.softwareroot)

# clone/pull repositories into /var/www/repositories/apache/
if [ -d "/var/www/repositories/apache/${domain}/.git" ]; then
    if [ "$(cd /var/www/repositories/apache/${domain} && git config --get remote.origin.url)" != "${repo}" ]; then
        echo "the repo has changed in secrets/configuration.yml, removing and cloning the new repository..."
        sudo rm --force --recursive "/var/www/repositories/apache/${domain}"
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b ${branch} ${repo} /var/www/repositories/apache/${domain}"
    elif [ "$(cd /var/www/repositories/apache/${domain} && find .git/objects -type f | wc -l )" == "0" ]; then
        echo "the repo appears to be empty, removing and re-cloning the repository..."
        sudo rm --force --recursive "/var/www/repositories/apache/${domain}"
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b ${branch} ${repo} /var/www/repositories/apache/${domain}"
    elif [ "$(cd /var/www/repositories/apache/${domain} && git rev-list HEAD | tail -n 1 )" != "$(cd /var/www/repositories/apache/${domain} && git rev-list origin/master | tail -n 1 )" ]; then
        echo "the repo has changed, removing and cloning the new repository..."
        sudo rm --force --recursive "/var/www/repositories/apache/${domain}"
        sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b ${branch} ${repo} /var/www/repositories/apache/${domain}"
    else
        directory_size=$(du --exclude=.git --summarize "/var/www/repositories/apache/${domain}" | awk '{ print $1 }')
        directory_size_git=$(du --summarize "/var/www/repositories/apache/${domain}/.git" | awk '{ print $1 }')
        directory_size_maximum=$(( 1024 * 750 ))
        echo -e "website directory: /var/www/repositories/apache/${domain}"
        echo -e "website directory size: $(( (${directory_size} + ${directory_size_git}) / 1024 ))MB"
        echo -e "website directory size (excluding .git): $(( ${directory_size} / 1024 ))MB"
        echo -e "website directory .git size: $(( ${directory_size_git} / 1024 ))MB"
        # set git config options, note order of config files https://git-scm.com/docs/git-config#FILES
        cd "/var/www/repositories/apache/${domain}" \
            && git config --global user.name "Catapult" \
            && git config --global user.email "$(catapult company.email)" \
            && git config core.autocrlf false \
            && git config core.fileMode false \
            && git config core.packedGitLimit 128m \
            && git config core.packedGitWindowSize 128m \
            && git config merge.renameLimit 999999 \
            && git config pack.deltaCacheSize 128m \
            && git config pack.packSizeLimit 128m \
            && git config pack.threads 1 \
            && git config pack.windowMemory 128m
        # get the current branch
        branch_this=$(cd "/var/www/repositories/apache/${domain}" && git rev-parse --abbrev-ref HEAD)
        # git commit file stores if in the correct branch, environment, and software_workflow
        if ([ "${branch}" = "${branch_this}" ] && [ "${1}" = "production" ] && [ "${software_workflow}" = "downstream" ]) || ([ "${branch}" = "${branch_this}" ] && [ "${1}" = "test" ] && [ "${software_workflow}" = "upstream" ]); then
            # create a .gitignore file if none exists
            touch "/var/www/repositories/apache/${domain}/.gitignore"
            # manage the database config file entry in the .gitignore file
            if ! grep -q "${webroot}${softwareroot}${database_config_file}" "/var/www/repositories/apache/${domain}/.gitignore"; then
               sudo bash -c "echo \"${webroot}${softwareroot}${database_config_file}\" >> \"/var/www/repositories/apache/${domain}/.gitignore\""
            fi
            # manage the php-fpm .user.ini file entry in the .gitignore file
            if ! grep -q "${webroot}${softwareroot}.user.ini" "/var/www/repositories/apache/${domain}/.gitignore"; then
               sudo bash -c "echo \"${webroot}${softwareroot}.user.ini\" >> \"/var/www/repositories/apache/${domain}/.gitignore\""
            fi
            # manage the _sql directory entry in the .gitignore file
            sed -i '/_sql/,$d' "/var/www/repositories/apache/${domain}/.gitignore"
            if ! grep -q "_sql/*.sql" "/var/www/repositories/apache/${domain}/.gitignore"; then
               sudo bash -c "echo \"_sql/*.sql\" >> \"/var/www/repositories/apache/${domain}/.gitignore\""
            fi
            # add everything in the repository to the git index (keep in mind untracked file stores)
            cd "/var/www/repositories/apache/${domain}" \
                && git add --all :/
            # if the database config file is tracked, remove it from the git index with rm --cached so the config file remains (would have to be accurate) - will get overwritten by software_config's generated one
            cd "/var/www/repositories/apache/${domain}" \
                && git rm --cached "/var/www/repositories/apache/${domain}/${webroot}${softwareroot}${database_config_file}"
            # loop through each file store as a way to reduce repository size and avoid limits
            if [ ! -z "$(provisioners_array software.apache.${software}.file_stores)" ]; then
                for file_store in $(provisioners_array software.apache.${software}.file_stores); do
                    file_store="/var/www/repositories/apache/${domain}/${webroot}${file_store}"
                    # confirm the file store exists
                    if [ -d "${file_store}" ]; then
                        # get the file store size
                        file_store_size=$(du --summarize "${file_store}" | awk '{ print $1 }')
                        echo -e "website file store ${file_store} size: $(( ${file_store_size} / 1024 ))MB"
                        # determine whether the file store is untracked or tracked
                        cd "/var/www/repositories/apache/${domain}" \
                            && git check-ignore --quiet "${file_store}"
                        if [ $? -eq 0 ]; then
                            echo -e "- this website file store is untracked"
                            echo -e "- this website file store will be rsynced"
                            echo -e "- rely on virtual machine backups for disaster recovery"
                        else
                            # determine if the file store is too large
                            if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                                echo -e "- this website file store is tracked but over the limit to commit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                                echo -e "- this website file store will be rsynced"
                                echo -e "- rely on virtual machine backups for disaster recovery"
                                cd "/var/www/repositories/apache/${domain}" \
                                    && git reset --mixed "${file_store}"
                            else
                                echo -e "- this website file store is tracked and within the limit to commit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                                echo -e "- this website file store will be committed"
                            fi
                        fi
                    fi
                done
            fi
            # now that we have everything in our index that we want, commit, pull, then push
            cd "/var/www/repositories/apache/${domain}" \
                && git commit --message="Catapult auto-commit ${1}:${software_workflow}:software_files"
            cd "/var/www/repositories/apache/${domain}" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch"
            # if there are changes between us and remote, write a changes file for later use
            cd "/var/www/repositories/apache/${domain}" \
                && sudo git diff --exit-code --quiet ${branch} origin/${branch}
            if [ $? -eq 1 ]; then
                touch "/catapult/provisioners/redhat/logs/domain.${domain}.changes"
            fi
            # after we have a diff, continute to pull
            cd "/var/www/repositories/apache/${domain}" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin ${branch} && git submodule update --init --recursive && git push origin ${branch}"
        # git reset files and branch if outside of branch and software_workflow
        else
            # stash any pending work in localdev as a courtesy (branch may vary)
            if [ "${1}" = "dev" ]; then
                cd "/var/www/repositories/apache/${domain}" \
                    && git stash save --include-untracked
            fi
            # hard reset (tracked), checkout all from HEAD, clean (untracked - we'll rsync later), checkout correct branch, then pull in latest
            cd "/var/www/repositories/apache/${domain}" \
                && git reset --quiet --hard HEAD -- \
                && git checkout . \
                && git clean -d --force --force \
                && git checkout ${branch} \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch"
            # if there are changes between us and remote, write a changes file for later use
            cd "/var/www/repositories/apache/${domain}" \
                && sudo git diff --exit-code --quiet ${branch} origin/${branch}
            if [ $? -eq 1 ]; then
                touch "/catapult/provisioners/redhat/logs/domain.${domain}.changes"
            fi
            # after we have a diff, continue to pull
            cd "/var/www/repositories/apache/${domain}" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin ${branch} && git submodule update --init --recursive"
        fi
        # if we're on develop, pull master into develop to keep it up to date
        # this accomodates software_workflow = downstream and software_workflow = upstream (when dbtable_retain commits)
        if ([ "${branch_this}" = "develop" ]); then
            cd "/var/www/repositories/apache/${domain}" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch && git pull origin master && git submodule update --init --recursive && git push origin ${branch}"
        fi
        # last but not least, run git gc to cleanup unnecessary files and optimize the local repository
        # using the --auto flag will prevent gc from running every time, which on larger repositories can take a while
        cd "/var/www/repositories/apache/${domain}" \
            && git gc --auto
    fi
else
    if [ -d "/var/www/repositories/apache/${domain}" ]; then
        echo "the .git folder is missing, removing the directory and re-cloning the repository."
        sudo chmod 0777 -R "/var/www/repositories/apache/${domain}"
        sudo rm --force --recursive "/var/www/repositories/apache/${domain}"
    fi
    sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git clone --recursive -b ${branch} ${repo} /var/www/repositories/apache/${domain}"
    touch "/catapult/provisioners/redhat/logs/domain.${domain}.changes"
fi

touch "/catapult/provisioners/redhat/logs/git.${domain}.complete"
