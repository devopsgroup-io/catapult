source "/catapult/provisioners/redhat/modules/catapult.sh"

mysql_ip="$(catapult environments.${1}.servers.redhat_mysql.ip_private)"
redhat1_ip="$(catapult environments.${1}.servers.redhat1.ip_private)"

# install nfs-utils
sudo yum install -y nfs-utils

# enable nfs-utils
sudo systemctl enable nfs-server.service
sudo systemctl start nfs-server.service

# configure exports for mysql
if ([ "$1" != "dev" ]); then
    sudo cat > /etc/exports << EOF
/catapult/provisioners/redhat/logs ${mysql_ip}(rw,sync,no_root_squash,no_subtree_check)
/catapult/provisioners/redhat/installers/dehydrated/certs ${mysql_ip}(rw,sync,no_root_squash,no_subtree_check)
/var/www/repositories/apache ${mysql_ip}(rw,sync,no_root_squash,no_subtree_check)
EOF
fi
# configure exports for apache-node
if ([ "$1" != "dev" ] && [ ! -z "${redhat1_ip}" ]); then
    sudo cat >> /etc/exports << EOF
/catapult/provisioners/redhat/logs ${redhat1_ip}(rw,sync,no_root_squash,no_subtree_check)
/catapult/provisioners/redhat/installers/dehydrated/certs ${redhat1_ip}(rw,sync,no_root_squash,no_subtree_check)
/var/www/repositories/apache ${redhat1_ip}(rw,sync,no_root_squash,no_subtree_check)
EOF
fi

# reload exports
exportfs -ra
