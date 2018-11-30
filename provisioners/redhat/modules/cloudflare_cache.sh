source "/catapult/provisioners/redhat/modules/catapult.sh"

domains=()

domain=$(catapult websites.apache.$5.domain)
domains+=("${domain}")

domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
if [ ! -z "${domain_tld_override}" ]; then
    domains+=("${domain}.${domain_tld_override}")
fi

valid_http_response_codes=("200" "400")

for domain in "${domains[@]}"; do

    # create array from domain
    IFS=. read -a domain_levels <<< "${domain}"

    # determine if cloudflare zone exists
    cloudflare_zone=$(curl --silent --show-error --connect-timeout 5 --max-time 10 --write-out "HTTPSTATUS:%{http_code}" --request GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
    --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
    --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    --header "Content-Type: application/json")
    cloudflare_zone_status=$(echo "${cloudflare_zone}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    cloudflare_zone=$(echo "${cloudflare_zone}" | sed -e 's/HTTPSTATUS\:.*//g')

    # check for a curl error
    if [[ ! "${valid_http_response_codes[@]}" =~ "${cloudflare_zone_status}" ]]; then

        echo -e "[${cloudflare_zone_status}] 1 there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"

    # clear cloudflare zone cache by zone id, if it exists
    elif [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" != "[]" ]; then

        cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
        cloudflare_zone_cache=$(curl --silent --show-error --connect-timeout 5 --max-time 10 --write-out "HTTPSTATUS:%{http_code}" --request DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache" \
        --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
        --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        --header "Content-Type: application/json" \
        --data "{\"purge_everything\":true}")
        cloudflare_zone_cache_status=$(echo "${cloudflare_zone_cache}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        cloudflare_zone_cache=$(echo "${cloudflare_zone_cache}" | sed -e 's/HTTPSTATUS\:.*//g')

        # check for a curl error
        if [[ ! "${valid_http_response_codes[@]}" =~ "${cloudflare_zone_cache_status}" ]]; then
            echo -e "[${cloudflare_zone_status}] 2 there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
        elif [ "$(echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] $(echo ${cloudflare_zone_cache} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
        else
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] successfully cleared cache"
        fi

    else

        echo "[${domain_levels[-2]}.${domain_levels[-1]}] cloudflare zone does not exist"
        
    fi

done

touch "/catapult/provisioners/redhat/logs/cloudflare_cache.$(catapult websites.apache.$5.domain).complete"
