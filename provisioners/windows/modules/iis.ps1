. "c:\catapult\provisioners\windows\modules\catapult.ps1"


echo "`n=> Installing URL Rewrite 2.0"
start-process -filepath "c:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe" -argumentlist "/install /products:""UrlRewrite2"" /accepteula" -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
get-content $provision
get-content $provisionError


echo "`n=> Importing servermanager"
import-module servermanager
if (Get-Module -ListAvailable -Name servermanager) {
    echo "servermanager loaded"
    echo (Get-Module servermanager) | Format-Table -Property Version
} else {
    echo "servermanager failed to load"
}

echo "`n=> Installing web-webserver (This may take a while...)"
add-windowsfeature web-webserver -includeallsubfeature -logpath c:\catapult\provisioners\windows\logs\add-windowsfeature_web-webserver.log


echo "`n=> Installing web-mgmt-tools"
add-windowsfeature web-mgmt-tools -includeallsubfeature -logpath c:\catapult\provisioners\windows\logs\add-windowsfeature_web-mgmt-tools.log


echo "`n=> Importing webadministration"
import-module webadministration
if (Get-Module -ListAvailable -Name webadministration) {
    echo "webadministration loaded"
    echo (Get-Module webadministration) | Format-Table -Property Version
} else {
    echo "webadministration failed to load"
}


