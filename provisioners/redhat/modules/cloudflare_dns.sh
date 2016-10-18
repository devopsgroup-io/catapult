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

    # determine if cloudflare zone exists
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
        echo "[${domain_levels[-2]}.${domain_levels[-1]}] cloudflare zone exists, managing dns records..."
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
            dns_record=$(curl --silent --show-error  --connect-timeout 30 --max-time 60 --write-out "HTTPSTATUS:%{http_code}" --request GET "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records?type=A&name=${domain_dns_record}" \
            --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
            --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
            --header "Content-Type: application/json")
            dns_record_status=$(echo "${dns_record}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
            dns_record=$(echo "${dns_record}" | sed -e 's/HTTPSTATUS\:.*//g')

            # calculate the amount of subdomains to then use as a determination between being cloudflare proxied or not in order to support SSL (cloudflare only supports one subdomain level)
            IFS=. read -a domain_levels <<< "${domain_dns_record}"
            if [ ${#domain_levels[@]} -gt 3 ]; then
                cloudflare_proxied="false"
            else
                cloudflare_proxied="true"
            fi

            # create or update the dns a record
            if [[ ! "${valid_http_response_codes[@]}" =~ "${dns_record_status}" ]]; then
                echo -e "[${dns_record_status}] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
            else
                # create dns a record
                if [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')" == "[]" ]; then
                    dns_record=$(curl --silent --show-error  --connect-timeout 30 --max-time 60 --write-out "HTTPSTATUS:%{http_code}" --request POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records" \
                    --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
                    --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
                    --header "Content-Type: application/json" \
                    --data "{\"type\":\"A\",\"name\":\"${domain_dns_record}\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":${cloudflare_proxied}}")
                    dns_record_status=$(echo "${dns_record}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
                    dns_record=$(echo "${dns_record}" | sed -e 's/HTTPSTATUS\:.*//g')
                # update dns a record
                else
                    dns_record_id=$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                    dns_record=$(curl --silent --show-error  --connect-timeout 30 --max-time 60 --write-out "HTTPSTATUS:%{http_code}" --request PUT "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records/${dns_record_id}" \
                    --header "X-Auth-Email: $(catapult company.cloudflare_email)" \
                    --header "X-Auth-Key: $(catapult company.cloudflare_api_key)" \
                    --header "Content-Type: application/json" \
                    --data "{\"id\":\"${dns_record_id}\",\"type\":\"A\",\"name\":\"${domain_dns_record}\",\"content\":\"$(catapult environments.$1.servers.redhat.ip)\",\"ttl\":1,\"proxied\":${cloudflare_proxied}}")
                    dns_record_status=$(echo "${dns_record}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
                    dns_record=$(echo "${dns_record}" | sed -e 's/HTTPSTATUS\:.*//g')
                fi
                # output the result
                if [[ ! "${valid_http_response_codes[@]}" =~ "${dns_record_status}" ]]; then
                    echo -e "[${dns_record_status}] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
                elif [ "$(echo "${dns_record}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]')" == "False" ]; then
                    echo "[${domain_dns_record}] $(echo ${dns_record} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]')"
                else
                    echo "[${domain_dns_record}] successfully set dns a record"
                fi

            fi

        done

    fi

done

touch "/catapult/provisioners/redhat/logs/cloudflare_dns.$(catapult websites.apache.$5.domain).complete"
