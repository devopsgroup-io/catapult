redhat_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat.ip)"

# remove all rules
sudo iptables --flush
# allow server/client ssh over 22
sudo iptables\
    --append INPUT\
    --protocol tcp\
    --dport 22\
    --jump ACCEPT
sudo iptables\
    --append OUTPUT\
    --protocol tcp\
    --sport 22\
    --jump ACCEPT
# allow server to use 127.0.0.1 or localhost, lo = loopback interface
sudo iptables\
    --append INPUT\
    --in-interface lo\
    --jump ACCEPT
sudo iptables\
    --append OUTPUT\
    --out-interface lo\
    --jump ACCEPT
# allow server to access the web for packages, updates, etc
sudo iptables\
    --append OUTPUT\
    --out-interface eth0\
    --destination 0.0.0.0/0\
    --jump ACCEPT
sudo iptables\
    --append INPUT\
    --in-interface eth0\
    --match state\
    --state ESTABLISHED,RELATED\
    --jump ACCEPT
# allow for outbound mail
sudo iptables\
    -append OUTPUT\
    --protocol tcp\
    --dport 25\
    --jump ACCEPT
# allow incoming web traffic from the world
if [ "${4}" == "apache" ]; then
    sudo iptables\
        --append INPUT\
        --in-interface eth0\
        --protocol tcp\
        --dport 80\
        --match state\
        --state NEW,ESTABLISHED\
        --jump ACCEPT
    sudo iptables\
        --append OUTPUT\
        --out-interface eth0\
        --protocol tcp\
        --sport 80\
        --match state\
        --state ESTABLISHED\
        --jump ACCEPT
# allow incoming database traffic
elif [ "${4}" == "mysql" ]; then
    if [ "${1}" == "dev"  ]; then
        # from developer machine
        sudo iptables\
            --append INPUT\
            --in-interface eth0\
            --protocol tcp\
            --dport 3306\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
        sudo iptables\
            --append OUTPUT\
            --out-interface eth0\
            --protocol tcp\
            --sport 3306\
            --match state\
            --state ESTABLISHED\
            --jump ACCEPT
    else
        # from the redhat server
        sudo iptables\
            --append INPUT\
            --in-interface eth0\
            --protocol tcp\
            --dport 3306\
            --source ${redhat_ip}\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
        sudo iptables\
            --append OUTPUT\
            --out-interface eth0\
            --protocol tcp\
            --destination ${redhat_ip}\
            --sport 3306\
            --match state\
            --state ESTABLISHED\
            --jump ACCEPT
    fi
fi

# now that everything is configured, we drop everything else (drop does not send any return packets, reject does)
sudo iptables --policy FORWARD DROP
sudo iptables --policy INPUT DROP
sudo iptables --policy OUTPUT DROP
# output the iptables
sudo iptables --list
