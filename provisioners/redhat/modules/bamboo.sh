# define our bamboo version
bamboo_version="5.15.3"

# install java
sudo yum install -y java-1.8.0-openjdk-devel.x86_64 
java -version

# if the defined bamboo versin is not installed, download and install
if [ ! -d /usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/atlassian-bamboo ]; then

    mkdir --parents /usr/local/src/bamboo
    cd /usr/local/src/bamboo
    
    curl --silent --show-error --connect-timeout 5 --output bamboo.tar.gz --retry 5 --location --url https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${bamboo_version}.tar.gz

    tar -xzf bamboo.tar.gz

fi

mkdir --parents /usr/local/src/bamboo/atlassian-bamboo
sudo cat > "/usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties" << EOF
    bamboo.home=/usr/local/src/bamboo/atlassian-bamboo
EOF

# run bamboo as port 80
sed --in-place 's/:8085//g' /usr/local/src/bamboo/atlassian-bamboo/xml-data/configuration/administration.xml
sed --in-place 's/port="8085"/port="80"/g' /usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/conf/server.xml

# increase jvm maximum memory
sed --in-place 's/JVM_MAXIMUM_MEMORY="1024m"/JVM_MAXIMUM_MEMORY="2048m"/g' /usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/bin/setenv.sh
bash /usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/bin/setenv.sh

# run bamboo as as service
# https://confluence.atlassian.com/bamboo/running-bamboo-as-a-linux-service-416056046.html
sudo cat "/catapult/provisioners/redhat/installers/bamboo/bamboo.sh" > "/etc/init.d/bamboo"
# make the bamboo init script executable
chmod a+x /etc/init.d/bamboo
# add the bamboo init script to systemctl
sudo /sbin/chkconfig --add bamboo
# enable bamboo on startup
sudo systemctl enable bamboo
# start bamboo
#bash /usr/local/src/bamboo/atlassian-bamboo-${bamboo_version}/bin/start-bamboo.sh
sudo systemctl start bamboo

# sleep a few seconds to allow start-bamboo.sh to start
sleep 5
# confirm that bamboo has started, the first start can expect a 5-10 minute delay 
response=0
until [ $response -eq 200 ]; do
    response=$(curl --connect-timeout 30 --max-time 30 --head --output /dev/null --retry 0 --silent --write-out '%{http_code}\n' --location --url http://127.0.0.1)
    echo "$(date) waiting for Bamboo to start, checking every 30 seconds (a fresh install takes about 5 minutes startup time)..."
    if [ ${response} -eq 000 ]; then
      sleep 30
    fi
done
echo "Bamboo successfully started"

# echo out configuration, which includes the IP address of the bamboo instance
cat /usr/local/src/bamboo/atlassian-bamboo/bamboo.cfg.xml
