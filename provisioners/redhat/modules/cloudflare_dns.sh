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

    # set dns a records if cloudflare zone exists
    if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" != "[]" ]; then

        # create an array of dns records
        domain_dns_records=()
        if [ "${1}" == "production" ]; then
            domain_dns_records+=("${domain}")
            domain_dns_records+=("www.${domain}")
        else
            domain_dns_records+=("${1}.${domain}")
            domain_dns_records+=("www.${1}.${domain}")
        fi
        
        for domain_dns_record in "${domain_dns_records[@]}"; do

            # get the cloudflare zone id
            cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')

            # determine if dns a record exists
            dns_record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records?type=A&name=${domain_dns_record}" \
            -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
            -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
            -H "Content-Type: application/json")

            if [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" == "[]" ]; then
                # create dns a record
                dns_record=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records" \
                -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
                -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"A\",\"name\":\"${domain_dns_record}\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":true}")
            else
                # update dns a record
                dns_record_id=$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                dns_record=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records/${dns_record_id}" \
                -H "X-Auth-Email: $(catapult company.cloudflare_email)" \
                -H "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
                -H "Content-Type: application/json" \
                --data "{\"id\":\"${dns_record_id}\",\"type\":\"A\",\"name\":\"${domain_dns_record}\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":true}")
            fi

            # output the result
            if [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
                echo "[${domain_dns_record}] $(echo ${dns_record} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
            else
                echo "[${domain_dns_record}] successfully set dns a record"
            fi

        done

    else
        echo "[${domain}] cloudflare zone does not exist"
    fi

done

touch "/catapult/provisioners/redhat/logs/cloudflare_dns.$(catapult websites.apache.$5.domain).complete"
