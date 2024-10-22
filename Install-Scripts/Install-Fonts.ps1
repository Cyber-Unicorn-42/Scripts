<#
.Synopsis
Script to install fonts

.DESCRIPTION
This script will install the fonts specified.

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Example
.\Install-Fonts.ps1 -TranscriptPath c:\temp -Fonts "IBMPlexSans-Regular.otf","IBMPlexSerif-Regular.otf"
This will install the supplied fonts, and a transcript off all commands run in PowerShell and their output will be placed in a log file in C:\temp.

.NOTES   
Name: Install-Fonts.ps1
Created By: Peter Dodemont
Version: 1.2
DateUpdated: 15/01/2022

.LINK
https://cyberunicorn.me/
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
,
[Parameter(Mandatory=$true)]
[string[]]
$Fonts=@()
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\FontsInstall.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Install fonts
Try{
    ForEach ($Font in $Fonts){
        # Copy font to fonts directory
        Copy-Item -Path $Font -Destination $Env:Windir\Fonts -Force

        # Get font name and type
        $FontSplit = $Font.split(".")
        $FontName = $FontSplit[0]
        $FontType = $FontSplit[1]
        
        # Set value for the font type in the registry
        Switch ($FontType) {
            "ttf" {
                $FontTypeName = "(TrueType)"
                Break
            }
            "otf" {
                $FontTypeName = "(OpenType)"
                Break
            }
        }
        # Create registry entry for the font
        New-ItemProperty -Value "$Font" -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Name "$FontName $FontTypeName" -Force > $null
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Font installation Error: $ErrorMsg"
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