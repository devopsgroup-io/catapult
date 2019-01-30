source "/catapult/provisioners/redhat/modules/catapult.sh"



echo -e "\n> system authentication configuration"
# install sshd
sudo yum install -y sshd
sudo systemctl enable sshd.service
sudo systemctl start sshd.service
# harden ssh configuration - Fail2Ban also plays a part
# reduce this number "There were 34877 failed login attempts since the last successful login."
echo -e "$(lastb | head -n -2 | wc -l) failed login attempts"
echo -e "$(last | head -n -2 | wc -l) successful login attempts"
sudo last
# only allow authentication via ssh key pair
sed -i -e "/PasswordAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PasswordAuthentication no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nPasswordAuthentication no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/PubkeyAuthentication/d" /etc/ssh/sshd_config
if ! grep -q "PubkeyAuthentication yes" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nPubkeyAuthentication yes" >> /etc/ssh/sshd_config'
fi
# https://cisofy.com/controls/SSH-7408/ - harden ssh configuration
sed -i -e "/ClientAliveCountMax/d" /etc/ssh/sshd_config
if ! grep -q "ClientAliveCountMax 2" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nClientAliveCountMax 2" >> /etc/ssh/sshd_config'
fi
sed -i -e "/MaxSessions/d" /etc/ssh/sshd_config
if ! grep -q "MaxSessions 2" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nMaxSessions 2" >> /etc/ssh/sshd_config'
fi
sed -i -e "/X11Forwarding/d" /etc/ssh/sshd_config
if ! grep -q "X11Forwarding no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nX11Forwarding no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/MaxAuthTries/d" /etc/ssh/sshd_config
if ! grep -q "MaxAuthTries 2" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nMaxAuthTries 2" >> /etc/ssh/sshd_config'
fi
sed -i -e "/LogLevel/d" /etc/ssh/sshd_config
if ! grep -q "LogLevel VERBOSE" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nLogLevel VERBOSE" >> /etc/ssh/sshd_config'
fi
sed -i -e "/ClientAliveInterval/d" /etc/ssh/sshd_config
if ! grep -q "ClientAliveInterval 120" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nClientAliveInterval 120" >> /etc/ssh/sshd_config'
fi
sed -i -e "/ClientAliveCountMax/d" /etc/ssh/sshd_config
if ! grep -q "ClientAliveCountMax 2" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nClientAliveCountMax 2" >> /etc/ssh/sshd_config'
fi
sed -i -e "/TCPKeepAlive/d" /etc/ssh/sshd_config
if ! grep -q "TCPKeepAlive no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nTCPKeepAlive no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/AllowAgentForwarding/d" /etc/ssh/sshd_config
if ! grep -q "AllowAgentForwarding no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nAllowAgentForwarding no" >> /etc/ssh/sshd_config'
fi
sed -i -e "/AllowTcpForwarding/d" /etc/ssh/sshd_config
if ! grep -q "AllowTcpForwarding no" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nAllowTcpForwarding no" >> /etc/ssh/sshd_config'
fi
# https://wiki.centos.org/TipsAndTricks/BannerFiles
banner="
********************************************************************
*                                                                  *
* This system is for the use of authorized users only.  Usage of   *
* this system may be monitored and recorded by system personnel.   *
*                                                                  *
* Anyone using this system expressly consents to such monitoring   *
* and is advised that if such monitoring reveals possible          *
* evidence of criminal activity, system personnel may provide the  *
* evidence from such monitoring to law enforcement officials.      *
*                                                                  *
********************************************************************
"
sudo cat > /etc/issue.net << EOF
${banner}
EOF
sudo cat > /etc/issue << EOF
${banner}
EOF
sed -i -e "/Banner/d" /etc/ssh/sshd_config
if ! grep -q "Banner /etc/issue.net" "/etc/ssh/sshd_config"; then
   sudo bash -c 'echo -e "\nBanner /etc/issue.net" >> /etc/ssh/sshd_config'
fi
# harden file permissions
sudo chmod 0700 /root/.ssh
# reload sshd after configuration changes
sudo systemctl restart sshd.service



echo -e "\n> system email configuration"
# install postfix
sudo yum install -y postfix
sudo systemctl enable postfix.service
sudo systemctl start postfix.service
# prevent a billion emails from localdev
if ([ "${1}" == "dev" ]); then
    sudo cat "/dev/null" > "/root/.forward"
