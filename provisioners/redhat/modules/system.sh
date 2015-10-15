source "/catapult/provisioners/redhat/modules/catapult.sh"

# only allow authentication via ssh key pair
# suppress this - There were 34877 failed login attempts since the last successful login.
echo -e "$(lastb | head -n -2 | wc -l) failed login attempts"
echo -e "$(last | head -n -2 | wc -l) successful login attempts"
sudo last
sed -i -e "/PasswordAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/PubkeyAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PubkeyAuthentication yes" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config'
fi
sudo systemctl reload sshd.service

# send root's mail as company email
sudo cat > "/root/.forward" << EOF
"$(echo "${configuration}" | shyaml get-value company.email)"
EOF

# send an email with catapult stack
if [ "$1" = "production" ]; then
    sudo touch /tmp/email.txt
    sudo echo -e "Subject: Catapult ($(echo "${configuration}" | shyaml get-value company.name)) - Environment Update" >> /tmp/email.txt
    sudo echo -e "\n" >> /tmp/email.txt
    echo "${configuration}" | shyaml get-values-0 websites.apache |
    while IFS='' read -r -d '' key; do
        domain=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
        domain_tld_override=$(echo "$key" | grep -w "domain_tld_override" | cut -d ":" -f 2 | tr -d " ")
        if [ ! -z "${domain_tld_override}" ]; then
            domain_root="${domain}.${domain_tld_override}"
        else
            domain_root="${domain}"
        fi
        force_auth=$(echo "$key" | grep -w "force_auth" | cut -d ":" -f 2 | tr -d " ")
        force_auth_exclude=$(echo "$key" | grep -w "force_auth_exclude" | tr -d " ")
        if ([ ! -z "${force_auth_exclude}" ]); then
            force_auth_excludes=( $(echo "${key}" | shyaml get-values force_auth_exclude) )
        else
            force_auth_excludes=""
        fi
        sudo echo -e "domain: ${domain}" >> /tmp/email.txt
        sudo echo -e "http://dev.${domain_root}" >> /tmp/email.txt
        sudo echo -e "http://test.${domain_root}" >> /tmp/email.txt
        sudo echo -e "http://qc.${domain_root}" >> /tmp/email.txt
        sudo echo -e "http://${domain_root}" >> /tmp/email.txt
        sudo echo -e "force_auth: ${force_auth}" >> /tmp/email.txt
        sudo echo -e "force_auth_exclude: ${force_auth_excludes}" >> /tmp/email.txt
        sudo echo -e "\n" >> /tmp/email.txt
    done
    sudo echo -e "\n" >> /tmp/email.txt
    sudo echo -e "https://devopsgroup.io/" >> /tmp/email.txt
    sendmail -F"Catapult" "$(echo "${configuration}" | shyaml get-value company.email)" < /tmp/email.txt
    sudo cat /dev/null > /tmp/email.txt
fi
