sudo yum install -y java-1.8.0-openjdk-devel.x86_64 
java -version

if [ ! -d /usr/local/src/bamboo/atlassian-bamboo-5.13.2/atlassian-bamboo ]; then

    mkdir --parents /usr/local/src/bamboo
    cd /usr/local/src/bamboo
    
    curl --silent --show-error --connect-timeout 5 --output bamboo.tar.gz --retry 5 --location --url https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-5.13.2.tar.gz

    tar -xzf bamboo.tar.gz

fi

mkdir --parents /usr/local/src/bamboo/atlassian-bamboo
sudo cat > "/usr/local/src/bamboo/atlassian-bamboo-5.13.2/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties" << EOF
    bamboo.home=/usr/local/src/bamboo/atlassian-bamboo
EOF

# run bamboo as port 80
sed --in-place 's/:8085//g' /usr/local/src/bamboo/atlassian-bamboo/xml-data/configuration/administration.xml
sed --in-place 's/port="8085"/port="80"/g' /usr/local/src/bamboo/atlassian-bamboo-5.13.2/conf/server.xml

# run bamboo as as service
# https://confluence.atlassian.com/bamboo/running-bamboo-as-a-linux-service-416056046.html
sudo cat > "/etc/init.d/bamboo" << EOF
#!/bin/sh
set -e
### BEGIN INIT INFO
# Provides: bamboo
# Required-Start: $local_fs $remote_fs $network $time
# Required-Stop: $local_fs $remote_fs $network $time
# Should-Start: $syslog
# Should-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Atlassian Bamboo Server
### END INIT INFO
# INIT Script
######################################

# Define some variables
# Name of app ( bamboo, Confluence, etc )
APP=bamboo
# Name of the user to run as
USER=root
# Location of application's bin directory
BASE=/usr/local/src/bamboo/atlassian-bamboo-5.13.2

case "$1" in
  # Start command
  start)
    echo "Starting $APP"
    /bin/su - $USER -c "export BAMBOO_HOME=${BAMBOO_HOME}; $BASE/bin/start-bamboo.sh &> /dev/null"
    ;;
  # Stop command
  stop)
    echo "Stopping $APP"
    /bin/su - $USER -c "$BASE/bin/shutdown.sh &> /dev/null"
    echo "$APP stopped successfully"
    ;;
   # Restart command
   restart)
        $0 stop
        sleep 5
        $0 start
        ;;
  *)
    echo "Usage: /etc/init.d/$APP {start|restart|stop}"
    exit 1
    ;;
esac

exit 0
EOF
# make the bamboo init script executable
chmod a+x /etc/init.d/bamboo
# add the bamboo init script to systemctl
sudo /sbin/chkconfig --add bamboo
# enable bamboo on startup
sudo systemctl enable bamboo
# start bamboo
#bash /usr/local/src/bamboo/atlassian-bamboo-5.13.2/bin/start-bamboo.sh
sudo systemctl start bamboo

# sleep a few seconds to allow start-bamboo.sh to start
sleep 5
# confirm that bamboo has started, the first start can expect a 5-10 minute delay 
response=0
until [ $response -eq 200 ]; do
    response=$(curl --connect-timeout 30 --max-time 30 --head --output /dev/null --retry 0 --silent --write-out '%{http_code}\n' --location --url http://127.0.0.1)
    echo "$(date) waiting for Bamboo to start, checking every 30 seconds (a fresh install takes about 5 minutes startup time)..."
done
echo "Bamboo successfully started"

# echo out configuration, which includes the IP address of the bamboo instance
cat /usr/local/src/bamboo/atlassian-bamboo/bamboo.cfg.xml
