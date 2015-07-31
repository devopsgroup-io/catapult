import-module c:\vagrant\provisioners\windows\installers\poweryaml\poweryaml.psm1
$config = get-yaml -fromfile (resolve-path c:\vagrant\secrets/configuration.yml)
# @todo pass environment arg from vagrant

echo "==> Configuring time"
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


$provisionstart = get-date
$provisionError = "c:\vagrant\provisioners\windows\logs\provisionError.log"
$provision = "c:\vagrant\provisioners\windows\logs\provision.log"


if (-not(Test-Path -Path "c:\windows\Microsoft.NET\Framework64\v4.0.30319\")) {

    echo "`n==> Installing .NET 4.0 (This will take a while...)"
    # ((new-object net.webclient).DownloadFile("http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe","c:\tmp\dotNetFx40_Full_x86_x64.exe")) 
    start-process -filepath "c:\vagrant\provisioners\windows\installers\dotNetFx40_Full_x86_x64.exe" -argumentlist "/q /norestart /log c:\vagrant\provisioners\windows\logs\dotNetFx40_Full_x86_x64.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    echo "Restarting Windows..."
    echo "Please run 'vagrant provision windows' when it's back up"
    restart-computer -force

} else {

    echo "`n==> Installing Git"
    start-process -filepath "c:\vagrant\provisioners\windows\installers\Git-1.9.5-preview20141217.exe" -argumentlist "/SP- /NORESTART /VERYSILENT /SUPPRESSMSGBOXES /SAVEINF=c:\vagrant\provisioners\windows\logs\git-settings.txt /LOG=c:\vagrant\provisioners\windows\logs\Git-1.9.5-preview20141217.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist "--version" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError

    echo "`n==> Configuring git repositories (This may take a while...)"
    # keep linux lf line endings instead of windows converting to crlf
    start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("config --global core.autocrlf false") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    # clone/pull necessary repos
    foreach ($instance in $config.websites.iis) {
        if (test-path ("c:\vagrant\repositories\iis\{0}\.git" -f $instance.domain) ) {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:/vagrant/repositories/iis/{0} pull origin {1}" -f $instance.domain,$config.environments.dev.branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
        } else {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("clone --recursive -b master {0} c:/vagrant/repositories/iis/{1}" -f $instance.repo.replace("://",("://{0}:{1}@" -f $config.company.bitbucket_user,$config.company.bitbucket_user_password)),$instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
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
    get-childitem "c:\vagrant\repositories\iis\*" | ?{ $_.PSIsContainer } | foreach-object {
        $domain = split-path $_.FullName -leaf
        if (-not($domains -contains $domain)) {
            echo "`nWebsite does not exist in secrets/configuration.yaml, removing $domain ..."
            remove-item -recurse -force $_.FullName
        }
    }

    echo "`n==> Importing servermanager"
    import-module servermanager

    echo "`n==> Installing web-webserver"
    add-windowsfeature web-webserver -includeallsubfeature -logpath c:\vagrant\provisioners\windows\logs\add-windowsfeature_web-webserver.log

    echo "`n==> Installing web-mgmt-tools"
    add-windowsfeature web-mgmt-tools -includeallsubfeature -logpath c:\vagrant\provisioners\windows\logs\add-windowsfeature_web-mgmt-tools.log

    echo "`n==> Importing webadministration"
    import-module webadministration

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
    
    $provisionend = Get-Date
    echo ("`n`n`n==> Provision complete ({0}) seconds" -f [math]::floor((New-TimeSpan -Start $provisionstart -End $provisionend).TotalSeconds))
}


exit 0
