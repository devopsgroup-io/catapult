. "c:\catapult\provisioners\windows\modules\catapult.ps1"


if (-not(Get-Service -Name "nrsvrmon" -ErrorAction SilentlyContinue)) {
    echo "New Relic Server Monitor Service is not running, installing..."
    # the unadvertised arg NR_HOST=<host name> is also available, retaining the windows hostname due to the 15 char limit
    msiexec /i "c:\catapult\provisioners\windows\installers\NewRelicServerMonitor_x64_3.3.6.0.msi" /L*v "c:\catapult\provisioners\windows\logs\NewRelicServerMonitor_x64_3.3.6.0.msi.log" /qn NR_LICENSE_KEY=$($configuration.company.newrelic_license_key)
} else {
    echo "New Relic Server Monitor Service is running, skipping install..."
}
