source "/catapult/provisioners/redhat/modules/catapult.sh"

redhat1_ip="$(catapult environments.${1}.servers.redhat1.ip_private)"

# install nfs-utils
sudo yum install -y nfs-utils

# enable nfs-utils
sudo systemctl enable nfs-server.service
sudo systemctl start nfs-server.service

# configure exports
if ([ "$1" != "dev" ] && [ ! -z "${redhat1_ip}" ]); then
sudo cat > /etc/exports << EOF
/var/www/repositories/apache ${redhat1_ip}(ro,sync,no_root_squash,no_subtree_check)
/catapult/provisioners/redhat/installers/dehydrated/certs ${redhat1_ip}(ro,sync,no_root_squash,no_subtree_check)
EOF
fi

# reload exports
exportfs -ra
