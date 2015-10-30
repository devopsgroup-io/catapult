source "/catapult/provisioners/redhat/modules/catapult.sh"

domain=$(catapult websites.apache.$5.domain)
domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
if [ ! -z "${domain_tld_override}" ]; then
    domain="${domain}.${domain_tld_override}"
fi

# create array from domain
IFS=. read -a domain_levels <<< "${domain}"

# determine if cloudflare zone exists
cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
-H "X-Auth-Email: $(catapult company.cloudflare_email)" \
-H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
-H "Content-Type: application/json" \
| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

if [ "${cloudflare_zone_id}" = "[]" ]; then
    # create cloudflare zone
    echo "cloudflare zone does not exist, creating..."
    cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
    -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
    -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    -H "Content-Type: application/json" \
    --data "{\"name\":\"${domain_levels[-2]}.${domain_levels[-1]}\",\"jump_start\":false}")
    if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
        echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]'
    else
        cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
        echo "success"
    fi
else
    # get cloudflare zone
    echo "cloudflare zone exists, retrieving..."
    cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
    -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
    -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    -H "Content-Type: application/json")
    if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
        echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]'
    else
        cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
        echo "success"
    fi
fi

# clear cloudflare zone cache, providing zone is valid
if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "True" ]; then
    echo "clearing cloudflare zone (${domain_levels[-2]}.${domain_levels[-1]}) cache"
    cloudflare_zone_cache=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache" \
    -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
    -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    -H "Content-Type: application/json" \
    --data "{\"purge_everything\":true}")
    if [ "$(echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
        echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]'
    else
        echo "success"
    fi
fi

touch "/catapult/provisioners/redhat/logs/cloudflare_cache.$(catapult websites.apache.$5.domain).complete"
