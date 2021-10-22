<#
.Synopsis
Script to install MSI applications

.DESCRIPTION
This script will install any specified MSI application and add any of the provided public properties

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Parameter MSIFilename
The file name of the MSI with the extension. Intune/MEM automatically adds switches to any command that it detects has a file with the .msi extension.
The name will also get used for the name of the log file created by the TranscriptPath parameter.

.Parameter MSIProperties
Include any additional public properties you would like to include for the installer

.Example
.\Install-MSI.ps1 -MSIFilename Firefox.msi -MSIProperties "ALLUSERS=1 DESKTOP_SHORTCUT=false"
This will install Firefox for all users without creating desktop shortcuts. The properties specified for MSIProperties are unique for each package.
You will need to look up what they need to be and if they are even required.

.\Install-MSI.ps1 -MSIFilename Firefox.msi -TranscriptPath c:\temp
This will install Firefox with the default options, and a transcript off all commands run in PowerShell and their output will be placed in a log file in C:\temp.
The log file will be Firefox.log.

.NOTES   
Name: Install-MSI.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 22/10/2021

.LINK
https://peterdodemont.com/
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
,
[Parameter(Mandatory=$true)]
[String]
$MSIFilename
,
[Parameter(Mandatory=$false)]
[String]
$MSIProperties
)

# Start transcript when TranscriptPath parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\$MSIFilename.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Set Variables
$MSIInstallFile = $MSIFilename + ".msi"

# Install MSI
Try {
    Start-Process msiexec.exe -ArgumentList "/i $MSIInstallFile /qn /norestart $MSIProperties" -Wait
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "$MSIInstallFile Installation Error: $ErrorMsg"
    Exit 421
}

# Stop transcript when TranscriptPath parameter is passed.
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