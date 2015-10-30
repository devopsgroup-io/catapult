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
echo -e "CPU"
cat /proc/cpuinfo | grep 'model name' | cut -d: -f2 | awk 'NR==1' | tr -d " "
echo -e "$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')% utilization"
echo -e "\nHDD"
df -h
echo -e "\nNET"
ifconfig
echo -e "\nRAM"
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
sudo ssh-keyscan -T 10 bitbucket.org > ~/.ssh/known_hosts
sudo ssh-keyscan -T 10 github.com >> ~/.ssh/known_hosts
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
        cd /catapult && sudo git diff --exit-code ${branch} origin/${branch} "secrets/configuration.yml.gpg"
        if [ $? -eq 1 ]; then 
            configuration_changes="True"
        fi
        cd /catapult && sudo git pull
    else
        sudo git clone --recursive -b ${branch} $2 /catapult | sed "s/^/\t/"
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
        # first boot || dev || not config related || config related and incoming config changes
        if ([ ! -s /catapult/provisioners/redhat/logs/$4.log ]) || ([ "${1}" == "dev" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.configuration) == "False" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.configuration) == "True" ] && [ "${configuration_changes}" == "True" ]); then
            start=$(date +%s)
            echo -e "\n\n\n==> MODULE: ${module}"
            echo -e "==> DESCRIPTION: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.description)"
            echo -e "==> MULTITHREADING: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.multithreading)"
            # if multithreading is supported
            if ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.${module}.multithreading) == "True" ]); then
                # cleanup leftover utility files
                for file in "/catapult/provisioners/redhat/logs/${module}.*.log"; do
                    if [ -e "$file" ]; then
                        rm $file
                    fi
                done
                for file in "/catapult/provisioners/redhat/logs/${module}.*.complete"; do
                    if [ -e "$file" ]; then
                        rm $file
                    fi
                done
                # enable job control
                set -m
                # get configuration
                source "/catapult/provisioners/redhat/modules/catapult.sh"
                # loop through websites and pass to subprocesses
                websiteN=0
                echo "${configuration}" | shyaml get-values-0 websites.apache |
                while read -r -d $'\0' website; do
                    bash "/catapult/provisioners/redhat/modules/${module}.sh" $1 $2 $3 $4 $websiteN >> "/catapult/provisioners/redhat/logs/${module}.$(echo "${website}" | shyaml get-value domain).log" 2>&1 &
                    (( websiteN += 1 ))
                done
                # determine when each subprocess is finished
                echo "${configuration}" | shyaml get-values-0 websites.apache |
                    while read -r -d $'\0' website; do
                        domain=$(echo "${website}" | shyaml get-value domain)
                        while [ ! -e "/catapult/provisioners/redhat/logs/${module}.${domain}.complete" ]; do
                            sleep 1
                        done
                        echo -e "=> ${domain}"
                        cat "/catapult/provisioners/redhat/logs/${module}.${domain}.log" | sed 's/^/   /'
                    done
                # cleanup utility files
                for file in "/catapult/provisioners/redhat/logs/${module}.*.log"; do
                    rm $file
                done
                for file in "/catapult/provisioners/redhat/logs/${module}.*.complete"; do
                    rm $file
                done
            else
                bash "/catapult/provisioners/redhat/modules/${module}.sh" $1 $2 $3 $4
            fi
            end=$(date +%s)
            echo -e "==> MODULE: ${module}"
            echo -e "==> DURATION: $(($end - $start)) seconds"
        fi
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
