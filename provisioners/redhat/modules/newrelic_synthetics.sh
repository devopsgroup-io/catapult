source "/catapult/provisioners/redhat/modules/catapult.sh"

# get a list of monitors
newrelic_monitors=$(curl --silent --show-error --connect-timeout 10 --max-time 20 --write-out "HTTPSTATUS:%{http_code}" --request GET "https://synthetics.newrelic.com/synthetics/api/v1/monitors" \
--header "X-Api-Key: $(catapult company.newrelic_admin_api_key)")
newrelic_monitors_status=$(echo "${newrelic_monitors}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
newrelic_monitors=$(echo "${newrelic_monitors}" | sed -e 's/HTTPSTATUS\:.*//g')

# check for a curl error
if [ $newrelic_monitors_status == 000 ]; then

    echo "there was a problem with the new relic admin api request - please visit https://status.newrelic.com/ to see if there is a problem"

else

    # get number of monitors (poor man's loop)
    monitor_count=$(echo "${newrelic_monitors}" | python -c 'import json,sys;object=json.load(sys.stdin);print len(object["monitors"])')

    # if the monitor exists, update
    i=0
    monitor_exists=false
    until [ $i -ge $monitor_count ]; do
        monitor_uri=$(echo "${newrelic_monitors}" | python -c "import json,sys;object=json.load(sys.stdin);print object[\"monitors\"][${i}][\"uri\"]")
        if echo "${monitor_uri}" | grep --quiet "http://$(catapult websites.apache.$5.domain).*"; then
 
            # set a monitor_exists variable so we know not to create one
            monitor_exists=true
            echo "synthetic monitor exists, updating..."

            # get the id of the monitor          
            monitor_id=$(echo "${newrelic_monitors}" | python -c "import json,sys;object=json.load(sys.stdin);print object[\"monitors\"][${i}][\"id\"]")

            newrelic_monitor=$(curl --silent --show-error --connect-timeout 10 --max-time 20 --write-out "HTTPSTATUS:%{http_code}" --request PUT "https://synthetics.newrelic.com/synthetics/api/v1/monitors/${monitor_id}" \
            --header "X-Api-Key: $(catapult company.newrelic_admin_api_key)" \
            --header "Content-Type: application/json" \
            --data "{\"name\":\"$(catapult websites.apache.$5.domain)\",\"frequency\":5,\"uri\":\"http://$(catapult websites.apache.$5.domain)\",\"locations\":[\"AWS_EU_WEST_1\",\"AWS_AP_NORTHEAST_1\",\"AWS_AP_SOUTHEAST_2\",\"AWS_AP_SOUTHEAST_1\",\"AWS_US_EAST_1\",\"LINODE_US_WEST_1\",\"LINODE_US_SOUTH_1\",\"AWS_SA_EAST_1\",\"AWS_US_WEST_2\",\"LINODE_US_CENTRAL_1\",\"LINODE_US_EAST_1\",\"LINODE_EU_WEST_1\",\"AWS_EU_CENTRAL_1\",\"AWS_US_WEST_1\"],\"status\":\"ENABLED\",\"type\":\"simple\",\"slaThreshold\":7.0}")
            newrelic_monitor_status=$(echo "${newrelic_monitor}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
            newrelic_monitor=$(echo "${newrelic_monitor}" | sed -e 's/HTTPSTATUS\:.*//g')

            # check for a curl error
            if [ $newrelic_monitor_status == 000 ]; then
                echo "there was a problem with the new relic admin api request - please visit https://status.newrelic.com/ to see if there is a problem"
            # a success is null, nice 
            elif [ "${newrelic_monitor}" != "" ]; then
                echo "there was a problem with the new relic admin api request - please visit https://status.newrelic.com/ to see if there is a problem"
                echo "${newrelic_monitor}"
            # success
            else
                echo "synthetic monitor successfully configured"
            fi
            
        fi
        i=$[$i+1]
    done

    # if the monitor does not exist, create
    if [ $monitor_exists == false ]; then
        
        echo "synthetic monitor does not exist, creating..."

        newrelic_monitor=$(curl --silent --show-error --connect-timeout 10 --max-time 20 --write-out "HTTPSTATUS:%{http_code}" --request POST "https://synthetics.newrelic.com/synthetics/api/v1/monitors" \
        --header "X-Api-Key: $(catapult company.newrelic_admin_api_key)" \
        --header "Content-Type: application/json" \
        --data "{\"name\":\"$(catapult websites.apache.$5.domain)\",\"frequency\":5,\"uri\":\"http://$(catapult websites.apache.$5.domain)\",\"locations\":[\"AWS_EU_WEST_1\",\"AWS_AP_NORTHEAST_1\",\"AWS_AP_SOUTHEAST_2\",\"AWS_AP_SOUTHEAST_1\",\"AWS_US_EAST_1\",\"LINODE_US_WEST_1\",\"LINODE_US_SOUTH_1\",\"AWS_SA_EAST_1\",\"AWS_US_WEST_2\",\"LINODE_US_CENTRAL_1\",\"LINODE_US_EAST_1\",\"LINODE_EU_WEST_1\",\"AWS_EU_CENTRAL_1\",\"AWS_US_WEST_1\"],\"status\":\"ENABLED\",\"type\":\"simple\",\"slaThreshold\":7.0}")
        newrelic_monitor_status=$(echo "${newrelic_monitor}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        newrelic_monitor=$(echo "${newrelic_monitor}" | sed -e 's/HTTPSTATUS\:.*//g')

        # check for a curl error
        if [ $newrelic_monitor_status == 000 ]; then
            echo "there was a problem with the new relic admin api request - please visit https://status.newrelic.com/ to see if there is a problem"
        # a success is null, nice 
        elif [ "${newrelic_monitor}" != "" ]; then
            echo "there was a problem with the new relic admin api request - please visit https://status.newrelic.com/ to see if there is a problem"
            echo "${newrelic_monitor}"
        # success
        else
            echo "synthetic monitor successfully configured"
        fi

    fi

    
fi

touch "/catapult/provisioners/redhat/logs/newrelic_synthetics.$(catapult websites.apache.$5.domain).complete"