echo "`n=> Configuring git repositories (This may take a while...)"
if (-not($configuration.websites.iis)) {

    echo "There are no websites in iis, nothing to do."

} else {

    # initialize id_rsa
    new-item "c:\Program Files (x86)\Git\.ssh\id_rsa" -type file -force
    get-content "c:\catapult\secrets\id_rsa" | add-content "c:\Program Files (x86)\Git\.ssh\id_rsa"

    # initialize known_hosts
    new-item "c:\Program Files (x86)\Git\.ssh\known_hosts" -type file -force
    # ssh-keyscan bitbucket.org for a maximum of 10 tries
    for ($i=0; $i -le 10; $i++) {
        start-process -filepath "c:\Program Files (x86)\Git\bin\ssh-keyscan.exe" -argumentlist ("-4 -T 10 bitbucket.org") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        if ((get-content $provision) -match "bitbucket\.org") {
            echo "ssh-keyscan for bitbucket.org successful"
            get-content $provision | add-content "c:\Program Files (x86)\Git\.ssh\known_hosts"
            break
        } else {
            echo "ssh-keyscan for bitbucket.org failed, retrying!"
        }
    }
    # ssh-keyscan github.com for a maximum of 10 tries
    for ($i=0; $i -le 10; $i++) {
        start-process -filepath "c:\Program Files (x86)\Git\bin\ssh-keyscan.exe" -argumentlist ("-4 -T 10 github.com") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        if ((get-content $provision) -match "github\.com") {
            echo "ssh-keyscan for github.com successful"
            get-content $provision | add-content "c:\Program Files (x86)\Git\.ssh\known_hosts"
            break
        } else {
            echo "ssh-keyscan for github.com failed, retrying!"
        }
    }

    # keep linux lf (line feed) line endings instead of windows converting to crlf (carriage return line feed <- haha, typewriter)
    start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("config --global core.autocrlf false") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError

    # clone/pull repositories into c:\inetpub\repositories\iis\
    if (-not(test-path -path "c:\inetpub\repositories\iis")) {
        new-item -itemtype directory -force -path "c:\inetpub\repositories\iis"
    }
    foreach ($instance in $configuration.websites.iis) {
        if (test-path ("c:\inetpub\repositories\iis\{0}\.git" -f $instance.domain) ) {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config --global user.name {1}" -f $instance.domain,"Catapult") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config --global user.email {1}" -f $instance.domain,$configuration.company.email) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config core.packedGitLimit 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config core.packedGitWindowSize 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.deltaCacheSize 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.packSizeLimit 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.windowMemory 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} reset -q --hard HEAD --" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} checkout ." -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} clean -fd" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} checkout {1}" -f $instance.domain,$configuration.environments.$($args[0]).branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} fetch" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} pull origin {1}" -f $instance.domain,$configuration.environments.$($args[0]).branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} submodule update --init --recursive" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
        } else {
            start-process -filepath "c:\Program Files (x86)\Git\bin\git.exe" -argumentlist ("clone --recursive --branch {1} {2} c:\inetpub\repositories\iis\{0}" -f $instance.domain,$configuration.environments.$($args[0]).branch,$instance.repo) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
            get-content $provision
            get-content $provisionError
        }
    }
    # create an array of domains
    $domains = @()
    foreach ($instance in $configuration.websites.iis) {
        $domains += $instance.domain
    }
    # cleanup directories from domains array
    get-childitem "c:\inetpub\repositories\iis\*" | ?{ $_.PSIsContainer } | foreach-object {
        $domain = split-path $_.FullName -leaf
        if (-not($domains -contains $domain)) {
            echo "`nWebsite does not exist in secrets/configuration.yml, removing $domain ..."
            remove-item -recurse -force $_.FullName
        }
    }

    echo "`n=> Removing SSL Bindings"
    if (get-childitem -path IIS:\SslBindings) {
        $sslbindings = get-childitem -path IIS:\SslBindings
        foreach ($sslbinding in $sslbindings) {
            if ($sslbinding.IPAddress -and $sslbinding.Port -and $sslbinding.Host) {
                remove-item ("IIS:\SslBindings\{0}!{1}!{2}" -f $sslbinding.IPAddress,$sslbinding.Port,$sslbinding.Host) -recurse
            } elseif ($sslbinding.IPAddress -and $sslbinding.Port) {
                remove-item ("IIS:\SslBindings\{0}!{1}" -f $sslbinding.IPAddress,$sslbinding.Port) -recurse
            } elseif ($sslbinding.Port -and $sslbinding.Host) {
                remove-item ("IIS:\SslBindings\!{0}!{1}" -f $sslbinding.Port,$sslbinding.Host) -recurse
            } else {
                echo "could not remove the ssl binding"
                write-host ($sslbinding | format-list | out-string)
            }
        }
    }

    echo "`n=> Removing websites"
    if (get-childitem -path IIS:\Sites | where-object {$_.Name -ne "Default Web Site"}) {
        $websites = get-childitem -path IIS:\Sites | where-object {$_.Name -ne "Default Web Site"}
        foreach ($website in $websites) {
            remove-item ("IIS:\Sites\{0}" -f $website.Name) -recurse
        }
    }

    echo "`n=> Removing application pools"
    if (get-childitem -path IIS:\AppPools | where-object {$_.Name -ne "DefaultAppPool"}) {
        $apppools = get-childitem -path IIS:\AppPools | where-object {$_.Name -ne "DefaultAppPool"}
        foreach ($apppool in $apppools) {
            remove-item ("IIS:\AppPools\{0}" -f $apppool.Name) -recurse
        }
    }

    echo "`n=> Creating application pools"
    foreach ($instance in $configuration.websites.iis) {
        new-item ("IIS:\AppPools\$($args[0]).{0}" -f $instance.domain)
        set-itemproperty ("IIS:\AppPools\$($args[0]).{0}" -f $instance.domain) managedRuntimeVersion v4.0
    }

    echo "`n=> Creating websites"
    foreach ($instance in $configuration.websites.iis) {
        $domain = ("$($args[0]).{0}" -f $instance.domain)
        if ($instance.webroot) {
            $instance.webroot = $instance.webroot.Replace("/","\")
        }
        # 80
        new-website -name ("$($args[0]).{0}" -f $instance.domain) -hostheader ("$($args[0]).{0}" -f $instance.domain) -port 80 -physicalpath ("c:\inetpub\repositories\iis\{0}\{1}" -f $instance.domain,$instance.webroot) -applicationpool ("$($args[0]).{0}" -f $instance.domain) -force

        # 80:www
        new-webbinding -name ("$($args[0]).{0}" -f $instance.domain) -hostheader ("www.$($args[0]).{0}" -f $instance.domain) -port 80

        # 443
        new-webbinding -name ("$($args[0]).{0}" -f $instance.domain) -hostheader ("$($args[0]).{0}" -f $instance.domain) -port 443 -protocol https -sslflags 1

        # 443:www
        new-webbinding -name ("$($args[0]).{0}" -f $instance.domain) -hostheader ("www.$($args[0]).{0}" -f $instance.domain) -port 443 -protocol https -sslflags 1

        # set website user account
        set-itemproperty ("$($args[0]).{0}" -f $instance.domain) -name username -value "$env:username"
        set-itemproperty ("$($args[0]).{0}" -f $instance.domain) -name password -value "$env:username"
    }

    echo "`n=> Creating SSL Bindings"
    foreach ($instance in $configuration.websites.iis) {
        $domain = ("$($args[0]).{0}" -f $instance.domain)
        # create self-signed cert
        $certificate = New-SelfSignedCertificate -DnsName ("$($args[0]).{0}" -f $instance.domain) -CertStoreLocation "cert:\LocalMachine\My"
        # bind self-signed cert to 443
        new-item -path "IIS:\SslBindings\!443!$domain" -value $certificate -sslflags 1 -force
    }

    echo "`n=> Starting websites"
    if (get-childitem -path IIS:\Sites) {
        get-childitem -path IIS:\Sites | foreach { start-website $_.Name; }
    }
    foreach ($instance in $configuration.websites.iis) {
        echo ("http://$($args[0]).{0}" -f $instance.domain)
    }

}
