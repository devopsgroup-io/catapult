source "/catapult/provisioners/redhat/modules/catapult.sh"

if [ "$1" = "dev" ]; then

    echo -e "\t * skipping cloudflare as global dns is not required in dev..."

else

    cloudflare_api_key="$(echo "${configuration}" | shyaml get-value company.cloudflare_api_key)"
    cloudflare_email="$(echo "${configuration}" | shyaml get-value company.cloudflare_email)"
    redhat_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat.ip)"

    echo "${configuration}" | shyaml get-values-0 websites.apache |
    while IFS='' read -r -d '' key; do

        domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
        domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
        if [ ! -z "${domain_tld_override}" ]; then
            domain_root="${domain}.${domain_tld_override}"
        else
            domain_root="${domain}"
        fi

        if [ "$1" = "production" ]; then
            echo -e "\nNOTICE: ${domain_root}"
        else
            echo -e "\nNOTICE: ${1}.${domain_root}"
        fi
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
                echo "* cloudflare zone does not exist, creating..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"jump_start\":false}")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            else
                # get cloudflare zone
                echo "* cloudflare zone exists, retrieving..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[0]}.${domain_levels[1]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            fi

            # set dns a records only if we were able to create/get zone id
            if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "True" ]; then
                echo "* creating dns a records..." | sed "s/^/\t/"
                if [ "$1" = "production" ]; then
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                else
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${1}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                fi
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
                echo "* cloudflare zone does not exist, creating..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[1]}.${domain_levels[2]}\",\"jump_start\":false}")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            else
                # get cloudflare zone
                echo "* cloudflare zone exists, retrieving..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[1]}.${domain_levels[2]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            fi

            # set dns a records only if we were able to create/get zone id
            if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "True" ]; then
                echo "* creating dns a records..." | sed "s/^/\t/"
                if [ "$1" = "production" ]; then
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                else
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                fi
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
                echo "* cloudflare zone does not exist, creating..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[2]}.${domain_levels[3]}\",\"jump_start\":false}")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            else
                # get cloudflare zone
                echo "* cloudflare zone exists, retrieving..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[2]}.${domain_levels[3]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            fi

            # set dns a records only if we were able to create/get zone id
            if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "True" ]; then
                echo "* creating dns a records..." | sed "s/^/\t/"
                if [ "$1" = "production" ]; then
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                else
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}.${domain_levels[1]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                fi
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
                echo "* cloudflare zone does not exist, creating..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json"\
                --data "{\"name\":\"${domain_levels[3]}.${domain_levels[4]}\",\"jump_start\":false}")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            else
                # get cloudflare zone
                echo "* cloudflare zone exists, retrieving..." | sed "s/^/\t/"
                cloudflare_zone=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain_levels[3]}.${domain_levels[4]}"\
                -H "X-Auth-Email: ${cloudflare_email}"\
                -H "X-Auth-Key: ${cloudflare_api_key}"\
                -H "Content-Type: application/json")
                if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                    echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                else
                    cloudflare_zone_id=$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["result"][0]["id"]' )
                    echo "success" | sed "s/^/\t\t/"
                fi
            fi

            # set dns a records only if we were able to create/get zone id
            if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "True" ]; then
                echo "* creating dns a records..." | sed "s/^/\t/"
                if [ "$1" = "production" ]; then
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                else
                    # set dns a record for environment
                    cloudflare_zone_dns_records_a1=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"${1}.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a1}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                    # set dns a record for www.environment
                    cloudflare_zone_dns_records_a2=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records"\
                    -H "X-Auth-Email: ${cloudflare_email}"\
                    -H "X-Auth-Key: ${cloudflare_api_key}"\
                    -H "Content-Type: application/json"\
                    --data "{\"type\":\"A\",\"name\":\"www.${1}.${domain_levels[0]}.${domain_levels[1]}.${domain_levels[2]}\",\"content\":\"${redhat_ip}\",\"ttl\":1,\"proxied\":true}")
                    if [ "$(echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                        echo "${cloudflare_zone_dns_records_a2}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
                    else
                        echo "success" | sed "s/^/\t\t/"
                    fi
                fi
            fi

        fi

        # set cloudflare ssl setting per zone, providing zone is valid
        if [ "$(echo "${cloudflare_zone}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "True" ]; then
            echo "* setting cloudflare zone ssl to full" | sed "s/^/\t/"
            cloudflare_zone_ssl=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/ssl"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            --data "{\"value\":\"full\"}")
            if [ "$(echo "${cloudflare_zone_ssl}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                echo "${cloudflare_zone_ssl}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
            else
                echo "success" | sed "s/^/\t\t/"
            fi

            echo "* setting cloudflare zone authenticated origin pulls to on" | sed "s/^/\t/"
            cloudflare_zone_tls_client_auth=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/settings/tls_client_auth"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            --data "{\"value\":\"on\"}")
            if [ "$(echo "${cloudflare_zone_tls_client_auth}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                echo "${cloudflare_zone_tls_client_auth}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
            else
                echo "success" | sed "s/^/\t\t/"
            fi

            echo "* clearing cloudflare zone cache" | sed "s/^/\t/"
            cloudflare_zone_cache=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/purge_cache"\
            -H "X-Auth-Email: ${cloudflare_email}"\
            -H "X-Auth-Key: ${cloudflare_api_key}"\
            -H "Content-Type: application/json"\
            --data "{\"purge_everything\":true}")
            if [ "$(echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["success"]' )" == "False" ]; then
                echo "${cloudflare_zone_cache}" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["errors"][0]["message"]' | sed "s/^/\t\t/"
            else
                echo "success" | sed "s/^/\t\t/"
            fi
        fi

    done

fi
