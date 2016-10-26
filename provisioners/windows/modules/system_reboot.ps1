$objSystemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"
if ($objSystemInfo.RebootRequired) {
    restart-computer
}
