# variables inbound from provisioner args
# $($args[0]) => environment
# $($args[1]) => repository
# $($args[2]) => gpg key
# $($args[3]) => instance



echo "`n`n`n==> SYSTEM INFORMATION"

# who are we?
Get-WmiObject -Class Win32_ComputerSystem



echo "`n`n`n==> RECEIVING CATAPULT"

# what are we receiving?
echo "=> ENVIRONMENT: $($args[0])"
echo "=> REPOSITORY: $($args[1])"
echo "=> GPG KEY: ************"
echo "=> INSTANCE:$($args[3])"



echo "`n`n`n==> STARTING PROVISION"

# provision the server
powershell -file "c:\catapult\provisioners\windows\provision_server.ps1" $args[0] $args[1] $args[2] $args[3]
