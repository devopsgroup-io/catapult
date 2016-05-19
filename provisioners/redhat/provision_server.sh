# resources function
function resources() {
    module="${1}"

    cpu_utilization=$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')
    if [ "${cpu_utilization%.*}" -gt 80 ]; then
        output_cpu_utilization="![${cpu_utilization%.*}% cpu]"
    else
        output_cpu_utilization=" [${cpu_utilization%.*}% cpu]"
    fi

    mem_total=$(free --mega | grep "Mem:" | awk '{print $2}')
    mem_utilization=$(free --mega | grep "Mem:" | awk '{print $3}')

    swap_total=$(free --mega | grep "Swap:" | awk '{print $2}')
    swap_utilization=$(free --mega | grep "Swap:" | awk '{print $3}')

    eth0_name=$(cat /proc/net/dev | tail -n +3 | sed -n '1p' | awk '{print $1}')
    eth0_rx=$(cat /proc/net/dev | tail -n +3 | sed -n '1p' | awk '{print $2}' | awk '{ var = $1 / 1024 / 1024 ; print var }')
    eth0_tx=$(cat /proc/net/dev | tail -n +3 | sed -n '1p' | awk '{print $10}' | awk '{ var = $1 / 1024 / 1024 ; print var }')

    eth1_name=$(cat /proc/net/dev | tail -n +3 | sed -n '2p' | awk '{print $1}')
    eth1_rx=$(cat /proc/net/dev | tail -n +3 | sed -n '2p' | awk '{print $2}' | awk '{ var = $1 / 1024 / 1024 ; print var }')
    eth1_tx=$(cat /proc/net/dev | tail -n +3 | sed -n '2p' | awk '{print $10}' | awk '{ var = $1 / 1024 / 1024 ; print var }')

    module_processes_started=$(ls -l /catapult/provisioners/redhat/logs/${module}.*.log 2>/dev/null | wc -l)
    module_processes_completed=$(ls -l /catapult/provisioners/redhat/logs/${module}.*.complete 2>/dev/null | wc -l)
    module_processes_active=$(( $module_processes_started - $module_processes_completed ))
    if [ "${module_processes_active}" -gt 4 ]; then
        output_module_processes="![${module_processes_active} active / ${module_processes_completed} completed]"
    else
        output_module_processes=" [${module_processes_active} active / ${module_processes_completed} completed]"
    fi

    echo -e " \
> managing parallel processes \
${output_module_processes} \
${output_cpu_utilization} \
[${mem_utilization}MB / ${mem_total}MB mem] \
[${swap_utilization}MB / ${swap_total}MB swap] \
[${eth0_name} ${eth0_rx%.*}MB rx ${eth0_tx%.*}MB tx] \
[${eth1_name} ${eth1_rx%.*}MB rx ${eth1_tx%.*}MB tx] \
    "
}

# install shyaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade

