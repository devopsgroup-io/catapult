#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance


echo -e "\n\n\n"
echo "                   seTHRe                       "
echo "                ---- ESERb                      "
echo "                \    \AHA'                      "
echo "                 \ \Y \Ha                       "
echo "                  \;\\\\_\                        "
echo "                .;'  \\\\                         "
echo "              .;'     \\\\                        "
echo "            .;'        \\\\                       "
echo "    ____  .;'____       \\\\   ____     ____      "
echo "   / / _\_L / /  \ ______\\\\_/_/__\__ / /  \     "
echo "  | | |____| | ++ |_________________| | ++ |    "
echo "   \_\__/   \_\__/          \_\__/   \_\__/     "


echo -e "\n\n\n==> SYSTEM INFORMATION"
echo -e "SYSTEM"
cat /etc/centos-release
hostnamectl status
echo -e "\nCPU"
cat /proc/cpuinfo | grep 'model name' | cut -d: -f2 | awk 'NR==1' | tr -d " "
echo -e "$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')% utilization"
echo -e "\nDISKS"
df -h
echo -e "\nNETWORK"
ifconfig
echo -e "\nMEMORY"
free -h


echo -e "\n\n\n==> RECEIVING CATAPULT"
# update packages
sudo yum update -y
# install shyaml
sudo easy_install pip
sudo pip install --upgrade pip
sudo pip install shyaml --upgrade
# install git
sudo yum install -y git
# initialize known_hosts
sudo mkdir -p ~/.ssh
sudo touch ~/.ssh/known_hosts
# ssh-keyscan bitbucket.org for a maximum of 10 tries
i=0
until [ $i -ge 10 ]; do
    sudo ssh-keyscan bitbucket.org > ~/.ssh/known_hosts
    if grep -q "bitbucket\.org" ~/.ssh/known_hosts; then
        echo "ssh-keyscan for bitbucket.org successful"
        break
    else
        echo "ssh-keyscan for bitbucket.org failed, retrying!"
    fi
    i=$[$i+1]
done
# ssh-keyscan github.com for a maximum of 10 tries
i=0
until [ $i -ge 10 ]; do
    sudo ssh-keyscan github.com >> ~/.ssh/known_hosts
    if grep -q "github\.com" ~/.ssh/known_hosts; then
        echo "ssh-keyscan for github.com successful"
        break
    else
        echo "ssh-keyscan for github.com failed, retrying!"
    fi
    i=$[$i+1]
done
# clone and pull catapult
if ([ $1 = "dev" ] || [ $1 = "test" ]); then
    branch="develop"
elif ([ $1 = "qc" ]); then
    branch="release"
elif ([ $1 = "production" ]); then
    branch="master"
fi
if [ $1 != "dev" ]; then
    if [ -d "/catapult/.git" ]; then
        cd /catapult && sudo git checkout ${branch}
        cd /catapult && sudo git fetch
        cd /catapult && sudo git pull
    else
        sudo git clone --recursive -b ${branch} $2 /catapult
    fi
else
    if ! [ -e "/catapult/secrets/configuration.yml.gpg" ]; then
        echo -e "Cannot read from /catapult/secrets/configuration.yml.gpg, please vagrant reload the virtual machine."
        exit 1
    else
        echo -e "Your Catapult instance is being synced from your host machine."
    fi
fi


# run server provision
if [ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 redhat.servers.redhat.$4.modules) ]; then
    provisionstart=$(date +%s)
    echo -e "\n\n\n==> PROVISION: ${4}"
    # decrypt configuration
    source "/catapult/provisioners/redhat/modules/catapult_decrypt.sh"
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
            # get configuration
            source "/catapult/provisioners/redhat/modules/catapult.sh"
            # create an array for cpu samples
            cpu_load_samples=()
            # create a website index to pass to each sub-process
            website_index=0
            # loop through websites and start sub-processes
            while read -r -d $'\0' website; do
                # only allow a certain number of parallel bash sub-processes at once
                while [ $(( $(ls -l /catapult/provisioners/redhat/logs/${module}.*.log 2>/dev/null | wc -l) - $(ls -l /catapult/provisioners/redhat/logs/${module}.*.complete 2>/dev/null | wc -l) )) -gt 5 ]; do
                    # sample cpu usage
                    cpu_load_sample_decimal=$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')
                    cpu_load_samples+=(${cpu_load_sample_decimal%.*})
                    # add up all of the cpu samples
                    cpu_load_samples_sum=0
                    for i in ${cpu_load_samples[@]}; do
                      let cpu_load_samples_sum+=$i
                    done
                    # get the count of the cpu samples
                    cpu_load_samples_total="${#cpu_load_samples[@]}"
                    # calculate cpu average
                    if [ "${cpu_load_samples_total}" -gt 0 ]; then
                        cpu_load_samples_average=$((cpu_load_samples_sum / cpu_load_samples_total))
                    else
                        cpu_load_samples_average=0
                    fi
                    echo "> waiting to start more parallel processes [$(( $(ls -l /catapult/provisioners/redhat/logs/${module}.*.log 2>/dev/null | wc -l) - $(ls -l /catapult/provisioners/redhat/logs/${module}.*.complete 2>/dev/null | wc -l) )) active / 5 max] [$(ls -l /catapult/provisioners/redhat/logs/${module}.*.complete  2>/dev/null | wc -l) completed] [${cpu_load_samples_average}% average cpu]"
                    sleep 2
                done
                bash "/catapult/provisioners/redhat/modules/${module}.sh" $1 $2 $3 $4 $website_index >> "/catapult/provisioners/redhat/logs/${module}.$(echo "${website}" | shyaml get-value domain).log" 2>&1 &
                (( website_index += 1 ))
            done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
            echo "==> all parallel processes started, waiting for all parallel processes to complete..."
            # determine when each subprocess finishes
            while read -r -d $'\0' website; do
                domain=$(echo "${website}" | shyaml get-value domain)
                domain_tld_override=$(echo "${website}" | shyaml get-value domain_tld_override 2>/dev/null )
                software=$(echo "${website}" | shyaml get-value software 2>/dev/null )
                software_dbprefix=$(echo "${website}" | shyaml get-value software_dbprefix 2>/dev/null )
                software_workflow=$(echo "${website}" | shyaml get-value software_workflow 2>/dev/null )
                while [ ! -e "/catapult/provisioners/redhat/logs/${module}.${domain}.complete" ]; do
                    # sample cpu usage
                    cpu_load_sample_decimal=$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')
                    cpu_load_samples+=(${cpu_load_sample_decimal%.*})
                    sleep 2
                done
                echo -e "=> domain: ${domain}"
                echo -e "=> domain_tld_override: ${domain_tld_override}"
                echo -e "=> software: ${software}"
                echo -e "=> software_dbprefix: ${software_dbprefix}"
                echo -e "=> software_workflow: ${software_workflow}"
                cat "/catapult/provisioners/redhat/logs/${module}.${domain}.log" | sed 's/^/     /'
            done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)
            # add up all of the cpu samples
            cpu_load_samples_sum=0
            for i in ${cpu_load_samples[@]}; do
              let cpu_load_samples_sum+=$i
            done
            # get the count of the cpu samples
            cpu_load_samples_total="${#cpu_load_samples[@]}"
            # calculate cpu average
            if [ "${cpu_load_samples_total}" -gt 0 ]; then
                cpu_load_samples_average=$((cpu_load_samples_sum / cpu_load_samples_total))
            else
                cpu_load_samples_average=0
            fi
            echo -e "==> CPU USAGE: ${cpu_load_samples_average}% from ${cpu_load_samples_total} samples"
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

exit 0
