source "/catapult/provisioners/redhat/modules/catapult.sh"

# create a vhost per website
echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    # define variables
    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")

    # generate letsencrypt https certificates for upstream cloud environments
    if ([ "$1" != "dev" ]); then
        if [ -z "${domain_tld_override}" ]; then
            bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --domain "${domain_environment}" --domain "www.${domain_environment}" 2>&1
            sudo cat >> /catapult/provisioners/redhat/installers/dehydrated/domains.txt << EOF
${domain_environment} www.${domain_environment}
EOF
        else
            bash /catapult/provisioners/redhat/installers/dehydrated/dehydrated --cron --domain "${domain_environment}.${domain_tld_override}" --domain "www.${domain_environment}.${domain_tld_override}" 2>&1
            sudo cat >> /catapult/provisioners/redhat/installers/dehydrated/domains.txt << EOF
${domain_environment}.${domain_tld_override} www.${domain_environment}.${domain_tld_override}
EOF
        fi
    fi

done
