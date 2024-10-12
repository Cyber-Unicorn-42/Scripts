<#
.Synopsis
Intune Proactive Remediations script to detect the value of registry key for the currently logged in user as system.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect the value of a registry key for the currently logged in user as system.
If the value is not found or incorrect the remediation is triggered.

.NOTES   
Name: ProactiveRem-MappedDrive-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 28/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set variables for network drive
$DriveLetter = "y"
$FileServer = "FILE-01.securitypete.com"
$ShareName = "Data\Sydney"
$DriveRoot = "\\" + $FileServer + "\" + $ShareName

# Convert drive letter to uppercase as lowercase causes removal issues.
$DriveLetter = $DriveLetter.ToUpper()

# Get current drive details
$CurrentDriveDetails = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue

# Check registry key value. If it doesn't match trigger remediation.
Try {
    If (($CurrentDriveDetails.Name -eq $DriveLetter) -AND ($CurrentDriveDetails.DisplayRoot -eq $DriveRoot)){
        Write-Host "$Driveletter is mapped to $DriveRoot."
        Exit 0
    }
    Else {
        Write-Host "$DriveLetter is not mapped to $DriveRoot."
        Exit 1
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error checking mapped drive: $ErrorMsg"
    Exit 1
}