source "/catapult/provisioners/redhat/modules/catapult.sh"

# function to implode array after exploding
function join { local IFS="$1"; shift; echo "$*"; }

# set domain for environment
domain="$(catapult websites.apache.$5.domain)"
domain_www="www.$(catapult websites.apache.$5.domain)"
if [ "${1}" != "production" ]; then 
    domain="${1}.$(catapult websites.apache.$5.domain)"
    domain_www="www.${1}.$(catapult websites.apache.$5.domain)"
fi

# append domain if domain_tld_override
domain_tld_override=$(catapult websites.apache.$5.domain_tld_override)
if [ ! -z "${domain_tld_override}" ]; then
    domain="${domain}.${domain_tld_override}"
    domain_www="${domain_www}.${domain_tld_override}"
fi

# create arrays from domain and domain_www
IFS='.' read -a domain_levels <<< "${domain}"
IFS='.' read -a domain_levels_www <<< "${domain_www}"

# determine if cloudflare zone exists
cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[-2]}.${domain_levels[-1]}" \
-H "X-Auth-Email: $(catapult company.cloudflare_email)" \
-H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
-H "Content-Type: application/json")

# set a records if cloudflare zone exists
if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" != "[]" ]; then
    
    # get the cloudflare zone id
    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')

    # remove the zone from the domain and domain_www arrays
    unset domain_levels[${#domain_levels[@]}-1]
    unset domain_levels[${#domain_levels[@]}-1]
    unset domain_levels_www[${#domain_levels_www[@]}-1]
    unset domain_levels_www[${#domain_levels_www[@]}-1]

    # set dns a record
    if [[ "${#domain_levels[@]}" != "0" ]]; then

        echo "setting dns a record $(join . "${domain_levels[@]}")"

        dns_record=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records" \
        -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
        -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$(join . "${domain_levels[@]}")\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":true}")

        if [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
            echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]'
        else
            echo "success"
        fi

    fi

    # set www dns a record
    if [[ "${#domain_levels_www[@]}" != "0" ]]; then
        
        echo "setting dns www a record $(join . "${domain_levels_www[@]}")"

        dns_record=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records" \
        -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
        -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$(join . "${domain_levels_www[@]}")\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":true}")

        if [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
            echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]'
        else
            echo "success"
        fi

    fi

else
    echo "cloudflare zone does not exist"
fi

touch "/catapult/provisioners/redhat/logs/cloudflare_dns.$(catapult websites.apache.$5.domain).complete"
