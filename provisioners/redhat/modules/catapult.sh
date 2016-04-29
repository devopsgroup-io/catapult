configuration=$(cat /catapult/secrets/configuration.yml)
function catapult {
    echo "${configuration}" | shyaml get-value $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${configuration}" | shyaml get-value $1
    else
        echo ""
    fi
}
function catapult_array {
    echo "${configuration}" | shyaml get-values $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${configuration}" | shyaml get-values $1
    else
        echo ""
    fi
}

configuration_provisioners=$(cat /catapult/provisioners/provisioners.yml)
function provisioners {
    echo "${configuration_provisioners}" | shyaml get-value $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${configuration_provisioners}" | shyaml get-value $1
    else
        echo ""
    fi
}
function provisioners_array {
    echo "${configuration_provisioners}" | shyaml get-values $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${configuration_provisioners}" | shyaml get-values $1
    else
        echo ""
    fi
}
