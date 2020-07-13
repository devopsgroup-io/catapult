source "/catapult/provisioners/redhat/modules/catapult.sh"

redhat_ip="$(catapult environments.${1}.servers.redhat.ip_private)"

# install nfs-utils
sudo yum install -y nfs-utils

if ([ "$1" != "dev" ]); then

    # remove all nfs shared folder startup entries for non-matched ip entries (redhat could be a new droplet with a new private ip)
    defined_mounts=("${redhat_ip}:/catapult/provisioners/redhat/logs  /catapult/provisioners/redhat/logs   nfs      rw,sync,hard,intr  0     0")
    mounts=$(cat /etc/fstab | grep "/catapult/provisioners/redhat/logs" | awk '{print $1}')
    while read -r mount; do
        if [[ ! ${defined_mounts[*]} =~ "${mount}" ]]; then
            echo -e "only the \"${defined_mounts[*]}\" mounts should exist, removing ${mount}..."
            # escape slashes for sed
            mount=$(echo -e "${mount}" | sed 's#\/#\\\/#g')
            # remove mounts that don't match the defined mounts
            sed --in-place "/${mount}/d" /etc/fstab
        fi
    done <<< "${mounts}"
    defined_mounts=("${redhat_ip}:/catapult/provisioners/redhat/installers/dehydrated/certs  /catapult/provisioners/redhat/installers/dehydrated/certs   nfs      rw,sync,hard,intr  0     0")
    mounts=$(cat /etc/fstab | grep "/catapult/provisioners/redhat/installers/dehydrated/certs" | awk '{print $1}')
    while read -r mount; do
        if [[ ! ${defined_mounts[*]} =~ "${mount}" ]]; then
            echo -e "only the \"${defined_mounts[*]}\" mounts should exist, removing ${mount}..."
            # escape slashes for sed
            mount=$(echo -e "${mount}" | sed 's#\/#\\\/#g')
            # remove mounts that don't match the defined mounts
            sed --in-place "/${mount}/d" /etc/fstab
        fi
    done <<< "${mounts}"
    defined_mounts=("${redhat_ip}:/var/www/repositories/apache  /var/www/repositories/apache   nfs      rw,sync,hard,intr  0     0")
    mounts=$(cat /etc/fstab | grep "/var/www/repositories/apache" | awk '{print $1}')
    while read -r mount; do
        if [[ ! ${defined_mounts[*]} =~ "${mount}" ]]; then
            echo -e "only the \"${defined_mounts[*]}\" mounts should exist, removing ${mount}..."
            # escape slashes for sed
            mount=$(echo -e "${mount}" | sed 's#\/#\\\/#g')
            # remove mounts that don't match the defined mounts
            sed --in-place "/${mount}/d" /etc/fstab
        fi
    done <<< "${mounts}"
    defined_mounts=("${redhat_ip}:/var/www/dehydrated  /var/www/repositories/dehydrated   nfs      rw,sync,hard,intr  0     0")
    mounts=$(cat /etc/fstab | grep "/var/www/repositories/dehydrated" | awk '{print $1}')
    while read -r mount; do
        if [[ ! ${defined_mounts[*]} =~ "${mount}" ]]; then
            echo -e "only the \"${defined_mounts[*]}\" mounts should exist, removing ${mount}..."
            # escape slashes for sed
            mount=$(echo -e "${mount}" | sed 's#\/#\\\/#g')
            # remove mounts that don't match the defined mounts
            sed --in-place "/${mount}/d" /etc/fstab
        fi
    done <<< "${mounts}"

    # create startup entries for mounting nfs shared folders
    mounts=$(cat /etc/fstab | grep "${redhat_ip}" | awk '{print $1}')
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/catapult/provisioners/redhat/logs" ]]; then
        sudo bash -c "echo -e \"\n${redhat_ip}:/catapult/provisioners/redhat/logs  /catapult/provisioners/redhat/logs   nfs      rw,sync,hard,intr  0     0\" >> /etc/fstab"
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/catapult/provisioners/redhat/installers/dehydrated/certs" ]]; then
        sudo bash -c "echo -e \"\n${redhat_ip}:/catapult/provisioners/redhat/installers/dehydrated/certs  /catapult/provisioners/redhat/installers/dehydrated/certs   nfs      rw,sync,hard,intr  0     0\" >> /etc/fstab"
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/var/www/repositories/apache" ]]; then
        sudo bash -c "echo -e \"\n${redhat_ip}:/var/www/repositories/apache  /var/www/repositories/apache   nfs      rw,sync,hard,intr  0     0\" >> /etc/fstab"
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/var/www/dehydrated" ]]; then
        sudo bash -c "echo -e \"\n${redhat_ip}:/var/www/dehydrated  /var/www/dehydrated   nfs      rw,sync,hard,intr  0     0\" >> /etc/fstab"
    fi

    # mount nfs shared folders
    mounts=$(mount | grep "${redhat_ip}" | awk '{print $1}')
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/catapult/provisioners/redhat/logs" ]]; then
        umount /catapult/provisioners/redhat/logs
        rm -rf /catapult/provisioners/redhat/logs
        mkdir -p /catapult/provisioners/redhat/logs
        mount ${redhat_ip}:/catapult/provisioners/redhat/logs /catapult/provisioners/redhat/logs
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/catapult/provisioners/redhat/installers/dehydrated/certs" ]]; then
        umount /catapult/provisioners/redhat/installers/dehydrated/certs
        rm -rf /catapult/provisioners/redhat/installers/dehydrated/certs
        mkdir -p /catapult/provisioners/redhat/installers/dehydrated/certs
        mount ${redhat_ip}:/catapult/provisioners/redhat/installers/dehydrated/certs /catapult/provisioners/redhat/installers/dehydrated/certs
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/var/www/repositories/apache" ]]; then
        umount /var/www/repositories/apache
        rm -rf /var/www/repositories/apache
        mkdir -p /var/www/repositories/apache
        mount ${redhat_ip}:/var/www/repositories/apache /var/www/repositories/apache
    fi
    if [[ ! ${mounts[*]} =~ "${redhat_ip}:/var/www/dehydrated" ]]; then
        umount /var/www/dehydrated
        rm -rf /var/www/dehydrated
        mkdir -p /var/www/dehydrated
        mount ${redhat_ip}:/var/www/dehydrated /var/www/dehydrated
    fi

fi
