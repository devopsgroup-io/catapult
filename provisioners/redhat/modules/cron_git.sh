#!/bin/bash

for directory in /var/www/repositories/apache/*/; do
    # on a new provision, there will be no directories and an empty for loop returns itself
    if [ -e "${directory}" ]; then
        folder=$(basename "${directory}")
        if ! ([ "_default_" == "${folder}" ]); then
            cd "${directory}" \
                && git gc
        fi
    fi
done
