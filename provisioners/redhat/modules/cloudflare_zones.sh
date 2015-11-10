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

    # try and create the zone and let cloudflare handle if it already exists
    cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
    -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
    -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
    -H "Content-Type: application/json" \
    --data "{\"name\":\"${domain_levels[-2]}.${domain_levels[-1]}\",\"jump_start\":false}")

    if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
        echo "[${domain_levels[-2]}.${domain_levels[-1]}] $(echo ${cloudflare_zone} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
    else
        echo "[${domain_levels[-2]}.${domain_levels[-1]}] successfully created zone"
    fi

done

touch "/catapult/provisioners/redhat/logs/cloudflare_zones.$(catapult websites.apache.$5.domain).complete"
