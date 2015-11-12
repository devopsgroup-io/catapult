source "/catapult/provisioners/redhat/modules/catapult.sh"

domains=()

domain=$(catapult websites.apache.$5.domain)
domains+=("${domain}")

domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
if [ ! -z "${domain_tld_override}" ]; then
    domains+=("${domain}.${domain_tld_override}")
fi

for domain in "${domains[@]}"; do

    # create array from domain
    IFS=. read -a domain_levels <<< "${domain}"

    # determine if cloudflare zone exists
    cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
    -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
    -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    -H "Content-Type: application/json")

    # clear cloudflare zone cache by zone id, if it exists
    if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" != "[]" ]; then
        cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
        cloudflare_zone_cache=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache" \
        -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
        -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        -H "Content-Type: application/json" \
        --data "{\"purge_everything\":true}")
        if [ "$(echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] $(echo ${cloudflare_zone_cache} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
        else
            echo "[${domain_levels[-2]}.${domain_levels[-1]}] successfully cleared cache"
        fi
    else
        echo "[${domain_levels[-2]}.${domain_levels[-1]}] cloudflare zone does not exist"
    fi

done

touch "/catapult/provisioners/redhat/logs/cloudflare_cache.$(catapult websites.apache.$5.domain).complete"
