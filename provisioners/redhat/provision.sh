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


# determine if there are configuration changes



# provision server
# @todo standardize apache/mysql to match server name?
if [ "${4}" = "apache" ]; then

    provisionstart=$(date +%s)
    echo -e "\n\n\n==> PROVISION: apache"

    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 redhat.servers.redhat.modules |
    while read -r -d $'\0' key value; do
        # first boot || dev || not config related || config related and incoming config changes
        if ([ ! -s /catapult/provisioners/redhat/logs/apache.log ]) || ([ $1 == "dev" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.configuration) == "False" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.configuration) == "True" ] && [ "${configuration_changes}" == "True" ]); then
            start=$(date +%s)
            echo -e "\n\n\n==> MODULE: ${key}"
            echo -e "==> DESCRIPTION: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.description)"
            bash "/catapult/provisioners/redhat/modules/${key}.sh" $1 $2 $3 $4
            end=$(date +%s)
            echo -e "==> MODULE: ${key}"
            echo -e "==> DURATION: $(($end - $start)) seconds"
        fi
    done

    provisionend=$(date +%s)
    echo -e "\n\n\n==> PROVISION: apache"
    echo -e "==> DURATION: $(($provisionend - $provisionstart)) total seconds" | tee -a /catapult/provisioners/redhat/logs/apache.log

elif [ "${4}" = "mysql" ]; then

    provisionstart=$(date +%s)
    echo -e "\n\n\n==> PROVISION: mysql"

    cat "/catapult/provisioners/provisioners.yml" | shyaml get-values-0 redhat.servers.redhat_mysql.modules |
    while read -r -d $'\0' key value; do
        # first boot || dev || not config related || config related and incoming config changes
        if ([ ! -s /catapult/provisioners/redhat/logs/mysql.log ]) || ([ $1 == "dev" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.configuration) == "False" ]) || ([ $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.configuration) == "True" ] && [ "${configuration_changes}" == "True" ]); then
            start=$(date +%s)
            echo -e "\n\n\n==> MODULE: ${key}"
            echo -e "==> DESCRIPTION: $(cat "/catapult/provisioners/provisioners.yml" | shyaml get-value redhat.modules.$key.description)"
            bash "/catapult/provisioners/redhat/modules/${key}.sh" $1 $2 $3 $4
            end=$(date +%s)
            echo -e "==> MODULE: ${key}"
            echo -e "==> DURATION: $(($end - $start)) seconds"
        fi
    done

    provisionend=$(date +%s)
    echo -e "\n\n\n==> PROVISION: mysql"
    echo -e "==> DURATION: $(($provisionend - $provisionstart)) total seconds" | tee -a /catapult/provisioners/redhat/logs/mysql.log

else
    "Error: Cannot detect the server type."
    exit 1
fi
