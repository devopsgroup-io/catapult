function Add-CastingFunctions($value) {
    if ($PSVersionTable.PSVersion -ge "3.0") { return $value }
    return Add-CastingFunctionsForPosh2($value)
}

function Add-CastingFunctionsForPosh2($value) {
    return Add-Member -InputObject $value -Name ToInt `
           -MemberType ScriptMethod -PassThru -Value `
           { [int] $this } |
           Add-Member -Name ToLong `
           -MemberType ScriptMethod -PassThru -Value `
           { [long] $this } |
           Add-Member -Name ToDouble `
           -MemberType ScriptMethod -PassThru -Value `
           { [double] $this } |
           Add-Member -Name ToDecimal `
           -MemberType ScriptMethod -PassThru -Value `
           { [decimal] $this } |
           Add-Member -Name ToByte `
           -MemberType ScriptMethod -PassThru -Value `
           { [byte] $this } |
           Add-Member -Name ToBoolean `
           -MemberType ScriptMethod -PassThru -Value `
           { [System.Boolean]::Parse($this) }
}
