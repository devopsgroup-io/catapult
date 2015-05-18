$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests", "")
. "$pwd\$sut"

Describe "Detect-Tab" {

    It "should return the line number the first TAB character is found on" {
        $lines = @()
        $lines += "valide: yaml"
        $lines += "   `t    "
        $line_number_tab_is_in = 2

        $result = Detect-Tab $lines
        $result | Should Be $line_number_tab_is_in
    }

    It "should return 0 if no TAB character is found in text" {
        $result = Detect-Tab "          "
        $result | Should Be 0
    }
}

Describe "Validate-File" {

    Setup -File "exists.yml"

    It "should return false if a file does not exist" {
        $result = Validate-File "some non existent file"
        $result | Should Be $false
    }

    It "should return true for a file that does exist and does not contain a TAB character" {
        $result = Validate-File "$TestDrive\exists.yml" 
        $result | Should Be $true
    }
}

Describe "Validating a file with tabs" {

    Setup -File "bad.yml" "     `t   "

    It "should return false" {
        Trap [Exception] {
            Write-Host caught error
        }
        $result = Validate-File "$TestDrive\bad.yml"
        $result | Should Be $false
    }
}
