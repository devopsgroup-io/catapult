#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance
# $5 => software_validation



echo -e "==> Updating existing packages and installing utilities"
start=$(date +%s)
# only allow authentication via ssh key pair
# suppress this - There were 34877 failed login attempts since the last successful login.
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sudo systemctl stop sshd.service
sudo systemctl start sshd.service
# update yum
sudo yum update -y
# git clones
sudo yum install -y git
# parse yaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
configuration=$(gpg --batch --passphrase ${3} --decrypt /catapult/secrets/configuration.yml.gpg)
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa --decrypt /catapult/secrets/id_rsa.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa.pub --decrypt /catapult/secrets/id_rsa.pub.gpg
chmod 700 /catapult/secrets/id_rsa
chmod 700 /catapult/secrets/id_rsa.pub
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"



echo -e "\n\n==> Configuring time"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/time.sh
provisionstart=$(date +%s)
sudo touch /catapult/provisioners/redhat/logs/apache.log
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing PHP"
start=$(date +%s)
#@todo think about having directive per website that lists php module dependancies
sudo yum install -y php
sudo yum install -y php-mysql
sudo yum install -y php-curl
sudo yum install -y php-gd
sudo yum install -y php-dom
sudo yum install -y php-mbstring
sed -i -e "s#\;date\.timezone.*#date.timezone = \"$(echo "${configuration}" | shyaml get-value company.timezone_redhat)\"#g" /etc/php.ini
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing Drush and WP-CLI"
start=$(date +%s)
sudo yum install -y php-cli
sudo yum install -y mariadb
# install drush
if [ ! -f /usr/bin/drush  ]; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    ln -s /usr/local/bin/composer /usr/bin/composer
    git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
    cd /usr/local/src/drush
    git checkout 7.0.0-rc1
    ln -s /usr/local/src/drush/drush /usr/bin/drush
    composer install
fi
drush --version
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Installing Apache"
start=$(date +%s)
# install httpd
sudo yum install -y httpd
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
sudo yum install -y mod_ssl
sudo bash /etc/ssl/certs/make-dummy-cert "/etc/ssl/certs/httpd-dummy-cert.key.cert"
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring git repositories (This may take a while...)"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/git.sh
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Configuring Apache"
start=$(date +%s)
# set variables from secrets/configuration.yml
mysql_user="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user)"
mysql_user_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.user_password)"
mysql_root_password="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.mysql.root_password)"
redhat_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat.ip)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.$1.servers.redhat_mysql.ip)"
company_email="$(echo "${configuration}" | shyaml get-value company.email)"
cloudflare_api_key="$(echo "${configuration}" | shyaml get-value company.cloudflare_api_key)"
cloudflare_email="$(echo "${configuration}" | shyaml get-value company.cloudflare_email)"

# configure vhosts
# this is a debianism - but it makes things easier for cross-distro
sudo mkdir -p /etc/httpd/sites-available
sudo mkdir -p /etc/httpd/sites-enabled
if ! grep -q "IncludeOptional sites-enabled/*.conf" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "IncludeOptional sites-enabled/*.conf" >> "/etc/httpd/conf/httpd.conf"'
fi
# define the server's servername
# suppress this - httpd: Could not reliably determine the server's fully qualified domain name, using localhost.localdomain. Set the 'ServerName' directive globally to suppress this message
if ! grep -q "ServerName localhost" "/etc/httpd/conf/httpd.conf"; then
   sudo bash -c 'echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf'
fi

