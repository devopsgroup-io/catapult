@echo off
rem remember the directory path to this bat file
set dirPath=%~dp0

rem need to reverse windows names to posix names by changing \ to /
set dirPath=%dirPath:\=/%
rem remove blank at end of string
set dirPath=%dirPath:~0,-1%

rem - Customize for your installation, for instance you might want to add default parameters like the following:
rem - To gain access to the server, you must obtain an authorization token (40 characters) from HipChat.
rem   - Obtain the token by going to HipChat 'Account Settings' then 'API access'.
rem   - Use the token on the token parameter. An example of what it looks like is below.
rem - Avoid rate limiting problems with autoWait - see https://bobswift.atlassian.net/wiki/display/HCLI/Rate+Limiting
rem   java -jar "%dirPath%"/lib/hipchat-cli-7.0.0.jar --server http://my-server --autoWait --token X1Xt096Pb9wyEf3EOsKkhc91wJ4MYYP0FcRcDFrx %*

java -jar "%dirPath%"/lib/hipchat-cli-7.0.0.jar %*

rem Exit with the correct error level.
EXIT /B %ERRORLEVEL%
