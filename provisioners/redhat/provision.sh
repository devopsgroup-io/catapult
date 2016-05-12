#!/usr/bin/env bash



# variables inbound from provisioner args
# $1 => environment
# $2 => repository
# $3 => gpg key
# $4 => instance



echo -e "\n\n\n==> SYSTEM INFORMATION"

# who are we?
hostnamectl status



echo -e "\n\n\n==> INSTALLING MINIMAL DEPENDENCIES"

# update packages
sudo yum update -y

# install git
sudo yum install -y git



echo -e "\n\n\n==> RECEIVING CATAPULT"

# what are we receiving?
echo -e "=> ENVIRONMENT: ${1}"
echo -e "=> REPOSITORY: ${2}"
echo -e "=> GPG KEY: ************"
echo -e "=> INSTANCE: ${4}"

# get the catapult instance
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



# that's a lot of catapult
echo -e "\n\n\n "
cat /catapult/catapult/catapult.txt
echo -e "\n "
version=$(cd /catapult && cat /catapult/VERSION.yml | grep "version:" | awk '{print $2}')
repo=$(cd /catapult && git config --get remote.origin.url)
branch=$(cd /catapult && git rev-parse --abbrev-ref HEAD)
echo -e "==> CATAPULT VERSION: ${version}"
echo -e "==> CATAPULT GIT REPO: ${repo}"
echo -e "==> GIT BRANCH: ${branch}"



echo -e "\n\n\n==> STARTING PROVISION"

# provision the server
source "/catapult/provisioners/redhat/provision_server.sh"
