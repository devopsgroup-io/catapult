#!/bin/bash

date=$(/bin/date +"%b %d" --date "1 day ago")

/bin/cat /var/log/maillog | /bin/grep --invert-match "status=sent" | /bin/grep "${date}" | /bin/grep --silent "status="
if [ $? -eq 0 ]; then

    /bin/echo -e "Postfix mail messages were found in yesterday's (${date}) log without a status of sent. Please review the following failures:\n\n"

    /bin/cat /var/log/maillog | /bin/grep --invert-match "status=sent" | /bin/grep "${date}" | /bin/grep "status=" | /bin/sed -e "s/^.*$/&1\n/"
fi
