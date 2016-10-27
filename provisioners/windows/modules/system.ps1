. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Getting Windows license status"
Get-CimInstance -ClassName SoftwareLicensingProduct | where PartialProductKey | select `
    Name,
    Description,
    @{Name='GenuineStatus';Exp={
        switch ($_.GenuineStatus)
        {
            0 {'Non-Genuine'}
            1 {'Genuine'}
            Default {'Undetected'}
        }
    }},
    @{Name='LicenseStatus';Exp={
        # https://msdn.microsoft.com/en-us/library/cc534596%28v=vs.85%29.aspx
        switch ($_.LicenseStatus) {
            0 {'Unlicensed'}
            1 {'licensed'}
            2 {'OOBGrace'}
            3 {'OOTGrace'}
            4 {'NonGenuineGrace'}
            5 {'Notification'}
            6 {'ExtendedGrace'}
            Default {'Undetected'}
        }
    }} | Format-List


echo "`n=> Configuring security policy"
# remove the PasswordComplexity settting to allow for user accounts to be created for iis and the force_auth option
# we'll require our own, 10 character, 20 maximum password
$security_policy = "c:\catapult\provisioners\windows\installers\temp\security_policy.cfg"
secedit /export /cfg $security_policy
(gc $security_policy).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File $security_policy
secedit /configure /db c:\windows\security\local.sdb /cfg $security_policy /areas SECURITYPOLICY
rm -force $security_policy -confirm:$false


echo "`n=> Configuring hostname"
# set the base hostname limited by the 15 character limit (UGH)
if ($($args[0].Text.Length) -gt 4) {
    $hostname = "$($args[0].Substring(0,4))-win"
} else {
    $hostname = "$($args[0])-win"
}
# set hostname
if ($($args[3]) -eq "iis") {
    if ($env:computername.ToLower() -ne "$($hostname)") {
        Rename-Computer -Force -NewName "$($hostname)"
    }
} elseif (($args[3]) -eq "mssql") {
    if ($env:computername.ToLower() -ne "$($hostname)-mssql") {
        Rename-Computer -Force -NewName "$($hostname)-mssql"
    }
}
# echo hostname
echo $env:computername


echo "`n=> Configuring system page file"
# let windows manage our page file for us for now
wmic computersystem set AutomaticManagedPageFile=TRUE
echo "Allocated: $(get-wmiobject win32_pagefileusage | % {$_.allocatedbasesize})MB"
echo "Current: $(get-wmiobject win32_pagefileusage | % {$_.currentusage})MB"
echo "Peak: $(get-wmiobject win32_pagefileusage | % {$_.peakusage})MB"


echo "`n=> Importing PSWindowsUpdate"
if (test-path -path "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate") {
    Remove-Item "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate" -Force -Recurse
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("c:\catapult\provisioners\windows\installers\PSWindowsUpdate.zip", "C:\Windows\System32\WindowsPowerShell\v1.0\Modules")
Import-Module PSWindowsUpdate
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    echo "- PSWindowsUpdate loaded"
    echo (Get-Module PSWindowsUpdate) | Format-Table -Property Version
} else {
    echo "- PSWindowsUpdate failed to load"
}
#Set-ExecutionPolicy RemoteSigned


echo "`n=> Downloading .NET 3.5..."
if (-not(test-path -path "c:\catapult\provisioners\windows\installers\temp\dotnetfx35.exe")) {
    $url = "https://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe"
    $output = "c:\catapult\provisioners\windows\installers\temp\dotnetfx35.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} else {
    echo "- Installer exists, skipping download..."
}


