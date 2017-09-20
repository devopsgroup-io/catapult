#!/bin/bash
# This script makes it easier to manage cli version, user, and password settings for various CLIs
# Customize this for your installation. Be careful on upgrades or rename it to something else.
#
# Examples:
#     atlassian.sh confluence --action getServerInfo
#     atlassian.sh jira --action getServerInfo
#     atlassian myOtherConfluence --action getServerInfo
#     atlassian all --action run --file actions.txt
#
# Use settings to customize java environment values globally or for a particular server
# Examples:
#     settings="-Duser.language=en -Dfile.encoding=UTF-8"
#     settings="$settings -Duser.timezone=America/New_York"

# Get the cli version from the directory where it is installed like atlassian-cli-6.7.0 or atlassian-cli-6.7.0-SNAPSHOT
# Or if that is not your naming convention, just set cliVersion to the version number directly below

regexMajorVersion='[^0-9]*\([0-9]*\.[0-9]*\)'
regexSnapshot='[^0-9]*[0-9]*\.[0-9]*\.[0-9]*\(-SNAPSHOT\)'

cliVersion=`expr "$0" : $regexMajorVersion`.0`expr "$0" : $regexSnapshot`

application=$1

# - - - - - - - - - - - - - - - - - - - - START CUSTOMIZE FOR YOUR INSTALLATION !!!
user='automation'
password='automation'
settings=''

if [ "$application" = "all" ]; then
    callString="all-cli-${cliVersion}.jar"
elif [ "$application" = "confluence" ]; then
    callString="confluence-cli-${cliVersion}.jar --server https://confluence.examplegear.com --user $user --password $password"
elif [ "$application" = "jira" ]; then
    callString="jira-cli-${cliVersion}.jar --server https://jira.examplegear.com --user $user --password $password"
elif [ "$application" = "servicedesk" ]; then
    callString="servicedesk-cli-${cliVersion}.jar --server https://jira.examplegear.com --user $user --password $password"
elif [ "$application" = "bamboo" ]; then
    callString="bamboo-cli-${cliVersion}.jar --server https://bamboo.examplegear.com --user $user --password $password"
elif [ "$application" = "bitbucket" ]; then
    callString="bitbucket-cli-${cliVersion}.jar --server https://bitbucket.examplegear.com --user $user --password $password"
elif [ "$application" = "hipchat" ]; then
    callString="hipchat-cli-${cliVersion}.jar --server https://hipchat.examplegear.com --token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
elif [ "$application" = "upm" ]; then
    callString="upm-cli-${cliVersion}.jar --server https://jira.examplegear.com --user $user --password $password"
elif [ "$application" = "csv" ]; then
    callString="csv-cli-${cliVersion}.jar"

# - - - - - - - - - - - - - - - - - - - - - END CUSTOMIZE FOR YOUR INSTALLATION !!!

elif [ "$application" = "" ]; then
    echo "Missing application parameter. Specify an application like confluence, jira, or similar."
    echo "$0 <application name> <application specific parameters>"
    exit -99
else
    echo "Application $application not found in $0"
    exit -99
fi

# Uncomment the following line to help debug
#echo java $settings -jar `dirname $0`/lib/$callString "${@:2}"

java $settings -jar `dirname $0`/lib/$callString "${@:2}"
