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
        directory_size=$(du --exclude=.git --summarize "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" | awk '{ print $1 }')
        directory_size_git=$(du --summarize "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/.git" | awk '{ print $1 }')
        directory_size_maximum=$(( 1024 * 750 ))
        echo -e "website directory: /var/www/repositories/apache/$(catapult websites.apache.$5.domain)"
        echo -e "website directory size: $(( (${directory_size} + ${directory_size_git}) / 1024 ))MB"
        echo -e "website directory size (excluding .git): $(( ${directory_size} / 1024 ))MB"
        echo -e "website directory .git size: $(( ${directory_size_git} / 1024 ))MB"
        # set git config options, note order of config files https://git-scm.com/docs/git-config#FILES
        cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
            && git config --global user.name "Catapult" \
            && git config --global user.email "$(catapult company.email)" \
            && git config core.packedGitLimit 128m \
            && git config core.packedGitWindowSize 128m \
            && git config pack.deltaCacheSize 128m \
            && git config pack.packSizeLimit 128m \
            && git config pack.windowMemory 128m
        # get the current branch
        branch=$(cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" && git rev-parse --abbrev-ref HEAD)
        # git commit file stores if in the correct branch, environment, and software_workflow
        if ([ "$(catapult environments.$1.branch)" = "${branch}" ] && [ "${1}" = "production" ] && [ "$(catapult websites.apache.$5.software_workflow)" = "downstream" ]) || ([ "$(catapult environments.$1.branch)" = "${branch}" ] && [ "${1}" = "test" ] && [ "$(catapult websites.apache.$5.software_workflow)" = "upstream" ]); then
            # add everything in the webroot to the git index (keep in mind untracked file stores)
            cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/$(catapult websites.apache.$5.webroot)" \
                && git add --all
            # git reset the database config file to ensure we never track it or lose a database connection
            cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" \
                && git reset -- "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/$(catapult websites.apache.$5.webroot)$(provisioners software.apache.$(catapult websites.apache.$5.software).database_config_file)"
            # loop through each file store as a way to reduce repository size and avoid limits
            for file_store in $(provisioners_array software.apache.$(catapult websites.apache.$5.software).file_stores); do
                file_store="/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/$(catapult websites.apache.$5.webroot)${file_store}"
                # confirm the file store exists
                if [ -d "${file_store}" ]; then
                    # get the file store size
                    file_store_size=$(du --summarize "${file_store}" | awk '{ print $1 }')
                    echo -e "website file store ${file_store} size: $(( ${file_store_size} / 1024 ))MB"
                    # determine whether the file store is untracked or tracked
                    cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" \
                        && git check-ignore --quiet "${file_store}"
                    if [ $? -eq 0 ]; then
                        echo -e "- this website file store ${file_store} is untracked"
                        echo -e "- this website file store will be rsynced"
                        echo -e "- rely on virtual machine backups for disaster recovery"
                    else
                        # determine if the file store is too large
                        if [ "${file_store_size}" -gt "${directory_size_maximum}" ]; then
                            echo -e "- this website file store ${file_store} is tracked but over the limit to commit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                            echo -e "- this website file store will be rsynced"
                            echo -e "- rely on virtual machine backups for disaster recovery"
                            cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" \
                                && git reset --all "${file_store}"
                        else
                            echo -e "- this website file store ${file_store} is tracked and within the limit to commit [$(( ${file_store_size} / 1024 ))MB / $(( ${directory_size_maximum} / 1024 ))MB max]"
                            echo -e "- this website file store will be committed"
                        fi
                    fi
                fi
            done
            # if the database configuration file is tracked, we need to checkout the correct one so we can pull
            # we'll provide a warning here as well to remove it from the website repo
            if [ ! -z "$(catapult websites.apache.$5.software)" ]; then
                cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/$(catapult websites.apache.$5.webroot)" \
                    && git ls-files --error-unmatch "$(catapult websites.apache.$5.webroot)$(provisioners software.apache.$(catapult websites.apache.$5.software).database_config_file)" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "WARNING: the software database config file $(catapult websites.apache.$5.webroot)$(provisioners software.apache.$(catapult websites.apache.$5.software).database_config_file) is tracked, to continue we had to remove it and will be regenerated shortly, however there will be a potential loss of connectivity for a short period"
                    cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)/$(catapult websites.apache.$5.webroot)" \
                        && git checkout "$(catapult websites.apache.$5.webroot)$(provisioners software.apache.$(catapult websites.apache.$5.software).database_config_file)"
                fi
            fi
            # now that we have everything in our index that we want, commit, pull, then push
            cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" \
                && git commit --message="Catapult auto-commit ${1}:$(catapult websites.apache.$5.software_workflow):software_files"
            cd "/var/www/repositories/apache/$(catapult websites.apache.$5.domain)" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $(catapult environments.$1.branch)" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git submodule update --init --recursive" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git push origin $(catapult environments.$1.branch)"
        # git reset files and branch if outside of branch and software_workflow
        else
            # stash any pending work in localdev as a courtesy (branch may vary)
            if [ "${1}" = "dev" ]; then
                cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
                    && git stash save
            fi
            # hard reset (tracked), checkout all from HEAD, clean (untracked), checkout correct branch, then pull in latest
            cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
                && git reset --quiet --hard HEAD -- \
                && git checkout . \
                && git clean -d --force --force \
                && git checkout $(catapult environments.$1.branch) \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin $(catapult environments.$1.branch)" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git submodule update --init --recursive"
        fi
        # if we're on develop and software workflow is set to downstream, pull master into develop to keep it up to date
        if ([ "${branch}" = "develop" ] && [ "$(catapult websites.apache.$5.software_workflow)" = "downstream" ]); then
            cd /var/www/repositories/apache/$(catapult websites.apache.$5.domain) \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git fetch" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git pull origin master" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git submodule update --init --recursive" \
                && sudo ssh-agent bash -c "ssh-add /catapult/secrets/id_rsa; git push origin $(catapult environments.$1.branch)"
        fi
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
