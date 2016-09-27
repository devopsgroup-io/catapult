. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Downloading SQL Server 2014 Express Edition..."
if (-not(test-path -path "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe")) {
    $url = "https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/ExpressAndTools%2064BIT/SQLEXPRWT_x64_ENU.exe"
    $output = "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} else {
    echo "- Installer exists, skipping download..."
}


echo "`n=> Installing SQL Server 2014 Express Edition..."
if (-not(test-path -path "c:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\")) {
    # https://msdn.microsoft.com/en-us/library/ms144259(v=sql.120).aspx
    start-process -filepath "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe" -argumentlist "/ACTION=install /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SQL /INSTANCENAME=MSSQLSERVER /Q" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    get-content "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\Summary.txt"
} else {
    echo "- Installed, skipping..."
}


echo "`n=> Enabling TCP/IP for SQL Server..."
Import-Module "sqlps"
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer').
# List the object properties, including the instance names.
$Wmi
# Enable the TCP protocol on the default instance.
$uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
$Tcp.IsEnabled = $true
$Tcp.Alter()
$Tcp


echo "`n=> Configuring firewall for SQL Server..."
if (-not(Get-NetFirewallRule -DisplayName "SQL Server")) {
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort "1433" -Action Allow
}


echo "`n=> Restarting SQL Server..."
Restart-Service 'MSSQLSERVER' -Force
