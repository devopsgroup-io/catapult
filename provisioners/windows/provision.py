import sys
import winrm

winrmsession = winrm.Session(str(sys.argv[1]),auth=(str(sys.argv[2]),str(sys.argv[3])))
winrmsession.run_ps("winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}")
winrmsession.run_ps("Set-ExecutionPolicy RemoteSigned")
result = winrmsession.run_ps( 'powershell -file c:\catapult\provisioners\windows\provision.ps1' + ' "' + str(sys.argv[4]) + '" "' + str(sys.argv[5]) + '" "' + str(sys.argv[6]) + '" "' + str(sys.argv[7]) + '"' )

print result.std_out
print result.std_err
