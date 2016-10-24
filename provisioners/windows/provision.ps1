# variables inbound from provisioner args
# $($args[0]) => environment
# $($args[1]) => repository
# $($args[2]) => gpg key
# $($args[3]) => instance



# global
$provisionError = "c:\tmp\provisionError.log"
$provision = "c:\tmp\provision.log"



echo "`n`n`n==> SYSTEM INFORMATION"

# who are we?
Get-WmiObject -Class Win32_ComputerSystem



echo "`n`n`n==> INSTALLING MINIMAL DEPENDENCIES"

# download git
echo "`n=> Downloading Git..."
if (-not(test-path -path "c:\tmp\Git-2.10.1-64-bit.exe")) {
    $url = "https://github.com/git-for-windows/git/releases/download/v2.10.1.windows.1/Git-2.10.1-64-bit.exe"
    $output = "c:\tmp\Git-2.10.1-64-bit.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
} else {
    echo "- Installer exists, skipping download..."
}

# install git
echo "`n=> Installing Git"
if (-not(test-path -path "c:\Program Files\Git\bin\git.exe")) {
    start-process -filepath "c:\tmp\Git-2.10.1-64-bit.exe" -argumentlist "/SP- /NORESTART /VERYSILENT /SUPPRESSMSGBOXES /SAVEINF=c:\tmp\git-settings.txt /LOG=c:\tmp\Git-2.10.1-64-bit.exe.log" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
    get-content $provision
    get-content $provisionError
}
start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist "--version" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError



echo "`n`n`n==> RECEIVING CATAPULT"

# what are we receiving?
echo "=> ENVIRONMENT: $($args[0])"
echo "=> REPOSITORY: $($args[1])"
echo "=> GPG KEY: ************"
echo "=> INSTANCE:$($args[3])"

# define the branch
if ($($args[0]) -eq "production") {
    $branch = "master"
} elseif ($($args[0]) -eq "qc") {
    $branch = "release"
} else {
    $branch = "develop"
}
# get the catapult instance
if ($($args[0]) -eq "dev") {
    if (-not(test-path -path "c:\catapult\secrets\configuration.yml.gpg")) {
        echo "Cannot read from /catapult/secrets/configuration.yml.gpg, please vagrant reload the virtual machine."
        exit 1
    } else {
        echo "Your Catapult instance is being synced from your host machine."
    }
} else {
    if (test-path -path "c:\catapult\.git") {
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\catapult checkout {0}" -f $branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\catapult fetch") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\catapult pull") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
    } else {
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("clone --recursive --branch {0} {1} c:\catapult" -f $branch,$($args[1])) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
    }
}


echo "`n`n`n==> STARTING PROVISION"

# provision the server
powershell -file "c:\catapult\provisioners\windows\provision_server.ps1" $args[0] $args[1] $args[2] $args[3]
