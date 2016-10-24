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

bash /usr/local/src/bamboo/atlassian-bamboo-5.13.2/bin/start-bamboo.sh
