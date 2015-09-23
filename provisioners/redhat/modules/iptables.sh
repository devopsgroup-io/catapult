if [ "${1}" == "dev" ]; then
    redhat_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat.ip)"
else
    redhat_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat.ip_private)"
fi

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
# allow incoming database traffic
elif [ "${4}" == "mysql" ]; then
    if [ "${1}" == "dev"  ]; then
        # from developer machine
        sudo iptables\
            --append INPUT\
            --protocol tcp\
            --dport 3306\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
    else
        # from the redhat server
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
# output the iptables
sudo iptables --list-rules
