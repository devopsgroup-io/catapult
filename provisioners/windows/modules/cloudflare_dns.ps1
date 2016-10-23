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
    $headers = @{
        "X-Auth-Email" = $configuration.company.cloudflare_email;
        "X-Auth-Key" = $configuration.company.cloudflare_api_key;
    }
    try {
        $result = invoke-webrequest -usebasicparsing -method Get -uri "https://api.cloudflare.com/client/v4/zones?name=$($domain_levels[-2]).$($domain_levels[-1])" `
            -ContentType "application/json" `
            -Headers $headers
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
    } elseif ( "$($cloudflare_zone | ConvertFrom-Json | select -ExpandProperty result)" -eq "" ) {
        echo "[$($domain_levels[-2]).$($domain_levels[-1])] cloudflare zone does not exist"
    } else {
        echo "[$($domain_levels[-2]).$($domain_levels[-1])] cloudflare zone exists, managing dns records..."

        # create an array of dns records
        $domain_dns_records = @()
        if ($($args[0]) -eq "production") {
            $domain_dns_records += "$domain"
            $domain_dns_records += "www.$domain"
        } else {
            $domain_dns_records += "$($args[0]).$domain"
            $domain_dns_records += "www.$($args[0]).$domain"
        }

        foreach ($domain_dns_record in $domain_dns_records) {

            # get the cloudflare zone id
            $cloudflare_zone_id = "$($cloudflare_zone | ConvertFrom-Json | select -ExpandProperty result | Select-Object -first 1 | select -ExpandProperty id)"
            
            # determine if dns a record exists
            $headers = @{
                "X-Auth-Email" = $configuration.company.cloudflare_email;
                "X-Auth-Key" = $configuration.company.cloudflare_api_key;
            }
            try {
                $result = invoke-webrequest -usebasicparsing -method Get -uri "https://api.cloudflare.com/client/v4/zones/$($cloudflare_zone_id)/dns_records?type=A&name=$($domain_dns_record)" `
                    -ContentType "application/json" `
                    -Headers $headers
                $dns_record = $result.Content
                $dns_record_status = $result.StatusCode
            } catch {
                $result = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($result)
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $dns_record = $reader.ReadToEnd();
                $dns_record_status = [int][system.net.httpstatuscode]::$($_.Exception.Response.StatusCode)
            }

            # calculate the amount of subdomains to then use as a determination between being cloudflare proxied or not in order to support SSL (cloudflare only supports one subdomain level)
            $domain_levels = $domain_dns_record -split "\."
            if ( $domain_levels.length -gt 3 ) {
                $cloudflare_proxied = "false"
            } else {
                $cloudflare_proxied = "true"
            }

            # create or update the dns a record
            if ( -not($valid_http_response_codes -contains $cloudflare_zone_status) ) {
                echo "[$dns_record_status] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
            } else {
                # create dns a record
                if ( "$($dns_record | ConvertFrom-Json | select -ExpandProperty result)" -eq "" ) {
                    $data = @{
                        "type" = "A";
                        "name" = "$($domain_dns_record)";
                        "content" = "$($configuration.environments.$($args[0]).servers.windows.ip)";
                        "ttl" = 1;
                        "proxied" = ([System.Convert]::ToBoolean($cloudflare_proxied));
                    }
                    $headers = @{
                        "X-Auth-Email" = $configuration.company.cloudflare_email;
                        "X-Auth-Key" = $configuration.company.cloudflare_api_key;
                    }
                    try {
                        $result = invoke-webrequest -usebasicparsing -method Post -uri "https://api.cloudflare.com/client/v4/zones/$($cloudflare_zone_id)/dns_records" `
                            -ContentType "application/json" `
                            -Headers $headers `
                            -Body (ConvertTo-Json $data)
                        $dns_record = $result.Content
                        $dns_record_status = $result.StatusCode
                    } catch {
                        $result = $_.Exception.Response.GetResponseStream()
                        $reader = New-Object System.IO.StreamReader($result)
                        $reader.BaseStream.Position = 0
                        $reader.DiscardBufferedData()
                        $dns_record = $reader.ReadToEnd();
                        $dns_record_status = [int][system.net.httpstatuscode]::$($_.Exception.Response.StatusCode)
                    }
                # update dns a record
                } else {
                    $dns_record_id = "$($dns_record | ConvertFrom-Json | select -ExpandProperty result | Select-Object -first 1 | select -ExpandProperty id)"
                    $data = @{
                        "id" = "$($dns_record_id)";
                        "type" = "A";
                        "name" = "$($domain_dns_record)";
                        "content" = "$($configuration.environments.$($args[0]).servers.windows.ip)";
                        "ttl" = 1;
                        "proxied" = ([System.Convert]::ToBoolean($cloudflare_proxied));
                    }
                    $headers = @{
                        "X-Auth-Email" = $configuration.company.cloudflare_email;
                        "X-Auth-Key" = $configuration.company.cloudflare_api_key;
                    }
                    try {
                        $result = invoke-webrequest -usebasicparsing -method Put -uri "https://api.cloudflare.com/client/v4/zones/$($cloudflare_zone_id)/dns_records/$($dns_record_id)" `
                            -ContentType "application/json" `
                            -Headers $headers `
                            -Body (ConvertTo-Json $data)
                        $dns_record = $result.Content
                        $dns_record_status = $result.StatusCode
                    } catch {
                        $result = $_.Exception.Response.GetResponseStream()
                        $reader = New-Object System.IO.StreamReader($result)
                        $reader.BaseStream.Position = 0
                        $reader.DiscardBufferedData()
                        $dns_record = $reader.ReadToEnd();
                        $dns_record_status = [int][system.net.httpstatuscode]::$($_.Exception.Response.StatusCode)
                    }
                }
                # output the result
                if ( -not($valid_http_response_codes -contains $cloudflare_zone_status) ) {
                    echo "[$dns_record_status] there was a problem with the cloudflare api request - please visit https://www.cloudflarestatus.com to see if there is a problem"
                } elseif ( "$($dns_record | ConvertFrom-Json | select -ExpandProperty success)" -eq "False" ) {
                    echo "[$domain_dns_record] $($dns_record | ConvertFrom-Json | select -ExpandProperty errors | Select-Object -first 1 | select -ExpandProperty message)"
                } else {
                    echo "[$domain_dns_record] successfully set dns a record"
                }

            }

        }

    }

}
