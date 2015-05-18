$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $here\PowerYaml.psm1 -Force

Describe "PoweYaml when parsing strings" {

    It "Obtains a HashTable given a yaml hash" {
        $yaml = Get-Yaml -FromString "key: value"
        $yaml.GetType().Name | Should Be "HashTable"
    }

    It "Obtains an Object[] given a yaml array" {
        $yaml = Get-Yaml -FromString "- test`n- test2"
        $yaml.GetType().Name | Should Be "Object[]"
    }
}

Describe "Using Power Yaml to read a file" {
    Setup -File "sample.yml" "test: value"

    It "Can read the file and get the value" {
        $yaml = Get-Yaml -FromFile "$TestDrive\sample.yml"
        $yaml.test | Should Be "value"
    }
}

Describe "Using Power Yaml to convert integer scalars" {
    if ($PSVersionTable.PSVersion -ge "3.0") { return }

    It "Obtains an int given an integer value" {
        $yaml = Get-Yaml -FromString "key: 5"
        $yaml.key.ToInt().GetType().Name | Should Be "Int32"
    }
}

Remove-Module PowerYaml
