source "/catapult/provisioners/redhat/modules/catapult.sh"

# only allow authentication via ssh key pair
# assist this number - There were 34877 failed login attempts since the last successful login.
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

# configure the hostname
if ([ "${4}" = "apache" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat"
elif ([ "${4}" = "mysql" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat-${4}"
fi



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
    sudo bash -c 'echo "/swapfile swap    swap    defaults    0   0" >> /etc/fstab'
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



# initialize known_hosts
sudo mkdir -p ~/.ssh
sudo touch ~/.ssh/known_hosts

# ssh-keyscan bitbucket.org for a maximum of 10 tries
i=0
until [ $i -ge 10 ]; do
    sudo ssh-keyscan bitbucket.org > ~/.ssh/known_hosts
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
    sudo ssh-keyscan github.com >> ~/.ssh/known_hosts
    if grep -q "github\.com" ~/.ssh/known_hosts; then
        echo "ssh-keyscan for github.com successful"
        break
    else
        echo "ssh-keyscan for github.com failed, retrying!"
    fi
    i=$[$i+1]
done
