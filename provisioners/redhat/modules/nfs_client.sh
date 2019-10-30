source "/catapult/provisioners/redhat/modules/catapult.sh"

redhat_ip="$(catapult environments.${1}.servers.redhat.ip_private)"

# install nfs-utils
sudo yum install -y nfs-utils

# mount shared folder
if ([ "$1" != "dev" ]); then
    mkdir -p /var/www/repositories/apache
    mount ${redhat_ip}:/var/www/repositories/apache /var/www/repositories/apache
fi
