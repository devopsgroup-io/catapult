. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Configuring timezone"
# set timezone
tzutil /s $configuration.company.timezone_windows
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
echo $([System.TimeZone]::CurrentTimeZone.StandardName)
