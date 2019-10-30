source "/catapult/provisioners/redhat/modules/catapult.sh"

admin_password="$(catapult environments.${1}.software.admin_password)"
redhat1_ip="$(catapult environments.${1}.servers.redhat1.ip_private)"

# install haproxy
# http://www.haproxy.org/download/1.4/doc/configuration.txt
sudo yum install -y haproxy

# configure haproxy
sed --expression="s/admin:admin/admin:${admin_password}/g" /catapult/provisioners/redhat/installers/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg

# configure haproxy backend nodes
if [ ! -z "${redhat1_ip}" ]; then
sudo cat >> /etc/haproxy/haproxy.cfg << EOF
backend backend_http
    balance source
    mode tcp
    server redhat 127.0.0.1:8080 check
    server redhat1 ${redhat1_ip}:8080 check

backend backend_https
    balance source
    mode tcp
    server redhat 127.0.0.1:8081 check
    server redhat1 ${redhat1_ip}:8081 check

EOF
else
sudo cat >> /etc/haproxy/haproxy.cfg << EOF
backend backend_http
    balance source
    mode tcp
    server redhat 127.0.0.1:8080 check

backend backend_https
    balance source
    mode tcp
    server redhat 127.0.0.1:8081 check

EOF
fi

# reload haproxy
sudo systemctl reload haproxy.service

# enable haproxy
sudo systemctl enable haproxy.service
sudo systemctl start haproxy.service
