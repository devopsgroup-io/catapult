
if (Test-Path "build") {
  Remove-Item "build" -Recurse -Force
}

mkdir build
vendor\tools\nuget pack PowerYaml.nuspec -OutputDirectory build
