. "c:\catapult\provisioners\windows\modules\catapult.ps1"


$mssql_user = $configuration.environments.$($args[0]).servers.windows_mssql.mssql.user
$mssql_user_password = $configuration.environments.$($args[0]).servers.windows_mssql.mssql.user_password
$mssql_sa_password = $configuration.environments.$($args[0]).servers.windows_mssql.mssql.sa_password


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
    start-process -filepath "c:\catapult\provisioners\windows\installers\temp\SQLEXPRWT_x64_ENU\setup.exe" -argumentlist ("/IACCEPTSQLSERVERLICENSETERMS /SQLSYSADMINACCOUNTS={1} /SAPWD={0} /SQLSVCPASSWORD={0} /AGTSVCPASSWORD={0} /ASSVCPASSWORD={0} /ISSVCPASSWORD={0} /RSSVCPASSWORD={0} /ConfigurationFile=c:\catapult\provisioners\windows\installers\MicrosoftSQLServer\ConfigurationFile.ini" -f $mssql_sa_password,"$($hostname)\$($env:username)") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
    $directory_latest = Get-ChildItem -Path "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log" | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $summary_latest = Get-ChildItem "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\$directory_latest" | Where-Object {$_.Name -match "^Summary"} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    get-content "c:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\$directory_latest\$summary_latest"
    # the installer requires a cool down period to allow for garbage cleanup, services to start, etc
    echo "- Mandatory 30 second post-install cool down period, please wait..."
    start-sleep -s 30
    start-service 'MSSQL$SQLEXPRESS'
    restart-service 'MSSQL$SQLEXPRESS' -Force
 } else {
     echo "- Installed, skipping..."
 }
 
 
echo "`n=> Managing SQL Server Logins..."
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$server = new-object ("Microsoft.SqlServer.Management.Smo.Server") -ArgumentList "localhost\SQLEXPRESS"
# manage login of sa
$login = $server.Logins | ? {$_.Name -eq "sa"}
$login.ChangePassword($mssql_sa_password)
$login.PasswordPolicyEnforced = $false
$login.PasswordExpirationEnabled = $false
$login.Alter()
$login.Refresh()
# manage login of environment mssql user
if ($server.Logins.name -notcontains $mssql_user) {
    $login = new-object Microsoft.SqlServer.Management.Smo.Login($server, $mssql_user)
    $login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
    $login.PasswordPolicyEnforced = $false
    $login.PasswordExpirationEnabled = $false
    $login.Create($mssql_user_password)
}
$login = $server.Logins | ? {$_.Name -eq $mssql_user}
$login.ChangePassword($mssql_user_password)
$login.PasswordPolicyEnforced = $false
$login.PasswordExpirationEnabled = $false
$login.Alter()
$login.Refresh()
 

echo "`n=> Managing SQL Server Databases..."
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$server = new-object ("Microsoft.SqlServer.Management.Smo.Server") -ArgumentList "localhost\SQLEXPRESS"

# create an array of domainvaliddbnames
$domainvaliddbnames = @("master","model","msdb","tempdb")
foreach ($instance in $configuration.websites.iis) {
    $domainvaliddbname = ("{0}_{1}" -f $($args[0]), $instance.domain -replace "\.","_")
    $domainvaliddbnames += $domainvaliddbname
}
# cleanup databases from domainvaliddbnames array
foreach ($database in $server.Databases.name) {
    if ($domainvaliddbnames -notcontains $database) {
        echo "Removing the $($database) database as it does not exist in your configuration..."
        $server.KillAllProcesses($database)
        $database = $server.Databases[$database]
        $database.Drop()
    }
}

# create databases
foreach ($instance in $configuration.websites.iis) {
    $domainvaliddbname = ("{0}_{1}" -f $($args[0]), $instance.domain -replace "\.","_")
    # manage the database
    if ($server.Databases.name -notcontains $domainvaliddbname) {
        $database = new-object Microsoft.SqlServer.Management.Smo.Database($server, $domainvaliddbname)
        $database.Create()
    }
    # manage user of environment mssql user
    $database = $server.Databases[$domainvaliddbname];
    if ($database.Users.name -notcontains $mssql_user) {
        # add user to database
        $user = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($database, $mssql_user)
        $user.Login = $mssql_user
        $user.Create()
    }
    # grant roles to environment mssql user
    # see fancy chart of roles (note mssql version) https://msdn.microsoft.com/en-us/library/ms189121.aspx
    $role = $database.Roles["db_ddladmin"]
    $role.AddMember($mssql_user)
    $role.Alter()
    $role = $database.Roles["db_datareader"]
    $role.AddMember($mssql_user)
    $role.Alter()
    $role = $database.Roles["db_datawriter"]
    $role.AddMember($mssql_user)
    $role.Alter()
}


echo "`n=> Enabling TCP/IP for SQL Server..."
# required to load by file for first provision, the path is not yet added
if (Get-Module -ListAvailable -Name sqlps -ErrorAction SilentlyContinue) {
    import-module sqlps
} else {
    $env:PSModulePath = $env:PSModulePath + ";C:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules"
    import-module sqlps
}
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo.Wmi") | Out-Null
# http://blog.citrix24.com/configure-sql-express-to-accept-remote-connections/
$server = new-object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') -ArgumentList "localhost"
$tcp = $server.GetSmoObject("ManagedComputer[@Name='localhost']/ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']")
$tcp.IsEnabled = $true
$server.GetSmoObject("ManagedComputer[@Name='localhost']/ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']/IPAddress[@Name='IPAll']").IPAddressProperties[0].Value=""
$server.GetSmoObject("ManagedComputer[@Name='localhost']/ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']/IPAddress[@Name='IPAll']").IPAddressProperties[1].Value="1433"
$tcp.Alter()


echo "`n=> Configuring firewall for SQL Server..."
if (-not(Get-NetFirewallRule -DisplayName "SQL Server" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort "1433" -Action Allow
}
Get-NetFirewallRule -DisplayName "SQL Server"


echo "`n=> Restarting SQL Server..."
restart-service 'MSSQL$SQLEXPRESS' -Force
