$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests", "")
. "$pwd\$sut"

if ($PSVersionTable.PSVersion -ge "3.0") { return }

Describe "when accessing a yaml scalar value of '5'" {
    $patched = Add-CastingFunctionsForPosh2 ("5")

    Context "and I do not attempt to cast it" {
        It "returns a string" {
            $patched.GetType().Name | Should Be "string"
        }
    }

    Context "and I attempt to cast it as an integer" {
        It "returns a value that is of type integer" {
            $patched.ToInt().GetType().Name | Should Be "Int32"
        }
    }

    Context "and I attempt to cast it as a long" {
        It "returns a value that is of type long" {
            $patched.ToLong().GetType().Name | Should Be "Int64"
        }
    }

    Context "and I attempt to cast it as a double" {
        It "returns a value that is a double" {
            $patched.ToDouble().GetType().Name | Should Be "Double"
        }
    }

    Context "and I attempt to cast it as a decimal" {
        It "returns a value that is a decimal" {
            $patched.ToDecimal().GetType().Name | Should Be "Decimal"
        }
    }

    Context "and I attempt to cast it as a byte" {
        It "returns a value that is a byte" {
            $patched.ToByte().GetType().Name | Should Be "Byte"
        }
    }
}

Describe "when accessing boolean values" {

    Context "and I'm attempting to cast the value 'true'" {
        $patched = Add-CastingFunctionsForPosh2("true")

        It "return a value that is a boolean" {
            $patched.ToBoolean().GetType().Name | Should Be "Boolean"
        }

        It "returns a value that is true" {
            $patched.ToBoolean() | Should Be $true
        }
    }

    Context "and I'm attempting to cast the value 'false'" {
        $patched = Add-CastingFunctionsForPosh2("false")

        It "return a value that is a boolean" {
            $patched.ToBoolean().GetType().Name | Should Be "Boolean"
        }

        It "returns a value that is false" {
            $patched.ToBoolean() | Should Be $false
        }
    }
}
