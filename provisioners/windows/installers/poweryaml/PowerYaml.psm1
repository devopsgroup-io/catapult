. $PSScriptRoot\Functions\Casting.ps1
. $PSScriptRoot\Functions\Shadow-Copy.ps1
. $PSScriptRoot\Functions\YamlDotNet-Integration.ps1
. $PSScriptRoot\Functions\Validator-Functions.ps1

<# 
 .Synopsis
  Returns an object that can be dot navigated

 .Parameter FromFile
  File reference to a yaml document

 .Parameter FromString
  Yaml string to be converted
#>
function Get-Yaml([string] $FromString = "", [string] $FromFile = "") {
    if ($FromString -ne "") {
        $yaml = Get-YamlDocumentFromString $FromString
    } elseif ($FromFile -ne "") {
        if ((Validate-File $FromFile)) {
            $yaml = Get-YamlDocument -file $FromFile
        }
    }

    return Explode-Node $yaml.RootNode
}

Load-YamlDotNetLibraries (Join-Path $PSScriptRoot -ChildPath "Libs")
Export-ModuleMember -Function Get-Yaml 