# run server provision
if [ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 redhat.servers.redhat.$4.modules) ]; then
    provisionstart=$(date +%s)
    echo -e "\n\n\n==> PROVISION: ${4}"
    # decrypt configuration
    source "/catapult/provisioners/redhat/modules/catapult_decrypt.sh"
    # get configuration
    source "/catapult/provisioners/redhat/modules/catapult.sh"

    # report a deployment to new relic
    newrelic_deployment=$(curl --silent --show-error --connect-timeout 10 --max-time 20 --write-out "HTTPSTATUS:%{http_code}" --request POST "https://api.newrelic.com/deployments.xml" \
    --header "X-Api-Key: $(catapult company.newrelic_api_key)" \
    --data "deployment[app_name]=$(catapult company.name | tr '[:upper:]' '[:lower:]')-${1}-redhat" \
    --data "deployment[description]=Catapult Provision Started" \
    --data "deployment[revision]=$(cat "/catapult/VERSION.yml" | shyaml get-value version)")
    newrelic_deployment_status=$(echo "${newrelic_deployment}" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    newrelic_deployment=$(echo "${newrelic_deployment}" | sed -e 's/HTTPSTATUS\:.*//g')
    # check for a curl error
    if [ $newrelic_deployment_status == 000 ]; then
        echo "there was a problem reporting this deployment to new relic"
    else
        echo "successfully reported this deployment to new relic"
    fi

    # loop through each required module
    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 redhat.servers.redhat.$4.modules |
    while read -r -d $'\0' module; do
        start=$(date +%s)
        echo -e "\n\n\n==> MODULE: ${module}"
        echo -e "==> DESCRIPTION: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.description)"
        echo -e "==> MULTITHREADING: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.multithreading)"
        # if multithreading is supported
        if ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.multithreading) == "True" ]); then
            # cleanup leftover utility files
            for file in /catapult/provisioners/redhat/logs/${module}.*.log; do
                if [ -e "$file" ]; then
                    rm $file
                fi
            done
            for file in /catapult/provisioners/redhat/logs/${module}.*.complete; do
                if [ -e "$file" ]; then
                    rm $file
                fi
            done
            # enable job control
            set -m
            # create a website index to pass to each sub-process
            website_index=0
            # loop through websites and start sub-processes
            while read -r -d $'\0' website; do
                # only allow a certain number of parallel bash sub-processes at once
                sleep 1
                while true; do
                    resources=$(resources ${module})
                    if ([[ $resources == *"!"* ]]); then
                        echo "${resources}"
                        sleep 1
                    else
                        echo "${resources}"
                        break
                    fi
                done
                bash "/catapult/provisioners/redhat/modules/${module}.sh" $1 $2 $3 $4 $website_index >> "/catapult/provisioners/redhat/logs/${module}.$(echo "${website}" | shyaml get-value domain).log" 2>&1 &
                (( website_index += 1 ))
            done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
            # determine when each subprocess finishes
            while read -r -d $'\0' website; do
                domain=$(echo "${website}" | shyaml get-value domain)
                domain_tld_override=$(echo "${website}" | shyaml get-value domain_tld_override 2>/dev/null )
                software=$(echo "${website}" | shyaml get-value software 2>/dev/null )
                software_dbprefix=$(echo "${website}" | shyaml get-value software_dbprefix 2>/dev/null )
                software_workflow=$(echo "${website}" | shyaml get-value software_workflow 2>/dev/null )
                # only allow a certain number of parallel bash sub-processes at once
                while true; do
                    resources=$(resources ${module})
                    if [ ! -e "/catapult/provisioners/redhat/logs/${module}.${domain}.complete" ]; then
                        echo "${resources}"
                        sleep 1
                    else
                        break
                    fi
                done
                echo -e "=> domain: ${domain}"
                echo -e "=> domain_tld_override: ${domain_tld_override}"
                echo -e "=> software: ${software}"
                echo -e "=> software_dbprefix: ${software_dbprefix}"
                echo -e "=> software_workflow: ${software_workflow}"
                cat "/catapult/provisioners/redhat/logs/${module}.${domain}.log" | sed 's/^/     /'
            done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
            # cleanup leftover utility files
            for file in /catapult/provisioners/redhat/logs/${module}.*.log; do
                if [ -e "$file" ]; then
                    rm $file
                fi
            done
            for file in /catapult/provisioners/redhat/logs/${module}.*.complete; do
                if [ -e "$file" ]; then
                    rm $file
                fi
            done
        else
            bash "/catapult/provisioners/redhat/modules/${module}.sh" $1 $2 $3 $4
        fi
        end=$(date +%s)
        echo -e "==> MODULE: ${module}"
        echo -e "==> DURATION: $(($end - $start)) seconds"
    done

    provisionend=$(date +%s)
    # remove configuration
    source "/catapult/provisioners/redhat/modules/catapult_clean.sh"
    echo -e "\n\n\n==> PROVISION: ${4}"
    echo -e "==> DURATION: $(($provisionend - $provisionstart)) total seconds" | tee -a /catapult/provisioners/redhat/logs/$4.log
else
    "Error: Cannot detect the server type."
    exit 1
fi