# start fresh remove all logs, vhosts, and kill the welcome file
sudo rm -rf /var/log/httpd/*
sudo rm -rf /etc/httpd/sites-available/*
sudo rm -rf /etc/httpd/sites-enabled/*
sudo cat /dev/null > /etc/httpd/conf.d/welcome.conf

echo "${configuration}" | shyaml get-values-0 websites.apache |
while IFS='' read -r -d '' key; do

    domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    if [ -z "${domain_tld_override}" ]; then
        domain_root="${domain}.${domain_tld_override}"
    else
        domain_root="${domain}"
    fi
    domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
    domainvaliddbname=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " " | tr "." "_")
    force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
    force_https=$(echo "$key" | grep -w "force_https" | cut -d ":" -f 2 | tr -d " ")
    software=$(echo "$key" | grep -w "software" | cut -d ":" -f 2 | tr -d " ")
    software_dbprefix=$(echo "$key" | grep -w "software_dbprefix" | cut -d ":" -f 2 | tr -d " ")
    software_workflow=$(echo "$key" | grep -w "software_workflow" | cut -d ":" -f 2 | tr -d " ")
    webroot=$(echo "$key" | grep -w "webroot" | cut -d ":" -f 2 | tr -d " ")

    # configure apache
    if [ "$1" = "production" ]; then
        echo -e "\nNOTICE: ${domain_root}"
    else
        echo -e "\nNOTICE: ${1}.${domain_root}"
    fi

    # configure cloudflare dns
    if [ "$1" != "dev" ]; then
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

        # throw a new line
        echo -e "\n"

    fi

    # configure vhost
    echo -e "\t * configuring vhost"
    sudo mkdir -p /var/log/httpd/${domain_environment}
    sudo touch /var/log/httpd/${domain_environment}/access.log
    sudo touch /var/log/httpd/${domain_environment}/error.log
    if [ -z "${domain_tld_override}" ]; then
        domain_tld_override_value=""
    else
        domain_tld_override_value="ServerAlias ${domain_environment}.${domain_tld_override}
        ServerAlias www.${domain_environment}.${domain_tld_override}"
    fi
    if ([ -z "${force_auth}" ]) && ([ "$1" != "dev" ] || [ "$1" != "production" ]); then
        force_auth_value=""
    else
        sudo htpasswd -b -c /etc/httpd/sites-enabled/${domain_environment}.htpasswd $force_auth $force_auth
        force_auth_value="<Location />
            # Force HTTP authentication
            AuthType Basic
            AuthName \"Authentication Required\"
            AuthUserFile \"/etc/httpd/sites-enabled/${domain_environment}.htpasswd\"
            Require valid-user
        </Location>"
    fi
    if [ "${force_https}" = true ]; then
        # rewrite all http traffic to https
        force_https_value="Redirect Permanent / https://${domain_environment}"
    else
        force_https_value=""
    fi
    sudo cat > /etc/httpd/sites-available/$domain_environment.conf << EOF

    RewriteEngine On

    # must listen * to support cloudflare
    <VirtualHost *:80>
        ServerAdmin $company_email
        ServerName $domain_environment
        ServerAlias www.$domain_environment
        $domain_tld_override_value
        DocumentRoot /var/www/repositories/apache/$domain/$webroot
        ErrorLog /var/log/httpd/$domain_environment/error.log
        CustomLog /var/log/httpd/$domain_environment/access.log combined
        $force_auth_value
        $force_https_value
    </VirtualHost> 

    <IfModule mod_ssl.c>
        # must listen * to support cloudflare
        <VirtualHost *:443>
            ServerAdmin $company_email
            ServerName $domain_environment
            ServerAlias www.$domain_environment
            DocumentRoot /var/www/repositories/apache/$domain/$webroot
            ErrorLog /var/log/httpd/$domain_environment/error.log
            CustomLog /var/log/httpd/$domain_environment/access.log combined
            SSLEngine on
            SSLCertificateFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            SSLCertificateKeyFile /etc/ssl/certs/httpd-dummy-cert.key.cert
            $force_auth_value
        </VirtualHost>
    </IfModule>

    # allow .htaccess in apache 2.4+
    <Directory "/var/www/repositories/apache/$domain/${webroot}">
        AllowOverride All
        Options -Indexes +FollowSymlinks
    </Directory>

    # deny access to _sql folders
    <Directory "/var/www/repositories/apache/$domain/${webroot}_sql">
        Order Deny,Allow
        Deny From All
    </Directory>

EOF

    # enable vhost
    sudo ln -s /etc/httpd/sites-available/$domain_environment.conf /etc/httpd/sites-enabled/$domain_environment.conf

    # configure software
    if [ "$software" = "codeigniter2" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
            fi
            sed -e "s/\$db\['default'\]\['hostname'\]\s=\s'localhost';/\$db\['default'\]\['hostname'\] = '${redhat_mysql_ip}';/g" -e "s/\$db\['default'\]\['username'\]\s=\s'';/\$db\['default'\]\['username'\] = '${mysql_user}';/g" -e "s/\$db\['default'\]\['password'\]\s=\s'';/\$db\['default'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$db\['default'\]\['database'\]\s=\s'';/\$db\['default'\]\['database'\] = '${1}_${domainvaliddbname}';/g" -e "s/\$db\['default'\]\['dbprefix'\]\s=\s'';/\$db\['default'\]\['dbprefix'\] = '${software_dbprefix}';/g" /catapult/provisioners/redhat/installers/codeigniter2_database.php > "/var/www/repositories/apache/${domain}/${webroot}application/config/database.php"
    elif [ "$software" = "drupal6" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            connectionstring="mysql:\/\/${mysql_user}:${mysql_user_password}@${redhat_mysql_ip}\/${1}_${domainvaliddbname}"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/mysql:\/\/username:password@localhost\/databasename/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal6_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            echo -e "\t\trysncing $software ~/sites/default/files/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            fi
            echo "$software core version:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
            echo "$software core-requirements:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
            echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
    elif [ "$software" = "drupal7" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            connectionstring="\$databases['default']['default'] = array('driver' => 'mysql','database' => '${1}_${domainvaliddbname}','username' => '${mysql_user}','password' => '${mysql_user_password}','host' => '${redhat_mysql_ip}','prefix' => '${software_dbprefix}');"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            fi
            sed -e "s/\$databases\s=\sarray();/${connectionstring}/g" /catapult/provisioners/redhat/installers/drupal7_settings.php > "/var/www/repositories/apache/${domain}/${webroot}sites/default/settings.php"
            echo -e "\t\trysncing $software ~/sites/default/files/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/$domain/sites/default/files/ /var/www/repositories/apache/${domain}/${webroot}sites/default/files/ 2>&1 | sed "s/^/\t\t/"
            fi
            echo "$software core version:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-status --field-labels=0 --fields=drupal-version 2>&1 | sed "s/^/\t\t\t/"
            echo "$software core-requirements:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush core-requirements --severity=2 --format=table 2>&1 | sed "s/^/\t\t\t/"
            echo "$software pm-updatestatus:" | sed "s/^/\t\t/"
            cd "/var/www/repositories/apache/${domain}/${webroot}" && drush pm-updatestatus --format=table 2>&1 | sed "s/^/\t\t\t/"
    elif [ "$software" = "wordpress" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}wp-config.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            fi
            sed -e "s/database_name_here/${1}_${domainvaliddbname}/g" -e "s/username_here/${mysql_user}/g" -e "s/password_here/${mysql_user_password}/g" -e "s/localhost/${redhat_mysql_ip}/g" -e "s/'wp_'/'${software_dbprefix}'/g" /catapult/provisioners/redhat/installers/wp-config.php > "/var/www/repositories/apache/${domain}/${webroot}wp-config.php"
            echo -e "\t\trysncing $software ~/wp-content/"
            if ([ "$software_workflow" = "downstream" ] && [ "$1" != "production" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.production.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}wp-content/ /var/www/repositories/apache/${domain}/${webroot}wp-content/ 2>&1 | sed "s/^/\t\t/"
            elif ([ "$software_workflow" = "upstream" ] && [ "$1" != "test" ]); then
                rsync  --archive --compress --copy-links --delete -e "ssh -oStrictHostKeyChecking=no -i /catapult/secrets/id_rsa" root@$(echo "${configuration}" | shyaml get-value environments.test.servers.redhat.ip):/var/www/repositories/apache/${domain}/${webroot}wp-content/ /var/www/repositories/apache/${domain}/${webroot}wp-content/ 2>&1 | sed "s/^/\t\t/"
            fi
            echo "$software core version:" | sed "s/^/\t/\t"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core version 2>&1 | sed "s/^/\t\t\t/"
            echo "$software core verify-checksums:" | sed "s/^/\t\t/"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core verify-checksums 2>&1 | sed "s/^/\t\t\t/"
            echo "$software core check-update:" | sed "s/^/\t\t/"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" core check-update 2>&1 | sed "s/^/\t\t\t/"
            echo "$software plugin list:" | sed "s/^/\t\t/"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" plugin list 2>&1 | sed "s/^/\t\t\t/"
            echo "$software theme list:" | sed "s/^/\t\t/"
            php /catapult/provisioners/redhat/installers/wp-cli.phar --path="/var/www/repositories/apache/${domain}/${webroot}" theme list 2>&1 | sed "s/^/\t\t\t/"
    elif [ "$software" = "xenforo" ]; then
            echo -e "\t\tgenerating $software database configuration file"
            if [ -f "/var/www/repositories/apache/${domain}/${webroot}library/config.php" ]; then
                sudo chmod 0777 "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
            fi
            sed -e "s/\$config\['db'\]\['host'\]\s=\s'localhost';/\$config\['db'\]\['host'\] = '${redhat_mysql_ip}';/g" -e "s/\$config\['db'\]\['username'\]\s=\s'';/\$config\['db'\]\['username'\] = '${mysql_user}';/g" -e "s/\$config\['db'\]\['password'\]\s=\s'';/\$config\['db'\]\['password'\] = '${mysql_user_password}';/g" -e "s/\$config\['db'\]\['dbname'\]\s=\s'';/\$config\['db'\]\['dbname'\] = '${1}_${domainvaliddbname}';/g" /catapult/provisioners/redhat/installers/xenforo_config.php > "/var/www/repositories/apache/${domain}/${webroot}library/config.php"
    fi

done

end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n==> Restarting Apache"
start=$(date +%s)
sudo apachectl stop
sudo apachectl start
sudo apachectl configtest
sudo systemctl is-active httpd.service
end=$(date +%s)
echo "==> completed in ($(($end - $start)) seconds)"


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) total seconds)"


exit 0
