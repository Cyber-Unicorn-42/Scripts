<#
.Synopsis
Airlock Digital Install.

.DESCRIPTION
This script will install Airlock Digital for the group specified.
#>

Param
(
[Parameter(Mandatory=$true)]
[String]
$PolicyGroupID
,
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\AirlockDigitalInstall.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Install Airlock Digital
Try {
    Start-Process msiexec.exe -ArgumentList "/i AirlockDigital.msi /qn /norestart SERVER=ac9356.ci.managedwhitelisting.com SERVERPORT=443 POLICY=$PolicyGroupID" -Wait
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Airlock Digital Installation Error: $ErrorMsg"
    Exit 421
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
    Exit 432
}