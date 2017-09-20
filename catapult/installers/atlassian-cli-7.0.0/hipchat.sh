#!/bin/bash

# Comments
# - Customize for your installation, for instance you might want to add default parameters like the following:
# - To gain access to the server, you must obtain an authorization token (40 characters) from HipChat.
#   - Obtain the token by going to HipChat 'Account Settings' then 'API access'.
#   - Use the token on the token parameter. An example of what it looks like is below.
# - Avoid rate limiting problems with autoWait - see https://bobswift.atlassian.net/wiki/display/HCLI/Rate+Limiting
# java -jar `dirname $0`/lib/hipchat-cli-7.0.0.jar --server http://my-server --autoWait --token X1Xt096Pb9wyEf3EOsKkhc91wJ4MYYP0FcRcDFrx "$@"

java -jar `dirname $0`/lib/hipchat-cli-7.0.0.jar "$@"
