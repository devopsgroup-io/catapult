#!/bin/bash

/bin/echo -e "=============================================================================="
/bin/echo -e "THIS CATAPULT CRON_GIT MODULE RUNS GARBAGE COLLECTION FOR WEBSITE REPOSITORIES"
/bin/echo -e "=============================================================================="

for directory in /var/www/repositories/apache/*/; do
    # on a new provision, there will be no directories and an empty for loop returns itself
    if [ -e "${directory}" ]; then
        folder=$(basename "${directory}")
        if ! ([ "_default_" == "${folder}" ]); then
            /bin/echo -e "\n${folder}"
            /bin/echo -e "----------------------------------------"
            repository_size_before=$(du --human-readable --summarize ${directory} | awk '{ print $1 }')
            cd "${directory}" \
                && /usr/bin/git gc --prune
            repository_size_after=$(du --human-readable --summarize ${directory} | awk '{ print $1 }')
            /bin/echo -e "before ${repository_size_before}"
            /bin/echo -e "after ${repository_size_after}"
            # allow for a cool down
            sleep 45
        fi
    fi
done

/bin/echo -e "\n"
