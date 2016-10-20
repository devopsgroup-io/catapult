# variables inbound from provisioner args
# $($args[0]) => environment
# $($args[1]) => repository
# $($args[2]) => gpg key
# $($args[3]) => instance



# global
$provisionError = "c:\catapult\provisioners\windows\logs\provisionError.log"
$provision = "c:\catapult\provisioners\windows\logs\provision.log"


echo "`n`n=> Importing PowerYaml"
import-module c:\catapult\provisioners\windows\installers\poweryaml\poweryaml.psm1


echo "`n`n=> Powershell Version"
$PSVersionTable


echo "`n`n=> Installing GPG"
if (-not(test-path -path "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe")) {
    start-process -filepath "c:\catapult\provisioners\windows\installers\gpg4win-2.3.0.exe" -argumentlist "/S" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
}
start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--version" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError
if (-not(test-path -path "c:\catapult\secrets\configuration.yml.gpg")) {
    echo -e "Cannot read from c:\catapult\secrets\configuration.yml.gpg, please vagrant reload the virtual machine."
    exit 1
}


# get configuration of provisioners
$configuration_provisioners = get-yaml -fromfile (resolve-path c:\catapult\provisioners\provisioners.yml)


# run server provision
if ($configuration_provisioners.windows.servers.$($args[3]).modules) {

    $provisionstart = get-date
    echo "`n`n`n==> PROVISION: $($args[3])"

    # decrypt secrets
    start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\configuration.yml --decrypt c:\catapult\secrets\configuration.yml.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\id_rsa --decrypt c:\catapult\secrets\id_rsa.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\id_rsa.pub --decrypt c:\catapult\secrets\id_rsa.pub.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    $configuration = get-yaml -fromfile (resolve-path c:\catapult\secrets\configuration.yml)

    # loop through each required module
    foreach ($module in $configuration_provisioners.windows.servers.$($args[3]).modules) {

        $start = get-date
        echo "`n`n`n==> MODULE: $module"
        # check for reboot status between modules
        # required to ensure all dependencies are in place for later software installs
        $objSystemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"
        if ($objSystemInfo.RebootRequired) {
            echo "==> REBOOT REQUIRED STATUS: [REQUIRED] Windows Update requires a reboot of this machine. Please do so and run the provisioner again to continue..."
            exit 1
        } else {
            echo "==> REBOOT REQUIRED STATUS: [NOT REQUIRED] Continuing..."
        }
        echo ("==> DESCRIPTION: {0}" -f $configuration_provisioners.windows.modules.$($module).description)
        echo ("==> MULTITHREADING: {0}" -f $configuration_provisioners.windows.modules.$($module).multithreading)

        # invoke multithreading module in parallel
        # @todo this is not multithreading (remove the -Wait), will require mimicing the bash logic
        if ($configuration_provisioners.windows.modules.$($module).multithreading -eq "true") {
            # create a website index to pass to each sub-process
            $website_index = 0
            foreach ($instance in $configuration.websites.iis) {
                echo ("=> domain: $($instance.domain)")
                echo ("=> domain_tld_override: $($instance.domain_tld_override)")
                echo ("=> software: $($instance.software)")
                echo ("=> software_auto_update: $($instance.software_auto_update)")
                echo ("=> software_dbprefix: $($instance.software_dbprefix)")
                echo ("=> software_workflow: $($instance.software_workflow)")
                start-process powershell -argumentlist "-file c:\catapult\provisioners\windows\modules\$module.ps1", $args[0], $args[1], $args[2], $args[3], $website_index -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
                get-content $provision
                get-content $provisionError
                $website_index = $website_index + 1
            }
        # invoke standard module in series
        } else {
            powershell -file "c:\catapult\provisioners\windows\modules\$module.ps1" $args[0] $args[1] $args[2] $args[3]
        }

        $end = get-date
        echo "==> MODULE: $module"
        echo ("==> DURATION: {0} seconds" -f [math]::floor((New-TimeSpan -Start $start -End $end).TotalSeconds))
    }

    # remove secrets
    if (-not($($args[0]) -eq "dev")) {
        remove-item "c:\catapult\secrets\configuration.yml"
        remove-item "c:\catapult\secrets\id_rsa"
        remove-item "c:\catapult\secrets\id_rsa.pub"
    }

    $provisionend = Get-Date
    echo "`n`n`n==> PROVISION: $($args[3])"
    echo "==> FINISH: $(Get-Date)"
    echo ("==> DURATION: {0} total seconds" -f [math]::floor((New-TimeSpan -Start $provisionstart -End $provisionend).TotalSeconds))

} else {
    echo "Error: Cannot detect the server type."
    exit 1
}


