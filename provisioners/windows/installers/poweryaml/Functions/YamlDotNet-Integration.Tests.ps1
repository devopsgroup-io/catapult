$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Casting.ps1"
. "$here\Shadow-Copy.ps1"
. "$here\YamlDotNet-Integration.ps1"

$libDir = "$here\..\Libs"
Describe "Load-YamlDotNetLibraries" {

    Setup -Dir "Libs"
    Copy-Item "$libDir\*.dll" "$TestDrive\Libs"

    It "loads assemblies in a way that the dll's can be deleted after loading" {
        $testLibDir = "$TestDrive\Libs"
        Load-YamlDotNetLibraries $testLibDir
        Remove-Item $testLibDir -Recurse
        $testLibDir | Should Not Exist
    }
}

#Note The rest of the tests are dependent on the above test passing :-(
Describe "Convert-YamlScalarNodeToValue" {

    It "takes a YamlScalar and converts it to a value type" {
        $node = New-Object YamlDotNet.RepresentationModel.YamlScalarNode 5
        $result = Convert-YamlScalarNodeToValue $node

        $result | Should Be 5
    }
}

Describe "Convert-YamlSequenceNodeToList" {

    It "taks a YamlSequence and converts it to an array" {
        $yaml = Get-YamlDocumentFromString "---`n- single item`n- second item"

        $result = Convert-YamlSequenceNodeToList $yaml.RootNode
        $result.count | Should Be 2
    }

}

Describe "Convert-YamlMappingNodeToHash" {

    It "takes a YamlMappingNode and converts it to a hash" {
        $yaml = Get-YamlDocumentFromString "---`nkey1:   value1`nkey2:   value2"

        $result = Convert-YamlMappingNodeToHash $yaml.RootNode
        $result.keys.count | Should Be 2
    }

}

Describe "Get-YamlDocumentFromString" {

    It "will return a YamlDocument if given proper YAML" {
        $document = Get-YamlDocumentFromString "---"
        $document.GetType().Name | Should Be "YamlDocument"
    }

}
