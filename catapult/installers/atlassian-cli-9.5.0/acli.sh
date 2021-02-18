#!/bin/bash

# Remember the directory path to this script file
directory=`dirname "$0"`

# Optionally customize settings like location of configuration properties, default encoding, or time zone
# To customize time zone setting, use something like: -Duser.timezone=America/New_York
# To customize configuration location, use the ACLI_CONFIG environment variable or property setting (like: -DACLI_CONFIG=...)
# If not set, default is to look for acli.properties in the installation directory
settings="-Dfile.encoding=UTF-8"

# Find the jar file in the same directory as this script
cliJar=`find "$directory/lib" -name acli-*.jar`

java $settings -jar "${cliJar}" "${@:1}"
