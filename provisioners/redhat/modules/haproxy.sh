source "/catapult/provisioners/redhat/modules/catapult.sh"

admin_password="$(catapult environments.${1}.software.admin_password)"

# install haproxy
sudo yum install -y haproxy

# configure haproxy
sed --expression="s/admin:admin/admin:${admin_password}/g" \
    /catapult/provisioners/redhat/installers/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg

# reload haproxy
sudo systemctl reload haproxy.service

# enable haproxy
sudo systemctl enable haproxy.service
sudo systemctl start haproxy.service
