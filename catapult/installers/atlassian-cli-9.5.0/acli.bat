@echo off
setlocal

rem Remember the directory path to this script file
set directory=%~dp0

rem Remove blank at end of path
set directory=%directory:~0,-1%

rem Optionally customize settings like the location of configuration properties, default encoding, or time zone
rem To customize time zone setting, use something like: -Duser.timezone=America/New_York"
rem To customize configuration location, use the ACLI_CONFIG environment variable or property setting (like: -DACLI_CONFIG=...)
rem If not set, default is to look for acli.properties in the installation directory
set settings=-Dfile.encoding=UTF-8

rem Find the jar file in the same directory as this script in the lib sub-directory
for /F "tokens=* USEBACKQ" %%g in (`dir /s /b "%directory%\lib\acli*.jar"`) do (set "cliJar=%%g")

rem Call the client application passing all parameters
java %settings% -jar "%cliJar%" %*

rem Exit with the correct error level.
EXIT /B %ERRORLEVEL%
