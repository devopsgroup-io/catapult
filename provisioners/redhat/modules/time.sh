source "/catapult/provisioners/redhat/modules/catapult.sh"

# set timezone
sudo timedatectl set-timezone "$(echo "${configuration}" | shyaml get-value company.timezone_redhat)"
# configure the realtime clock
sudo timedatectl --adjust-system-clock set-local-rtc false
# install ntp
sudo yum install -y ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service

echo "> synchronize the hardware clock"
sudo systemctl stop ntpd.service
sudo ntpd -qg
sudo systemctl start ntpd.service

echo "> current hardware clock datetime"
sudo hwclock --debug

echo "> ntp peers"
sudo ntpq -p

echo "> ntp partner"
sudo ntpstat

echo "> current system datetime"
sudo timedatectl status
