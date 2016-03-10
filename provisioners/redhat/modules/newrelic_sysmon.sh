source "/catapult/provisioners/redhat/modules/catapult.sh"

# add the new relic yum repository
rpm --hash --upgrade --verbose https://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm

# install the server monitor package
sudo yum install -y newrelic-sysmond
# configure & start the server monitor daemon
nrsysmond-config --set license_key=$(catapult company.newrelic_license_key)
# ensure newrelic sysmon daemon is started with latest configuration
/etc/init.d/newrelic-sysmond start
/etc/init.d/newrelic-sysmond reload
/etc/init.d/newrelic-sysmond status
tail /var/log/newrelic/nrsysmond.log
