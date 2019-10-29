source "/catapult/provisioners/redhat/modules/catapult.sh"

admin_password="$(catapult environments.${1}.software.admin_password)"
backend_http_redhat1="$(catapult environments.${1}.servers.redhat1.ip_private)"
backend_https_redhat1="$(catapult environments.${1}.servers.redhat1.ip_private)"

# install haproxy
sudo yum install -y haproxy

# configure haproxy
sed --expression="s/admin:admin/admin:${admin_password}/g" \
    --expression="s/backend_http_redhat1/${backend_http_redhat1}/g" \
    --expression="s/backend_https_redhat1/${backend_https_redhat1}/g" \
    /catapult/provisioners/redhat/installers/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg

# reload haproxy
sudo systemctl reload haproxy.service

# enable haproxy
sudo systemctl enable haproxy.service
sudo systemctl start haproxy.service
