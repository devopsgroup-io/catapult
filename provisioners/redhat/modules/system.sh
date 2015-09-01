# only allow authentication via ssh key pair
# suppress this - There were 34877 failed login attempts since the last successful login.
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sudo systemctl stop sshd.service
sudo systemctl start sshd.service

# update packages
sudo yum update -y

# parse yaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
configuration=$(gpg --batch --passphrase ${3} --decrypt /catapult/secrets/configuration.yml.gpg)
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa --decrypt /catapult/secrets/id_rsa.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa.pub --decrypt /catapult/secrets/id_rsa.pub.gpg

# ssh keys are required to be 700
chmod 700 /catapult/secrets/id_rsa
chmod 700 /catapult/secrets/id_rsa.pub

# send root's mail as company email
sudo cat > "/root/.forward" << EOF
"$(echo "${configuration}" | shyaml get-value company.email)"
EOF

# send an email with catapult stack
if [ "$1" != "dev" ]; then
    sudo touch /tmp/email.txt
    sudo echo -e "Subject: Catapult \($(echo "${configuration}" | shyaml get-value company.name)\) - ${1} Environment Update" >> /tmp/email.txt
    echo "${configuration}" | shyaml get-values-0 websites.apache |
    while IFS='' read -r -d '' key; do
        domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
        domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
        if [ ! -z "${domain_tld_override}" ]; then
            domain_root="${1}.${domain}.${domain_tld_override}"
        else
            domain_root="${1}.${domain}"
        fi
        force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
        force_auth_exclude=$(echo "$key" | grep -w "force_auth_exclude" | tr -d " ")
        sudo echo -e "domain: ${domain_root}" >> /tmp/email.txt
        sudo echo -e "force_auth: ${force_auth}" >> /tmp/email.txt
        sudo echo -e "force_auth_exclude: ${force_auth_exclude}" >> /tmp/email.txt
        sudo echo -e "\n"
    done
    sendmail -F"Catapult" "$(echo "${configuration}" | shyaml get-value company.email)" < /tmp/email.txt
    sudo cat /dev/null > /tmp/email.txt
fi
