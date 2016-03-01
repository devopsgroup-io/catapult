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

# remove pretty hostname
hostnamectl set-hostname "" --pretty

# set dev hostnames
# @todo set hostnames in upstream servers, will need to align vagrant names, etc
if ([ $1 = "dev" ]); then
    hostnamectl set-hostname "$(echo "${configuration}" | shyaml get-value company.name)-${1}-redhat-${4}"
fi
