#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance



echo -e "\n\n\n==> Updating existing packages and installing utilities"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/system.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Configuring IPTables"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/iptables.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Configuring time"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/time.sh
provisionstart=$(date +%s)
sudo touch /catapult/provisioners/redhat/logs/apache.log
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Installing software tools"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/software_tools.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Configuring git repositories (This may take a while...)"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/git.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> RSyncing files"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/rsync.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Generating software database config files"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/software_database_config.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Configuring Apache"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/apache.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


echo -e "\n\n\n==> Configuring CloudFlare"
start=$(date +%s)
source /catapult/provisioners/redhat/modules/cloudflare.sh
end=$(date +%s)
echo -e "\n==> completed in ($(($end - $start)) seconds)"


provisionend=$(date +%s)
echo -e "\n\n==> Provision complete ($(($provisionend - $provisionstart)) total seconds)"


exit 0
