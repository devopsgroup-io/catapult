source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "$1" = "dev" ]; then

    echo -e "Skipping this module for the dev environment."

else

    # domain
    domain=$(catapult websites.apache.$5.domain)

    # domain_tld_override
    domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)

    # create an array of domains
    domains=()
    if [ -z "${domain_tld_override}" ]; then
        domains+=("${domain}")
    else
        domains+=("${domain}")
        domains+=("${domain}.${domain_tld_override}")
    fi

    valid_http_response_codes=("200" "400")

    for domain in "${domains[@]}"; do

        # create array from domain
        IFS=. read -a domain_levels <<< "${domain}"

        # try and create the zone and let cloudflare handle if it already exists
        cloudflare_zone=$(curl --silent --show-error --connect-timeout 5 --max-time 10 --write-out "HTTPSTATUS:%{http_code}" --request POST "https://api.cloudflare.com/client/v4/zones" \
        --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
        --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        --header "Content-Type: application/json" \
        --data "{\"name\":\"${domain_levels[-2]}.${domain_levels[-1]}\",\"jump_start\":false}")
        cloudflare_zone_status=$(echo "${cloudflare_zone}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        cloudflare_zone=$(echo "${cloudflare_zone}" | sed -e 's/HTTPSTATUS\:.*//g')

        # output the result
        if [[ ! "${valid_http_response_codes[@]}" =~ "${cloudflare_zone_status}" ]]; then
            echo -e "[${cloudflare_zone_status}] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
        elif [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] $(echo ${cloudflare_zone} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
        else
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] successfully created zone"
        fi

        # declare minimum TLS version for zone
        min_tls_ver="1.2"

        # get cloudflare zone details
        cloudflare_zone=$(curl --silent --show-error  --connect-timeout 30 --max-time 60 --write-out "HTTPSTATUS:%{http_code}" --request GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
        --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
        --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        --header "Content-Type: application/json")
        cloudflare_zone_status=$(echo "${cloudflare_zone}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        cloudflare_zone=$(echo "${cloudflare_zone}" | sed -e 's/HTTPSTATUS\:.*//g')

        # check for a curl error
        if [[ ! "${valid_http_response_codes[@]}" =~ "${cloudflare_zone_status}" ]]; then
            echo -e "[${cloudflare_zone_status}] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
        elif [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" == "[]" ]; then
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] cloudflare zone does not exist"
        else
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] cloudflare zone exists, managing minimum TLS version..."

            # get the cloudflare zone id
            cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')

            # manage minimum TLS version for zone
            cloudflare_min_tls=$(curl --silent --show-error  --connect-timeout 30 --max-time 60 --write-out "HTTPSTATUS:%{http_code}" --request PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/min_tls_version" \
            --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
            --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
            --header "Content-Type: application/json" \
            --data "{\"value\":\"${min_tls_ver}\"}")
            cloudflare_min_tls_status=$(echo "${cloudflare_min_tls}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
            cloudflare_min_tls=$(echo "${cloudflare_min_tls}" | sed -e 's/HTTPSTATUS\:.*//g')

            # check for a curl error
            if [[ ! "${valid_http_response_codes[@]}" =~ "200" ]]; then
                echo -e "[${cloudflare_min_tls_status}] http error ${cloudflare_min_tls_status} there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
            elif [ "$(echo "${cloudflare_min_tls}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
                echo "[${cloudflare_min_tls_status}] $(echo ${cloudflare_min_tls} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
            else
                echo "[${cloudflare_min_tls_status}] successfully set minimum TLS version to: ${min_tls_ver}"
            fi
        fi

    done

fi

touch "/catapult/provisioners/redhat/logs/cloudflare_zones.$(catapult websites.apache.$5.domain).complete"
