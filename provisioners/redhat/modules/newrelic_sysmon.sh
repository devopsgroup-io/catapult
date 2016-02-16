source "/catapult/provisioners/redhat/modules/catapult.sh"

# add the new relic yum repository
rpm --hash --upgrade --verbose https://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm

# install the server monitor package
sudo yum install -y newrelic-sysmond
# configure & start the server monitor daemon
nrsysmond-config --set license_key=$(catapult company.newrelic_license_key)
# start the server monitor daemon
/etc/init.d/newrelic-sysmond start
