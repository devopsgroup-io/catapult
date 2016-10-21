. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Downloading SQL Server 2014 Express Edition (This may take a while)..."
if (-not(test-path -path "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe")) {
    $url = "https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/ExpressAndTools%2064BIT/SQLEXPRWT_x64_ENU.exe"
    $output = "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} else {
    echo "- Installer exists, skipping download..."
}


echo "`n=> Extracting SQL Server 2014 Express Edition (This may take a while)..."
if (-not(test-path -path "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU\")) {
    start-process -filepath "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU.exe" -argumentlist "/Q /x:c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
} else {
    echo "- Installer extracted, skipping..."
}


echo "`n=> Installing SQL Server 2014 Express Edition (This may take a while)..."
if (-not(test-path -path "c:\Program Files\Microsoft SQL Server\MSSQL12.SQLEXPRESS\MSSQL\")) {
    # ini file setup
    # https://msdn.microsoft.com/en-us/library/dd239405(v=sql.120).aspx
    # setup parameters
    # https://msdn.microsoft.com/en-us/library/ms144259(v=sql.120).aspx
    start-process -filepath "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU\setup.exe" -argumentlist ("/IACCEPTSQLSERVERLICENSETERMS /SAPWD={0} /SQLSVCPASSWORD={0} /AGTSVCPASSWORD={0} /ASSVCPASSWORD={0} /ISSVCPASSWORD={0} /RSSVCPASSWORD={0} /ConfigurationFile=c:\catapult\provisioners\windows\installers\MicrosoftSQLServer\ConfigurationFile.ini" -f $configuration.environments.$($args[0]).servers.windows_mssql.mssql.sa_password) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    $directory_latest = Get-ChildItem -Path "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log" | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $summary_latest = Get-ChildItem "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\$directory_latest" | Where-Object {$_.Name -match "^Summary"} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    get-content "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\$directory_latest\$summary_latest"
    # the installer requires a cool down period to allow for garbage cleanup, services to start, etc
    echo "- Mandatory 30 second post-install cool down period, please wait..."
    start-sleep -s 30
} else {
    echo "- Installed, skipping..."
}


echo "`n=> Enabling TCP/IP for SQL Server..."
Import-Module "sqlps"
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer').
# List the object properties, including the instance names.
$wmi
# Enable the TCP protocol on the default instance.
$uri = "ManagedComputer[@Name='" + (get-item env:\computername).Value + "']/ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']"
$tcp = $wmi.GetSmoObject($uri)
$tcp.IsEnabled = $true
$tcp.Alter()
$tcp


echo "`n=> Configuring firewall for SQL Server..."
if (-not(Get-NetFirewallRule -DisplayName "SQL Server")) {
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort "1433" -Action Allow
}


echo "`n=> Restarting SQL Server..."
Restart-Service 'MSSQL$SQLEXPRESS' -Force
