#!/bin/bash

# for low memory machines, bamboo needs a kick every so often
response=$(/bin/curl --connect-timeout 30 --max-time 30 --head --output /dev/null --retry 0 --silent --write-out '%{http_code}\n' --location --url http://127.0.0.1)
if [ ${response} -eq 000 ]; then
	sudo systemctl stop bamboo
	pkill -9 java
	sudo systemctl start bamboo
fi

# pull the latest catapult on a daily basis but hide the output
cd /catapult && /usr/bin/git pull > /dev/null 2>/dev/null

#@todo automatic updates to bamboo
