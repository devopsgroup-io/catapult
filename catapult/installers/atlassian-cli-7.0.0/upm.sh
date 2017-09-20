#!/bin/bash

# Comments
# - Customize for your installation, for instance you might want to add default parameters like the following:
# java -jar `dirname $0`/lib/upm-cli-7.0.0.jar --token automation "$@"

java -jar `dirname $0`/lib/upm-cli-7.0.0.jar "$@"
