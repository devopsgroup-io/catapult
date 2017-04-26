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


echo "`n=> Installing web-webserver (This may take a while)..."
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


echo "`n=> Configuring IIS"
# remove revealing headers
$headers = @{
    "RESPONSE_X-AspNet-Version" = "ASP.NET";
    "RESPONSE_X-AspNetMvc-Version" = "ASP.NET";
    "RESPONSE_X-Powered-By" = "ASP.NET";
    "RESPONSE_SERVER" = "Microsoft-IIS";
}
foreach ($header in $headers.GetEnumerator()) {
    if (-not(get-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundrules/rule[@name='$($header.Name)']" -name ".")) {
        add-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundrules" -name "." -value @{name=$($header.Name)}
    }
    set-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundRules/rule[@name='$($header.Name)']/match" -name "serverVariable" -value "$($header.Name)"
    set-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundRules/rule[@name='$($header.Name)']/match" -name "pattern" -value ".*"
    set-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundRules/rule[@name='$($header.Name)']/action" -name "type" -value "Rewrite"
    set-webconfigurationproperty -pspath "iis:\" -filter "system.webServer/rewrite/outboundRules/rule[@name='$($header.Name)']/action" -name "value" -value "$($header.Value)"
}
# display errors on screen using the default recommendations for development and production
if ($($args[0]) -eq "dev") {
    set-webconfigurationproperty -filter "system.webserver/httperrors" -pspath "MACHINE/WEBROOT/APPHOST" -name "errorMode" -value "Detailed"
} else {
    set-webconfigurationproperty -filter "system.webserver/httperrors" -pspath "MACHINE/WEBROOT/APPHOST" -name "errorMode" -value "DetailedLocalOnly"
}
# create IIS_AUTH group for IIS basic auth users
$connection = [ADSI]("WinNT://$env:COMPUTERNAME")
if (-not($connection.children | where { $_.schemaClassName -eq "group" } | where { $_.Name -eq "IIS_AUTH" })) {
    $group = $connection.create("group", "IIS_AUTH")
    $group.setinfo()
    $group.description = "Group used by IIS basic authentication users."
    $group.setinfo()
}
# remove all users in the IIS_AUTH group
$group = $connection.Children.Find("IIS_AUTH", "group")
$group.psbase.invoke('members')  | ForEach {
  $user = $_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)
  $connection.delete("user", $user)
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
    if ($($args[0]) -eq "production") {
        $domain = ("{0}" -f $instance.domain)
    } else {
        $domain = ("$($args[0]).{0}" -f $instance.domain)
    }
    new-item ("IIS:\AppPools\{0}" -f $domain)
    set-itemproperty ("IIS:\AppPools\{0}" -f $domain) managedRuntimeVersion v4.0

    # grant application pool user permissions to website directory
    $acl = Get-Acl -Path ("c:\inetpub\repositories\iis\{0}\{1}" -f $instance.domain,$instance.webroot)
    $perm = ("IIS AppPool\{0}" -f $domain), 'Read,Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
    $acl.SetAccessRule($rule)
    $acl | Set-Acl -Path ("c:\inetpub\repositories\iis\{0}\{1}" -f $instance.domain,$instance.webroot)
}


