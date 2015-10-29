configuration=$(cat /catapult/secrets/configuration.yml)

function catapult {
    echo "${configuration}" | shyaml get-value $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${configuration}" | shyaml get-value $1
    else
        echo ""
    fi
}
