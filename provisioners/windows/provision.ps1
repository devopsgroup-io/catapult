# variables inbound from provisioner args
# $($args[0]) => environment
# $($args[1]) => repository
# $($args[2]) => gpg key
# $($args[3]) => instance


# global variables
$provisionstart = get-date
$provisionError = "c:\catapult\provisioners\windows\logs\provisionError.log"
$provision = "c:\catapult\provisioners\windows\logs\provision.log"


echo "`n==> Importing PowerYaml"
import-module c:\catapult\provisioners\windows\installers\poweryaml\poweryaml.psm1


echo "`n==> Powershell Version"
$PSVersionTable


echo "`n==> Installing GPG"
if (-not(Test-Path -Path "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe")) {
    start-process -filepath "c:\catapult\provisioners\windows\installers\gpg4win-2.3.0.exe" -argumentlist "/S" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
}
start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--version" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError
if (-not(Test-Path -Path "c:\catapult\secrets\configuration.yml.gpg")) {
    echo -e "Cannot read from c:\catapult\secrets\configuration.yml.gpg, please vagrant reload the virtual machine."
    exit 1
}
# decrypt configuration
start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\configuration.yml --decrypt c:\catapult\secrets\configuration.yml.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError
start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\id_rsa --decrypt c:\catapult\secrets\id_rsa.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError
start-process -filepath "c:\Program Files (x86)\GNU\GnuPG\gpg2.exe" -argumentlist "--verbose --batch --yes --passphrase $($args[2]) --output c:\catapult\secrets\id_rsa.pub --decrypt c:\catapult\secrets\id_rsa.pub.gpg" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError
$config = get-yaml -fromfile (resolve-path c:\catapult\secrets\configuration.yml)


echo "`n==> Configuring time"
# set timezone
tzutil /s $config.company.timezone_windows
# configure ntp
$timeroot = "HKLM:\SYSTEM\CurrentControlSet\services\W32Time"
Set-ItemProperty -path "$timeroot\parameters" -name type -Value "NTP"
Set-ItemProperty -path "$timeroot\parameters" -name NtpServer -Value "time.windows.com,0x1 nist1-ny.ustiming.org,0x1"
Set-ItemProperty -path "$timeroot\config" -name AnnounceFlags -Value 5
Set-ItemProperty -path "$timeroot\config" -name MaxPosPhaseCorrection -Value 1800
Set-ItemProperty -path "$timeroot\config" -name MaxNegPhaseCorrection -Value 1800
Set-ItemProperty -path "$timeroot\TimeProviders\NtpServer" -name Enabled -Value 1
Set-ItemProperty -path "$timeroot\TimeProviders\NtpClient" -name SpecialPollInterval -Value 900
# echo datetimezone
get-date
$([System.TimeZone]::CurrentTimeZone.StandardName)