echo "`n=> Creating websites"
foreach ($instance in $configuration.websites.iis) {
    if ($($args[0]) -eq "production") {
        $domain = ("{0}" -f $instance.domain)
    } else {
        $domain = ("$($args[0]).{0}" -f $instance.domain)
    }
    if ($instance.webroot) {
        $instance.webroot = $instance.webroot.Replace("/","\")
    }
    # 80
    new-website -name ("{0}" -f $domain) -hostheader ("{0}" -f $domain) -port 80 -physicalpath ("c:\inetpub\repositories\iis\{0}\{1}" -f $instance.domain,$instance.webroot) -applicationpool ("{0}" -f $domain) -force
    # 80:www
    new-webbinding -name ("{0}" -f $domain) -hostheader ("www.{0}" -f $domain) -port 80
    # 443
    new-webbinding -name ("{0}" -f $domain) -hostheader ("{0}" -f $domain) -port 443 -protocol https -sslflags 1
    # 443:www
    new-webbinding -name ("{0}" -f $domain) -hostheader ("www.{0}" -f $domain) -port 443 -protocol https -sslflags 1
    # add listeners for domain_tld_override if applicable
    if ($instance.domain_tld_override) {
        # 80
        new-webbinding -name ("{0}" -f $domain) -hostheader ("{0}.{1}" -f $domain,$instance.domain_tld_override) -port 80
        # 80:www
        new-webbinding -name ("{0}" -f $domain) -hostheader ("www.{0}.{1}" -f $domain,$instance.domain_tld_override) -port 80
        # 443
        new-webbinding -name ("{0}" -f $domain) -hostheader ("{0}.{1}" -f $domain,$instance.domain_tld_override) -port 443 -protocol https -sslflags 1
        # 443:www
        new-webbinding -name ("{0}" -f $domain) -hostheader ("www.{0}.{1}" -f $domain,$instance.domain_tld_override) -port 443 -protocol https -sslflags 1
    }
    # manage http basic authentication
    if (($instance.force_auth) -and (-not($instance.force_auth_exclude -contains $($args[0])))) {
        # only create the IIS_AUTH user if it does not yet exist (websites can have same force_auth value and user/pass are made the same)
        $connection = [ADSI]("WinNT://$env:COMPUTERNAME")
        if (-not($connection.children | where { $_.schemaClassName -eq "user" } | where { $_.Name -eq $instance.force_auth })) {
            $user = $connection.create("user", $instance.force_auth)
            $user.SetPassword($instance.force_auth)
            $user.SetInfo()
            $user.FullName = $instance.force_auth
            $user.SetInfo()
            $user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
            $user.SetInfo()
            $group = $connection.Children.Find("IIS_AUTH", "group")
            $group.Add("WinNT://$($env:COMPUTERNAME)/$($instance.force_auth)")
            set-webconfigurationproperty -filter "system.webServer/security/authentication/anonymousAuthentication" -pspath "IIS:\" -location ("{0}" -f $domain) -name Enabled -value False
            set-webconfigurationproperty -filter "system.webServer/security/authentication/basicAuthentication" -pspath "IIS:\" -location ("{0}" -f $domain) -name Enabled -value True
        }
    } else {
        set-webconfigurationproperty -filter "system.webServer/security/authentication/anonymousAuthentication" -pspath "IIS:\" -location ("{0}" -f $domain) -name Enabled -value True
        set-webconfigurationproperty -filter "system.webServer/security/authentication/basicAuthentication" -pspath "IIS:\" -location ("{0}" -f $domain) -name Enabled -value False
    }
}


echo "`n=> Creating SSL Bindings"
foreach ($instance in $configuration.websites.iis) {
    if ($($args[0]) -eq "production") {
        $domain = ("{0}" -f $instance.domain)
    } else {
        $domain = ("$($args[0]).{0}" -f $instance.domain)
    }
    if ($instance.domain_tld_override) {
        # create self-signed cert
        $certificate = New-SelfSignedCertificate -DnsName ("{0}.{1}" -f $domain,$instance.domain_tld_override) -CertStoreLocation "cert:\LocalMachine\My"
        # bind self-signed cert to 443
        new-item -path ("IIS:\SslBindings\!443!{0}.{1}" -f $domain,$instance.domain_tld_override) -value $certificate -sslflags 1 -force
    } else {
        # create self-signed cert
        $certificate = New-SelfSignedCertificate -DnsName ("{0}" -f $domain) -CertStoreLocation "cert:\LocalMachine\My"
        # bind self-signed cert to 443
        new-item -path ("IIS:\SslBindings\!443!{0}" -f $domain) -value $certificate -sslflags 1 -force
    }
}


echo "`n=> Starting websites"
if (get-childitem -path IIS:\Sites) {
    get-childitem -path IIS:\Sites | foreach { start-website $_.Name; }
}
foreach ($instance in $configuration.websites.iis) {
    echo ("http://{0}" -f $instance.domain)
}
