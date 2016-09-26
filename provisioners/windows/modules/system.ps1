. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Configuring hostname"
# set the base hostname limited by the 15 character limit (UGH)
if ($($args[0].Text.Length) -gt 4) {
    $hostname = "$($args[0].Substring(0,4))-win"
} else {
    $hostname = "$($args[0])-win"
}
# set hostname, 
if ($($args[3]) -eq "iis") {
    if ($env:computername.ToLower() -ne "$($hostname)") {
        Rename-Computer -Force -NewName "$($hostname)"
    }
} elseif (($args[3]) -eq "mssql") {
    if ($env:computername.ToLower() -ne "$($hostname)-mssql") {
        Rename-Computer -Force -NewName "$($hostname)-mssql"
    }
}
# echo datetimezone
echo $env:computername


echo "`n=> Configuring system page file"
# let windows manage our page file for us for now
wmic computersystem set AutomaticManagedPageFile=TRUE
echo "Allocated: $(get-wmiobject win32_pagefileusage | % {$_.allocatedbasesize})MB"
echo "Current: $(get-wmiobject win32_pagefileusage | % {$_.currentusage})MB"
echo "Peak: $(get-wmiobject win32_pagefileusage | % {$_.peakusage})MB"


echo "`n=> Importing PSWindowsUpdate"
Remove-Item "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate" -Force -Recurse
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("c:\catapult\provisioners\windows\installers\PSWindowsUpdate.zip", "C:\Windows\System32\WindowsPowerShell\v1.0\Modules")
Import-Module PSWindowsUpdate
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    echo "PSWindowsUpdate loaded"
    echo (Get-Module PSWindowsUpdate) | Format-Table -Property Version
} else {
    echo "PSWindowsUpdate failed to load"
}
#Set-ExecutionPolicy RemoteSigned


echo "`n=> Installing Windows Updates (This may take a while...)"
# install latest updates
Get-WUInstall -WindowsUpdate -AcceptAll -IgnoreReboot
echo "A reboot (LocalDev: vagrant reload) may be required after windows updates"
# @todo check for reboot status


echo "`n=> Installing .NET 4.0 (This may take a while...)"
if (-not(test-path -path "c:\windows\Microsoft.NET\Framework64\v4.0.30319\")) {
    # ((new-object net.webclient).DownloadFile("http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe","c:\tmp\dotNetFx40_Full_x86_x64.exe"))
    start-process -filepath "c:\catapult\provisioners\windows\installers\dotNetFx40_Full_x86_x64.exe" -argumentlist "/q /norestart /log c:\catapult\provisioners\windows\logs\dotNetFx40_Full_x86_x64.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    echo "Restarting Windows..."
    echo "Please invoke 'vagrant provision' when it's back up"
    restart-computer -force
    exit 0
}
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release


echo "`n=> Installing Web Platform Installer (This may take a while...)"
# http://www.iis.net/learn/install/web-platform-installer/web-platform-installer-v4-command-line-webpicmdexe-rtw-release
if (-not(test-path -path "c:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe")) {
    # https://github.com/fdcastel/psunattended/blob/master/PSUnattended.ps1
    start-process -filepath msiexec -argumentlist "/i ""c:\catapult\provisioners\windows\installers\WebPlatformInstaller_amd64_en-US.msi"" /q ALLUSERS=1 REBOOT=ReallySuppress" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
}