echo "`n==> Installing .NET 4.0 (This may take a while...)"
if (-not(Test-Path -Path "c:\windows\Microsoft.NET\Framework64\v4.0.30319\")) {
    # ((new-object net.webclient).DownloadFile("http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe","c:\tmp\dotNetFx40_Full_x86_x64.exe")) 
    start-process -filepath "c:\catapult\provisioners\windows\installers\dotNetFx40_Full_x86_x64.exe" -argumentlist "/q /norestart /log c:\catapult\provisioners\windows\logs\dotNetFx40_Full_x86_x64.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    echo "Restarting Windows..."
    echo "Please run 'vagrant provision windows' when it's back up"
    restart-computer -force
    exit 0
}
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release


echo "`n==> Installing Git"
if (-not(Test-Path -Path "c:\Program Files (x86)\Git\bin\git.exe")) {
    start-process -filepath "c:\catapult\provisioners\windows\installers\Git-1.9.5-preview20141217.exe" -argumentlist "/SP- /NORESTART /VERYSILENT /SUPPRESSMSGBOXES /SAVEINF=c:\catapult\provisioners\windows\logs\git-settings.txt /LOG=c:\catapult\provisioners\windows\logs\Git-1.9.5-preview20141217.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
}
start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist "--version" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError


echo "`n==> Importing servermanager"
import-module servermanager
if (Get-Module -ListAvailable -Name servermanager) {
    echo "servermanager loaded"
} else {
    echo "servermanager failed to load"
}

echo "`n==> Installing web-webserver (This may take a while...)"
add-windowsfeature web-webserver -includeallsubfeature -logpath c:\catapult\provisioners\windows\logs\add-windowsfeature_web-webserver.log


echo "`n==> Installing web-mgmt-tools"
add-windowsfeature web-mgmt-tools -includeallsubfeature -logpath c:\catapult\provisioners\windows\logs\add-windowsfeature_web-mgmt-tools.log


echo "`n==> Importing webadministration"
import-module webadministration
if (Get-Module -ListAvailable -Name webadministration) {
    echo "webadministration loaded"
} else {
    echo "webadministration failed to load"
}


echo "`n==> Configuring git repositories (This may take a while...)"
if (-not($config.websites.iis)) {

    echo "There are no websites in iis, nothing to do."

} else {

    # keep linux lf line endings instead of windows converting to crlf
    start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("config --global core.autocrlf false") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    # clone/pull necessary repos
    foreach ($instance in $config.websites.iis) {
        if (test-path ("c:\catapult\repositories\iis\{0}\.git" -f $instance.domain) ) {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\catapult\repositories\iis\{0} pull origin {1}" -f $instance.domain,$config.environments.dev.branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
        } else {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("clone --recursive -b master {0} c:\catapult\repositories\iis\{1}" -f $instance.repo.replace("://",("://{0}:{1}@" -f $config.company.bitbucket_user,$config.company.bitbucket_user_password)),$instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
        }
    }
    # create an array of domains
    $domains = @()
    foreach ($instance in $config.websites.iis) {
        $domains += $instance.domain
    }
    # cleanup directories from domains array
    get-childitem "c:\catapult\repositories\iis\*" | ?{ $_.PSIsContainer } | foreach-object {
        $domain = split-path $_.FullName -leaf
        if (-not($domains -contains $domain)) {
            echo "`nWebsite does not exist in secrets/configuration.yml, removing $domain ..."
            remove-item -recurse -force $_.FullName
        }
    }

    echo "`n==> Removing websites"
    if (get-childitem -Path IIS:\Sites | where-object {$_.Name -ne "Default Web Site"}) {
        $websites = get-childitem -Path IIS:\Sites | where-object {$_.Name -ne "Default Web Site"}
        foreach ($website in $websites) {
            remove-item ("IIS:\Sites\{0}" -f $website.Name) -recurse
        }
    }

    echo "`n==> Removing application pools"
    if (get-childitem -Path IIS:\AppPools | where-object {$_.Name -ne "DefaultAppPool"}) {
        $apppools = get-childitem -Path IIS:\AppPools | where-object {$_.Name -ne "DefaultAppPool"}
        foreach ($apppool in $apppools) {
            remove-item ("IIS:\AppPools\{0}" -f $apppool.Name) -recurse
        }
    }

    echo "`n==> Removing net shares"
    # iis cannot read from a vagrant synced folder, creating a net share gets around this. returnvalue: 0 is success.
    if (get-wmiobject Win32_Share | where-object {$_.Name -ne "c$"}) {
        $netshares = get-wmiobject Win32_Share | where-object {$_.Name -ne "c$"}
        foreach ($netshare in $netshares) {
            $netshare.Delete()
        }
    }

    echo "`n==> Creating net shares"
    foreach ($instance in $config.websites.iis) {
        (get-wmiobject Win32_Share -List).Create(("c:\inetpub\repositories\iis\{0}" -f $instance.domain), ("{0}" -f $instance.domain), 0)
    }

    echo "`n==> Creating application pools"
    foreach ($instance in $config.websites.iis) {
        new-item ("IIS:\AppPools\dev.{0}" -f $instance.domain)
        set-itemproperty ("IIS:\AppPools\dev.{0}" -f $instance.domain) managedRuntimeVersion v4.0
    }

    echo "`n==> Creating websites"
    foreach ($instance in $config.websites.iis) {
        new-website -name ("dev.{0}" -f $instance.domain) -hostheader ("dev.{0}" -f $instance.domain) -port 80 -physicalpath ("\\localhost\{0}" -f $instance.domain) -ApplicationPool ("dev.{0}" -f $instance.domain) -force
    }

    echo "`n==> Starting websites"
    if (get-childitem -Path IIS:\Sites) {
        get-childitem -Path IIS:\Sites | foreach { start-website $_.Name; }
    }
    echo ""
    foreach ($instance in $config.websites.iis) {
        echo ("http://dev.{0}" -f $instance.domain)
    }
    echo ""

    echo "`n==> Registering .NET 4.0 with IIS"
    start-process -filepath "c:\windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe" -argumentlist "-i" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError

}


# cleanup files
remove-item "c:\catapult\secrets\configuration.yml"
remove-item "c:\catapult\secrets\id_rsa"
remove-item "c:\catapult\secrets\id_rsa.pub"


$provisionend = Get-Date
echo ("`n`n`n==> Provision complete ({0}) seconds" -f [math]::floor((New-TimeSpan -Start $provisionstart -End $provisionend).TotalSeconds))
