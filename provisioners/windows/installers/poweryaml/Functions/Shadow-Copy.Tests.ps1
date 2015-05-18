$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Shadow-Copy" {

    Setup -File "testfile"
    $isolatedShadowPath = "$TestDrive\poweryaml\shadow"

    It "copies a file to a transient location" {
        Shadow-Copy -File "$TestDrive\testfile" -ShadowPath $isolatedShadowPath
        "$isolatedShadowPath\testfile" | Should Exist
    }

    It "returns a path to the shadow copied file" {
        $shadow = Shadow-Copy -File "$TestDrive\testfile" -ShadowPath $isolatedShadowPath
        $shadow | Should Be "$isolatedShadowPath\testfile"
    }

    It "does not complain if trying to overwrite locked files" {
        $file = [System.io.File]::Open("$isolatedShadowPath\testfile", 'Open', 'Read', 'None')
        $shadow = Shadow-Copy -File "$TestDrive\testfile" -ShadowPath $isolatedShadowPath
        $file.Close()
        "made it here, therefore no errors" | Should Be "made it here, therefore no errors"
    }
}
