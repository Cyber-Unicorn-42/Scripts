<#
.Synopsis
Script to install fonts

.DESCRIPTION
This script will install the fonts specified.

.NOTES   
Name: Install-Fonts.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 14/10/2021

.LINK
https://peterdodemont.com/
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
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

# Names of fonts to install
$Fonts = @("IBMPlexSans-Regular.otf","IBMPlexSerif-Regular.otf")

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