source "/catapult/provisioners/redhat/modules/catapult.sh"



echo -e "\n> system authentication configuration"
# install sshd
sudo yum install -y sshd
sudo systemctl enable sshd.service
sudo systemctl start sshd.service
# only allow authentication via ssh key pair
# assist this number - There were 34877 failed login attempts since the last successful login.
echo -e "$(lastb | head -n -2 | wc -l) failed login attempts"
echo -e "$(last | head -n -2 | wc -l) successful login attempts"
sudo last
sed -i -e "/PasswordAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nPasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/PubkeyAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PubkeyAuthentication yes" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nPubkeyAuthentication yes" >> /etc/ssh/sshd_config'
fi
sudo systemctl reload sshd.service



echo -e "\n> system email configuration"
# prevent a billion emails from localdev
if ([ "${1}" = "dev" ]); then
    sudo cat "/dev/null" > "/root/.forward"
# send root's mail as company email from upstream servers
else
    sudo cat > "/root/.forward" << EOF
    "$(echo "${configuration}" | shyaml get-value company.email)"
EOF
fi



echo -e "\n> system hostname configuration"
# remove pretty hostname
hostnamectl set-hostname "" --pretty

# configure the hostname
if ([ "${4}" = "apache" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat"
elif ([ "${4}" = "bamboo" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-build"
elif ([ "${4}" = "mysql" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat-mysql"
fi



echo -e "\n> system SELinux configuration"
sudo cat > /etc/sysconfig/selinux << EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF
sestatus -v



echo -e "\n> system swap configuration"
# get current swaps
swaps=$(swapon --noheadings --show=NAME)
swap_volumes=$(cat /etc/fstab | grep "swap" | awk '{print $1}')

# remove all swaps except /swapfile
while read -r swap; do
    if [ "${swap}" != "/swapfile" ]; then
        echo -e "only the /swapfile should exist, removing ${swap}..."
        sudo swapoff "${swap}"
    fi
done <<< "${swaps}"

# remove all swap volumes from startup except /swapfile
while read -r swap_volume; do
    if [ "${swap_volume}" != "/swapfile" ]; then
        echo -e "only the /swapfile should exist, removing ${swap_volume}..."
        # escape slashes for sed
        swap_volume=$(echo -e "${swap_volume}" | sed 's#\/#\\\/#g')
        # remove swap volumes that don't match /swapfile
        sed --in-place "/${swap_volume}/d" /etc/fstab
    fi
done <<< "${swap_volumes}"

# create the swap /swapfile if it does not exist
if [[ ! ${swaps[*]} =~ "/swapfile" ]]; then
    echo -e "the swap /swapfile does not exist, creating..."
    sudo dd if=/dev/zero of=/swapfile count=256 bs=1MiB
    sudo chmod 0600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
fi

# add the swap /swapfile to startup
if [[ ! ${swap_volumes[*]} =~ "/swapfile" ]]; then
    sudo bash -c 'echo -e "\n/swapfile swap    swap    defaults    0   0" >> /etc/fstab'
fi

# output the resulting swap
swapon --summary

# tune the swap temporarily for runtime
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Performance_Tuning_Guide/s-memory-tunables.html
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50

# tune the swap permanently for boot
sudo cat > "/etc/sysctl.d/catapult.conf" << EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF



echo -e "\n> system known hosts configuration"
# initialize known_hosts
sudo mkdir -p ~/.ssh
sudo touch ~/.ssh/known_hosts

# ssh-keyscan bitbucket.org for a maximum of 10 tries
i=0
until [ $i -ge 10 ]; do
    sudo ssh-keyscan -4 -T 10 bitbucket.org > ~/.ssh/known_hosts
    if grep -q "bitbucket\.org" ~/.ssh/known_hosts; then
        echo "ssh-keyscan for bitbucket.org successful"
        break
    else
        echo "ssh-keyscan for bitbucket.org failed, retrying!"
    fi
    i=$[$i+1]
done

# ssh-keyscan github.com for a maximum of 10 tries
i=0
until [ $i -ge 10 ]; do
    sudo ssh-keyscan -4 -T 10 github.com >> ~/.ssh/known_hosts
    if grep -q "github\.com" ~/.ssh/known_hosts; then
        echo "ssh-keyscan for github.com successful"
        break
    else
        echo "ssh-keyscan for github.com failed, retrying!"
    fi
    i=$[$i+1]
done



echo -e "\n> system yum-cron configuration"
# install yum-cron to apply updates nightly
sudo yum install -y yum-cron
sudo systemctl enable yum-cron.service
sudo systemctl start yum-cron.service
# auto download updates
sudo sed --in-place --expression='/^download_updates\s=/s|.*|download_updates = yes|' /etc/yum/yum-cron.conf
# auto apply updates
sudo sed --in-place --expression='/^apply_updates\s=/s|.*|apply_updates = yes|' /etc/yum/yum-cron.conf
# do not send any messages to stdout or email
sudo sed --in-place --expression='/^emit_via\s=/s|.*|emit_via = None|' /etc/yum/yum-cron.conf
# restart the service to re-read any new configuration
sudo systemctl restart yum-cron.service



echo -e "\n> system cron configuration"
# configure a weekly job to reboot the system if necessary
touch /etc/cron.weekly/catapult-reboot.cron
cat /catapult/provisioners/redhat/modules/system_reboot.sh > /etc/cron.weekly/catapult-reboot.cron
chmod 755 /etc/cron.weekly/catapult-reboot.cron
