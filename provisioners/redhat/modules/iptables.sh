redhat_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat.ip)"
redhat_mysql_ip="$(echo "${configuration}" | shyaml get-value environments.${1}.servers.redhat_mysql.ip)"

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

if [ "${4}" == "apache" ]; then
    # allow incoming web traffic from the world
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
elif [ "${4}" == "mysql" ]; then
    if [ "${1}" == "dev"  ]; then
        # allow incoming database traffic from developer machine
        sudo iptables\
            --append INPUT\
            --in-interface eth0\
            --protocol tcp\
            --dport 3306\
            --sport 3306\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
        sudo iptables\
            --append OUTPUT\
            --out-interface eth0\
            --protocol tcp\
            --dport 3306\
            --sport 3306\
            --match state\
            --state ESTABLISHED\
            --jump ACCEPT
    else
        # allow incoming database traffic from the redhat server
        sudo iptables\
            --append INPUT\
            --in-interface eth0\
            --protocol tcp\
            --destination ${redhat_mysql_ip}\
            --dport 3306\
            --source ${redhat_ip}\
            --sport 3306\
            --match state\
            --state NEW,ESTABLISHED\
            --jump ACCEPT
        sudo iptables\
            --append OUTPUT\
            --out-interface eth0\
            --protocol tcp\
            --destination ${redhat_ip}\
            --dport 3306\
            --source ${redhat_mysql_ip}\
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

