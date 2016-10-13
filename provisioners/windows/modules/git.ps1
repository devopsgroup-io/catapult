. "c:\catapult\provisioners\windows\modules\catapult.ps1"


# clone/pull repositories into c:\inetpub\repositories\iis\
if (-not(test-path -path "c:\inetpub\repositories\iis")) {
    new-item -itemtype directory -force -path "c:\inetpub\repositories\iis"
}
foreach ($instance in $configuration.websites.iis) {
    if (test-path ("c:\inetpub\repositories\iis\{0}\.git" -f $instance.domain) ) {
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config --global user.name {1}" -f $instance.domain,"Catapult") -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config --global user.email {1}" -f $instance.domain,$configuration.company.email) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config core.autocrlf false" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config core.packedGitLimit 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config core.packedGitWindowSize 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.deltaCacheSize 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.packSizeLimit 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} config pack.windowMemory 128m" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} reset -q --hard HEAD --" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} checkout ." -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} clean -fd" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} checkout {1}" -f $instance.domain,$configuration.environments.$($args[0]).branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} fetch" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} pull origin {1}" -f $instance.domain,$configuration.environments.$($args[0]).branch) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("-C c:\inetpub\repositories\iis\{0} submodule update --init --recursive" -f $instance.domain) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
    } else {
        start-process -filepath "c:\Program Files\Git\bin\git.exe" -argumentlist ("clone --recursive --branch {1} {2} c:\inetpub\repositories\iis\{0}" -f $instance.domain,$configuration.environments.$($args[0]).branch,$instance.repo) -Wait -RedirectStandardOutput $provision -RedirectStandardError $provisionError
        get-content $provision
        get-content $provisionError
    }
}