# send root's mail as company email from upstream servers
else
    sudo cat > "/root/.forward" << EOF
    "$(echo "${configuration}" | shyaml get-value company.email)"
EOF
fi
# https://cisofy.com/controls/MAIL-8818/ - hide the mail_name (option: smtpd_banner) from your postfix configuration
sed --in-place --expression="s/^#smtpd_banner\s=\s\$myhostname\sESMTP\s\$mail_name$/smtpd_banner = \$myhostname ESMTP/g" "/etc/postfix/main.cf"
# reload postfix after configuration changes
sudo systemctl reload postfix.service



echo -e "\n> system hostname configuration"
# remove pretty hostname
hostnamectl set-hostname "" --pretty
# configure the hostname
if ([ "${4}" == "apache" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat"
elif ([ "${4}" == "bamboo" ]); then
    hostnamectl set-hostname "$(catapult company.name | tr '[:upper:]' '[:lower:]')-build"
elif ([ "${4}" == "mysql" ]); then
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
# restart if SELinux is enabled
if $(sestatus | grep "SELinux status:" | grep -q "enabled"); then
    echo -e "\n> SELinux is enabled, this is normally due to a fresh install. We need to reboot to disable it, rebooting in 1 minute..."
    if [ $1 = "dev" ]; then
        # required in dev to regain the localdev synced folder
        echo -e "\n> Please run this command: vagrant reload <machine-name> --provision"
    else
        echo -e "\n> Please re-run the provisioner when the machine is back up."
    fi
    /sbin/shutdown --reboot
    sleep 90
fi



echo -e "\n> system control configuration"
# runtime configuraiton
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Performance_Tuning_Guide/s-memory-tunables.html
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
# https://www.kernel.org/doc/Documentation/sysctl/kernel.txt
# This toggle indicates whether restrictions are placed on exposing kernel addresses via /proc and other interfaces.
sudo sysctl kernel.kptr_restrict=2
# https://sites.google.com/site/syscookbook/rhel/rhel-sysrq-key
# It is a 'magical' key combo you can hit which the kernel will respond to regardless of whatever else it is doing, even if the console is unresponsive.
sudo sysctl kernel.sysrq=0
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security_Guide/sect-Security_Guide-Server_Security-Disable-Source-Routing.html
sudo sysctl net.ipv4.conf.all.accept_redirects=0
sudo sysctl net.ipv4.conf.all.log_martians=1
sudo sysctl net.ipv4.conf.all.send_redirects=0
sudo sysctl net.ipv4.conf.default.accept_redirects=0
sudo sysctl net.ipv4.conf.default.log_martians=1
sudo sysctl net.ipv4.tcp_timestamps=0
sudo sysctl net.ipv6.conf.all.accept_redirects=0
sudo sysctl net.ipv6.conf.default.accept_redirects=0

# boot configuration
sudo cat > "/etc/sysctl.d/catapult.conf" << EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.kptr_restrict=2
kernel.sysrq=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.default.log_martians=1
net.ipv4.tcp_timestamps=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF



echo -e "\n> system swap configuration"
# get current swaps
swaps=$(swapon --noheadings --show=NAME)
swap_volumes=$(cat /etc/fstab | grep "swap" | awk '{print $1}')

if ([ "${4}" == "apache" ] || [ "${4}" == "mysql" ]); then

    # create a 256MB swap at /swapfile if it does not exist
    if [[ ! ${swaps[*]} =~ "/swapfile" ]]; then
        echo -e "the swap /swapfile does not exist, creating..."
        sudo dd if=/dev/zero of=/swapfile count=256 bs=1MiB
        sudo chmod 0600 /swapfile
        sudo mkswap /swapfile
    fi
    sudo swapon /swapfile
    # add the swap /swapfile to startup if it does not exist
    if [[ ! ${swap_volumes[*]} =~ "/swapfile" ]]; then
        sudo bash -c 'echo -e "\n/swapfile swap    swap    defaults    0   0" >> /etc/fstab'
    fi

    # create a 512MB swap at /swapfile512 if it does not exist
    if [[ ! ${swaps[*]} =~ "/swapfile512" ]]; then
        echo -e "the swap /swapfile512 does not exist, creating..."
        sudo dd if=/dev/zero of=/swapfile512 count=512 bs=1MiB
        sudo chmod 0600 /swapfile512
        sudo mkswap /swapfile512
    fi
    sudo swapon /swapfile512
    # add the swap /swapfile512 to startup if it does not exist
    if [[ ! ${swap_volumes[*]} =~ "/swapfile512" ]]; then
        sudo bash -c 'echo -e "\n/swapfile512 swap    swap    defaults    0   0" >> /etc/fstab'
    fi

fi

if ([ "${4}" == "bamboo" ]); then

    # create a 768MB swap at /swapfile768 if it does not exist
    if [[ ! ${swaps[*]} =~ "/swapfile768" ]]; then
        echo -e "the swap /swapfile768 does not exist, creating..."
        sudo dd if=/dev/zero of=/swapfile768 count=768 bs=1MiB
        sudo chmod 0600 /swapfile768
        sudo mkswap /swapfile768
    fi
    sudo swapon /swapfile768
    # add the swap /swapfile768 to startup if it does not exist
    if [[ ! ${swap_volumes[*]} =~ "/swapfile768" ]]; then
        sudo bash -c 'echo -e "\n/swapfile768 swap    swap    defaults    0   0" >> /etc/fstab'
    fi

fi

# define the swaps
if ([ "${4}" == "apache" ] || [ "${4}" == "mysql" ]); then
    defined_swaps=("/swapfile" "/swapfile512")
elif ([ "${4}" == "bamboo" ]); then
    defined_swaps=("/swapfile" "/swapfile512" "/swapfile768")
fi
# remove all swaps except the defined swaps
while read -r swap; do
    if [[ ! ${defined_swaps[*]} =~ "${swap}" ]]; then
        echo -e "only the ${defined_swaps[*]} swap files should exist, removing ${swap}..."
        sudo swapoff "${swap}"
    fi
done <<< "${swaps}"
# remove all swap volumes from startup except the defined swaps
while read -r swap_volume; do
    if [[ ! ${defined_swaps[*]} =~ "${swap_volume}" ]]; then
        echo -e "only the ${defined_swaps[*]} swap files should exist, removing ${swap_volume}..."
        # escape slashes for sed
        swap_volume=$(echo -e "${swap_volume}" | sed 's#\/#\\\/#g')
        # remove swap volumes that don't match the defined swaps
        sed --in-place "/${swap_volume}/d" /etc/fstab
    fi
done <<< "${swap_volumes}"

# output the resulting swap
swapon --summary



echo -e "\n> system device configuration"
# disable external devices, prevent unauthorized storage or data theft
# install blocks all loading (ironically) and blacklist still allows drivers to be loaded manually
# modprobe --showconfig
sudo cat > /etc/modprobe.d/catapult-disable.conf << EOF
install firewire_core /bin/true
install firewire_ohci /bin/true
install usb_storage /bin/true
EOF



echo -e "\n> system monitoring configuration"
# new relic servers is no longer available, so until we find an agnostic monir, let's rely on the provider
if ([ "$1" != "dev" ]); then
    curl --silent --show-error --connect-timeout 5 --max-time 5 --location https://agent.digitalocean.com/install.sh | sh
fi



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



echo -e "\n> system additional repositories"
sudo yum install -y epel-release centos-release-scl



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



echo -e "\n> system rpmconf configuration"
# install rpmconf
# rpmconf --debug --clean
# @todo - add to cron to notify of pending conf files
sudo yum -y install rpmconf



echo -e "\n> system arpwatch configuration"
# install arpwatch
sudo yum -y install arpwatch
sudo systemctl enable arpwatch.service
sudo systemctl start arpwatch.service



echo -e "\n> system sysstat configuration"
# install sysstat
# https://github.com/sysstat/sysstat
sudo yum -y install sysstat
sudo systemctl enable sysstat.service
sudo systemctl start sysstat.service
# cat /etc/sysconfig/sysstat



echo -e "\n> system lynis configuration"
# install lynis
sudo yum install -y lynis
# run lynis: lynis audit system --quick



echo -e "\n> system clamav configuration"
# install clamav
sudo yum install -y clamav
# install clamav-update
sudo yum install -y clamav-update
sed --in-place --expression='/^Example/d' /etc/freshclam.conf
sed --in-place --expression="s/^FRESHCLAM_DELAY=disabled-warn/FRESHCLAM_DELAY=disabled/g" /etc/sysconfig/freshclam
