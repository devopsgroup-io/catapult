# import poweryaml
import-module c:\catapult\provisioners\windows\installers\poweryaml\poweryaml.psm1

# global
$provisionError = "c:\catapult\provisioners\windows\logs\provisionError.log"
$provision = "c:\catapult\provisioners\windows\logs\provision.log"
$configuration = get-yaml -fromfile (resolve-path c:\catapult\secrets\configuration.yml)
