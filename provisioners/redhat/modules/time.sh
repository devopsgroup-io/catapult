source "/catapult/provisioners/redhat/modules/catapult.sh"

# set timezone
sudo timedatectl set-timezone "$(echo "${configuration}" | shyaml get-value company.timezone_redhat)"
# install ntp
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service

echo "> ntp peers"
ntpq -p

echo "> ntp partner"
ntpstat

echo "> current datetime"
timedatectl status
