#!/bin/bash

# Comments
# - Customize for your installation, for instance you might want to add default parameters like the following:
# java -jar `dirname $0`/lib/agile-cli-7.9.0.jar --server https://my.examplegear.com --user automation --password automation "$@"

java -jar `dirname $0`/lib/agile-cli-7.9.0.jar "$@"
