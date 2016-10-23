. "c:\catapult\provisioners\windows\modules\catapult.ps1"


# domain
if ($configuration.websites.iis.length -gt 1) {
    $domain = $configuration.websites.iis[$($args[4])].domain
} else {
    $domain = $configuration.websites.iis.domain
}

# domain_tld_override
if ($configuration.websites.iis.length -gt 1) {
    $domain_tld_override = $configuration.websites.iis[$($args[4])].domain_tld_override
} else {
    $domain_tld_override = $configuration.websites.iis.domain_tld_override
}

# create an array of domains
$domains = @()
if ([string]::IsNullOrEmpty($domain_tld_override)) {
    $domains += "$domain"
} else {
    $domains += "$domain"
    $domains += "$domain.$domain_tld_override"
}

$valid_http_response_codes = @("200","400")

foreach ($domain in $domains) {

    # create array from domain
    $domain_levels = $domain -split "\."

    # try and create the zone and let cloudflare handle if it already exists
    $data = @{
        "name" = "$($domain_levels[-2]).$($domain_levels[-1])";
        "jumpstart" = ([System.Convert]::ToBoolean("false"))
    }
    $headers = @{
        "X-Auth-Email" = $configuration.company.cloudflare_email;
        "X-Auth-Key" = $configuration.company.cloudflare_api_key;
    }
    try {
        $result = invoke-webrequest -usebasicparsing -method Post -uri "https://api.cloudflare.com/client/v4/zones" `
            -ContentType "application/json" `
            -Headers $headers `
            -Body (ConvertTo-Json $data)
        $cloudflare_zone = $result.Content
        $cloudflare_zone_status = $result.StatusCode
    } catch {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $cloudflare_zone = $reader.ReadToEnd();
        $cloudflare_zone_status = [int][system.net.httpstatuscode]::$($_.Exception.Response.StatusCode)
    }

    # output the result
    if ( -not($valid_http_response_codes -contains $cloudflare_zone_status) ) {
        echo "[$cloudflare_zone_status] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
    } elseif ( "$($cloudflare_zone | ConvertFrom-Json | select -ExpandProperty success)" -eq "False" ) {
        echo "[$($domain_levels[-2]).$($domain_levels[-1])] $($cloudflare_zone | ConvertFrom-Json | select -ExpandProperty errors | Select-Object -first 1 | select -ExpandProperty message)"
    } else {
        echo "[$($domain_levels[-2]).$($domain_levels[-1])] successfully created zone"
    }
}
