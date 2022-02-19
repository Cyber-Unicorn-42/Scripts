<#
.Synopsis
Replace a string in a file and then restart a specified service

.DESCRIPTION
This script will replace a specified string in 1 or more files and then resart the specified service.

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Parameter FileLocations
The full paths to the file(s) where you want to replace the string. Seperated by comma's.

.Parameter OldString
The exisiting string to look for in the file(e).

.Parameter NewString
The new string that will replace the existing string in the file(s).

.Parameter ProcessName
The name of the process that you want to stop (usually this is the name of the executable without the extension).
This is usefull is the service doesn't stop ina timely fashion. As it will kill the process.

.Parameter ServiceName
The name of the service to restart.

.Example
.\ReplaceAndRestart.ps1 -FileLocations "C:\Program Files\SplunkUniversalForwarder\etc\apps\fileserver_outputs\outputs.conf","C:\Program Files\SplunkUniversalForwarder\etc\apps\securitypete_deploymentclient_app\local\deploymentclient.conf" -OldString "10.0.0.1" -NewString "syslog.securitypete.com" -ProcessName splunkd -ServiceName SplunkForwarder

This will replace the ip address of 10.0.0.1 with syslog.securitypete.com in the 2 configuration files and the force stop the splunkd process before restarting the Splunk Forwarder service.

.NOTES   
Name: ReplaceAndRestart.ps1
Created By: Peter Dodemont
Version: 1.1
Date Updated: 12/02/2022
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
,
[Parameter(Mandatory=$true)]
[string[]]
$FileLocations=@()
,
[Parameter(Mandatory=$true)]
[string]
$OldString
,
[Parameter(Mandatory=$true)]
[string]
$NewString
,
[Parameter(Mandatory=$false)]
[string]
$ProcessName
,
[Parameter(Mandatory=$false)]
[string]
$ServiceName
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\ReplaceAndRestart.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Replace the string in each of the specified locations
Try {
    ForEach ($FileLocation in $FileLocations){
        # Get content from file and replace string
        $NewContent = (get-content -Path $FileLocation -Raw -ErrorAction Stop) -replace $OldString,$NewString 

        # Write new-content to file
        $NewContent | Set-Content -Path $FileLocation
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error replacing string: $ErrorMsg"
    Exit 432
}

# Force stop process
Try{
    If ($ProcessName) {Stop-Process -Name $ProcessName -Force -ErrorAction Stop}

    # Sleep for 10 seconds to allow the process to be stopped
    Start-sleep -s 10
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error stopping process: $ErrorMsg"
    Exit 433
}

# Restart service
Try {
    If ($ServiceName){Restart-Service -Name $ServiceName -Force -ErrorAction Stop}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error restarting service: $ErrorMsg"
    Exit 434
}


# Stop transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Stop-Transcript
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to stop transcript: $ErrorMsg"
    Exit 435
}