echo "`n=> Installing .NET 3.5..."
if (-not(test-path -path "c:\windows\Microsoft.NET\Framework64\v3.5\")) {
    install-windowsfeature Net-Framework-Core -source "c:\catapult\provisioners\windows\installers\temp\dotnetfx35.exe"
} else {
    echo "- Installed, skipping..."
}


echo "`n=> Downloading .NET 4.0..."
if (-not(test-path -path "c:\catapult\provisioners\windows\installers\temp\dotNetFx40_Full_x86_x64.exe")) {
    $url = "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
    $output = "c:\catapult\provisioners\windows\installers\temp\dotNetFx40_Full_x86_x64.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} else {
    echo "- Installer exists, skipping download..."
}


echo "`n=> Installing .NET 4.0..."
if (-not(test-path -path "c:\windows\Microsoft.NET\Framework64\v4.0.30319\")) {
    start-process -filepath "c:\catapult\provisioners\windows\installers\temp\dotNetFx40_Full_x86_x64.exe" -argumentlist "/q /norestart /log c:\catapult\provisioners\windows\logs\dotNetFx40_Full_x86_x64.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    echo "Restarting Windows..."
    echo "Please invoke 'vagrant provision' when it's back up"
    restart-computer -force
    exit 0
} else {
    echo "- Installed, skipping..."
}


echo "`n=> Installed .NET versions"
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release


echo "`n=> Installing Web Platform Installer..."
# http://www.iis.net/learn/install/web-platform-installer/web-platform-installer-v4-command-line-webpicmdexe-rtw-release
if (-not(test-path -path "c:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe")) {
    # https://github.com/fdcastel/psunattended/blob/master/PSUnattended.ps1
    start-process -filepath msiexec -argumentlist "/i c:\catapult\provisioners\windows\installers\WebPlatformInstaller_amd64_en-US.msi /q ALLUSERS=1 REBOOT=ReallySuppress" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
} else {
    echo "- Installed, skipping..."
}


echo "`n=> Configuring SSH"
# initialize id_rsa
new-item "c:\Users\$env:username\.ssh\id_rsa" -type file -force
get-content "c:\catapult\secrets\id_rsa" | add-content "c:\Users\$env:username\.ssh\id_rsa"
# initialize known_hosts
new-item "c:\Users\$env:username\.ssh\known_hosts" -type file -force
# ssh-keyscan bitbucket.org for a maximum of 10 tries
for ($i=0; $i -le 10; $i++) {
    start-process -filepath "c:\Program Files\Git\usr\bin\ssh-keyscan.exe" -argumentlist ("-4 -T 10 bitbucket.org") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    if ((get-content $provision) -match "bitbucket\.org") {
        echo "ssh-keyscan for bitbucket.org successful"
        get-content $provision | add-content "c:\Users\$env:username\.ssh\known_hosts"
        break
    } else {
        echo "ssh-keyscan for bitbucket.org failed, retrying!"
    }
}
# ssh-keyscan github.com for a maximum of 10 tries
for ($i=0; $i -le 10; $i++) {
    start-process -filepath "c:\Program Files\Git\usr\bin\ssh-keyscan.exe" -argumentlist ("-4 -T 10 github.com") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    if ((get-content $provision) -match "github\.com") {
        echo "ssh-keyscan for github.com successful"
        get-content $provision | add-content "c:\Users\$env:username\.ssh\known_hosts"
        break
    } else {
        echo "ssh-keyscan for github.com failed, retrying!"
    }
}


<# @todo - this hangs more than it should, investigate
echo "`n=> Running Disk Cleanup (This may take a while)..."
# disk cleanup is packaged with the desktop-experience feature
install-windowsfeature Desktop-Experience
# desktop-experience requires a reboot to install
if (test-path -path "$env:SystemRoot\System32\cleanmgr.exe") {
    # http://support.microsoft.com/kb/253597
    $disk_space_before = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
    # set StateFlags0012 setting for each item in Windows 8.1 disk cleanup utility
    $volumeCaches = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    foreach ($key in $volumeCaches) {
        New-ItemProperty -Path "$($key.PSPath)" -Name StateFlags0099 -Value 2 -Type DWORD -Force | Out-Null
    }
    # run disk cleanup
    start-process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/sagerun:99"
    # delete the keys
    $volumeCaches = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    foreach ($key in $volumeCaches) {
        Remove-ItemProperty -Path "$($key.PSPath)" -Name StateFlags0099 -Force | Out-Null
    }
    $disk_space_after = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
    "Free Space Before: {0} GB" -f [math]::round($disk_space_before,2)
    "Free Space After: {0} GB" -f [math]::round($disk_space_after,2)
}
#>


echo "`n=> Checking for Windows Updates (This may take a while)..."
# configure windows update settings
$windows_update_settings = (new-object -com "Microsoft.Update.AutoUpdate").Settings
# 1 - Never check for updates
# 2 - Check for updates but let me choose whether to download and install them
# 3 - Download updates but let me choose whether to install them
# 4 - Install updates automatically
$windows_update_settings.NotificationLevel=4
$windows_update_settings.ScheduledInstallationDay=0
$windows_update_settings.ScheduledInstallationTime=3
$windows_update_settings.IncludeRecommendedUpdates=$true
$windows_update_settings.NonAdministratorsElevated=$true
$windows_update_settings.FeaturedUpdatesEnabled=$true
$windows_update_settings.save()
$windows_update_settings
# ensure we're set to the Microsoft Update Service
echo "Configuring the Microsoft Update Service..."
# Examples Of ServiceID:
# Windows Update                  9482f4b4-e343-43b6-b170-9a65bc822c77 
# Microsoft Update                7971f918-a847-4430-9279-4a52d1efe18d 
# Windows Store                   117cab2d-82b1-4b5a-a08c-4d62dbee7782 
# Windows Server Update Service   3da21691-e39d-4da6-8a4b-b43877bcb1b7 
# Performing the operation "Register Windows Update Service Manager: 7971f918-a847-4430-9279-4a52d1efe18d" on target "DEV-WIN".
# [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y
Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -confirm:$false
# get registered update service
echo "Getting the Microsoft Update Service..."
Get-WUServiceManager
# install latest updates
echo "Checking for Microsoft Updates..."
Get-WUInstall -MicrosoftUpdate -AcceptAll -IgnoreReboot


echo "`n=> Configuring Task Scheduler..."
# configure a weekly task to reboot the system if necessary
$taskname = "REQUIRED REBOOT STATUS"
if (-not(Get-ScheduledTask -TaskName $taskname -ErrorAction SilentlyContinue)) {
    $action = New-ScheduledTaskAction -Execute "c:\catapult\provisioners\windows\modules\system_reboot.ps1"
    $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 3am
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -User "System"
}
