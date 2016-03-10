source "/catapult/provisioners/redhat/modules/catapult.sh"

# add the new relic yum repository
rpm --hash --upgrade --verbose https://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm

# install the apm php package
sudo yum install -y newrelic-php5
# set the apm php appname
sed -i -e "s#newrelic\.appname.*#newrelic.appname = \"$(catapult company.name)-${1}-redhat\"#g" "/etc/php.d/newrelic.ini"
# apm php installed but license key does not match
NR_INSTALL_SILENT="true", NR_INSTALL_KEY="$(catapult company.newrelic_license_key)" /usr/bin/newrelic-install install
# ensure newrelic daemon is started with latest configuration
/etc/init.d/newrelic-daemon start
/etc/init.d/newrelic-daemon reload
/etc/init.d/newrelic-daemon status
tail /var/log/newrelic/newrelic-daemon.log
tail /var/log/newrelic/php_agent.log
# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
