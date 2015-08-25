echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
    if [ ! -z "${domain_tld_override}" ]; then
        domain_root="${domain}.${domain_tld_override}"
    else
        domain_root="${domain}"
    fi

    if [ "$1" = "dev" ]; then
        echo -e "\t * skipping cloudflare as global dns is not required in dev..."
    else
        if [ "$1" = "production" ]; then
            echo -e "\nNOTICE: ${domain_root}"
        else
            echo -e "\nNOTICE: ${1}.${domain_root}"
        fi
        echo -e "\t * configuring cloudflare dns"
        IFS=. read -a domain_levels <<< "${domain_root}"
        if [ "${#domain_levels[@]}" = "2" ]; then

            # $domain_levels[0] => devopsgroup
            # $domain_levels[1] => io

            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[0]}.${domain_levels[1]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[0]}.${domain_levels[1]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        elif [ "${#domain_levels[@]}" = "3" ]; then

            # $domain_levels[0] => drupal7
            # $domain_levels[1] => devopsgroup
            # $domain_levels[2] => io

            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[1]}.${domain_levels[2]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[1]}.${domain_levels[2]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[1]}.${domain_levels[2]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        elif [ "${#domain_levels[@]}" = "4" ]; then

            # $domain_levels[0] => devopsgroup
            # $domain_levels[1] => io
            # $domain_levels[2] => safeway
            # $domain_levels[3] => com

            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[2]}.${domain_levels[3]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[2]}.${domain_levels[3]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[2]}.${domain_levels[3]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        elif [ "${#domain_levels[@]}" = "5" ]; then

            # $domain_levels[0] => drupal7
            # $domain_levels[1] => devopsgroup
            # $domain_levels[2] => io
            # $domain_levels[3] => safeway
            # $domain_levels[4] => com

            # determine if cloudflare zone exists
            cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[3]}.${domain_levels[4]}"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]')

            if [ "${cloudflare_zone_id}" = "[]" ]; then
                # create cloudflare zone
                echo "cloudflare zone does not exist" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[3]}.${domain_levels[4]}\",\"jump_start\":false}"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            else
                # get cloudflare zone
                echo "cloudflare zone exists" | sed "s/^/\t\t/"
                cloudflare_zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[3]}.${domain_levels[4]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]')
                echo $cloudflare_zone_id | sed "s/^/\t\t/"
            fi

            if [ "$1" = "production" ]; then
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            else
                # set dns a record for environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"

                # set dns a record for www.environment
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}"\
                | sed "s/^/\t\t/"
            fi

        fi

        # set cloudflare ssl setting per zone
        curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/ssl"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"value\":\"full\"}"\
        | sed "s/^/\t\t/"

        # set cloudflare tls setting per zone
        curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/tls_client_auth"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"value\":\"on\"}"\
        | sed "s/^/\t\t/"

        # purge cloudflare cache per zone
        echo "clearing cloudflare cache" | sed "s/^/\t\t/"
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache"\
        -H "X-Auth-Email: ${cloudflare_email}"\
        -H "X-Auth-Key: ${cloudflare_api_key}"\
        -H "Content-Type: application/json"\
        --data "{\"purge_everything\":true}"\
        | sed "s/^/\t\t/"

    fi

done
