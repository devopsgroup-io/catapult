source "/catapult/provisioners/redhat/modules/catapult.sh"


# IPTABLES CONFIGURATION
echo -e "\n> configuring iptables-services"

# disable the baked in firewalld
sudo systemctl stop firewalld
sudo systemctl mask firewalld

# install the iptables-services
sudo yum install -y iptables-services

# start iptables service
sudo systemctl start iptables

# ensure iptables starts during boot
sudo systemctl enable iptables



# IPTABLES RULES BEFORE
echo -e "\n> iptables rules before configuration"

# output the iptables
sudo iptables --list-rules



# IPTABLES RULES CONFIGURATION
echo -e "\n> iptables rules configuration"

# establish default policies
sudo iptables --policy INPUT ACCEPT
sudo iptables --policy FORWARD ACCEPT
sudo iptables --policy OUTPUT ACCEPT
# remove all rules
sudo iptables --flush
# we're not a router
sudo iptables --policy FORWARD DROP
# allow all output, only filter input
sudo iptables --policy OUTPUT ACCEPT

# allow server/client ssh over 22
sudo iptables\
    --append INPUT\
    --protocol tcp\
    --dport 22\
    --jump ACCEPT
# allow server to use 127.0.0.1 or localhost, lo = loopback interface
sudo iptables\
    --append INPUT\
    --in-interface lo\
    --jump ACCEPT
# allow server to access the web for packages, updates, etc
sudo iptables\
    --append INPUT\
    --match state\
    --state ESTABLISHED,RELATED\
    --jump ACCEPT
# allow ntp over 123
sudo iptables\
    --append INPUT\
    --protocol udp\
    --dport 123\
    --jump ACCEPT
# allow incoming web traffic from the world
if [ "${4}" == "apache" ]; then
    sudo iptables\
        --append INPUT\
        --protocol tcp\
        --dport 80\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
    sudo iptables\
        --append INPUT\
        --protocol tcp\
        --dport 443\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
# allow incoming traffic for bamboo
elif [ "${4}" == "bamboo" ]; then
    sudo iptables\
        --append INPUT\
        --protocol tcp\
        --dport 80\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
    sudo iptables\
        --append INPUT\
        --protocol tcp\
        --dport 443\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
    sudo iptables\
        --append INPUT\
        --protocol tcp\
        --dport 8085\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
# allow incoming database traffic
elif [ "${4}" == "mysql" ]; then
    # allow any connection from the developer workstation
    if [ "${1}" == "dev"  ]; then
        sudo iptables\
            --append INPUT\
            --protocol tcp\
            --dport 3306\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
    # restrict incoming connection only from redhat private interface
    else
        redhat_ip="$(catapult environments.${1}.servers.redhat.ip_private)"
        sudo iptables\
            --append INPUT\
            --protocol tcp\
            --dport 3306\
            --source ${redhat_ip}\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
    fi
fi

# now that everything is configured, we drop everything else (drop does not send any return packets, reject does)
sudo iptables --policy INPUT DROP

# save our newly created config
# saves to cat /etc/sysconfig/iptables
sudo service iptables save

# restart iptables service
sudo systemctl restart iptables



# IPTABLES RULES CONFIGURATION
echo -e "\n> fail2ban service configuration and fail2ban jail/filter configuration"

# install fail2ban
sudo yum install -y fail2ban

# ensure fail2ban starts during boot
sudo systemctl enable fail2ban

# define our fail2ban jails
# see cron_security.sh for more information
sudo cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
banaction = iptables-multiport
# "bantime" is the number of seconds that a host is banned.
bantime  = 3600
# a host is banned if it has generated "maxretry" during the last "findtime" seconds.
findtime  = 600
# "maxretry" is the number of failures before a host get banned.
maxretry = 5

[sshd]
enabled = true

EOF

# restart fail2ban
sudo systemctl restart fail2ban

# output the fail2ban jails
sudo fail2ban-client status



# IPTABLES RULES AFTER
echo -e "\n> iptables rules after configuration"

# output the iptables
sudo iptables --list-rules
