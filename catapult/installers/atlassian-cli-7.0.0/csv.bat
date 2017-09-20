@echo off
rem remember the directory path to this bat file
set dirPath=%~dp0

rem need to reverse windows names to posix names by changing \ to /
set dirPath=%dirPath:\=/%
rem remove blank at end of string
set dirPath=%dirPath:~0,-1%

java -jar "%dirPath%"/lib/csv-cli-7.0.0.jar %*

rem Exit with the correct error level.
EXIT /B %ERRORLEVEL%
