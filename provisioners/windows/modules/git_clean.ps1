. "c:\catapult\provisioners\windows\modules\catapult.ps1"


# remove directories from c:\inetpub\repositories\iis\ that no longer exist in configuration
# create an array of domains
$domains = @()
foreach ($instance in $configuration.websites.iis) {
    $domains += $instance.domain
}
# cleanup directories from domains array
if (test-path -path "c:\inetpub\repositories\iis\") {
    get-childitem "c:\inetpub\repositories\iis\*" | ?{ $_.PSIsContainer } | foreach-object {
        $domain = split-path $_.FullName -leaf
        if (-not($domains -contains $domain)) {
            echo "`nRemoving the $($_.FullName) directory as it does not exist in your configuration..."
            remove-item -recurse -force $_.FullName
        }
    }
}
