source "/catapult/provisioners/redhat/modules/catapult.sh"


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

done

touch "/catapult/provisioners/redhat/logs/cloudflare_zones.$(catapult websites.apache.$5.domain).complete"
