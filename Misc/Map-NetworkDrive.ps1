<#
.Synopsis
Script to map network drive.

.DESCRIPTION
This script can be used to map network drives for a user through PowerShell.

.NOTES   
Name: Map-NetworkDrive.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 28/09/2021

.LINK
https://peterdodemont.com/
#>

# Set variables for network drive
$DriveLetter = "y"
$SMBDriveLetter = $DriveLetter + ":"
$FileServer = "FILE-01.securitypete.com"
$ShareName = "Data\Sydney"
$DriveRoot = "\\" + $FileServer + "\" + $ShareName
$RegKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\" + $DriveRoot.Replace('\','#')
$DriveDisplayName = "Sydney Share"

# Convert drive letter to uppercase as lowercase causes removal issues.
$DriveLetter = $DriveLetter.ToUpper()

# Get current drive details
$CurrentDriveDetails = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue

# Check network connectivity to server
Try{
    $NetworkTest = Test-NetConnection -ComputerName $FileServer -ErrorAction Stop
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Network Error: $ErrorMsg"
    Exit 1
}

# Map Drive.
If ($NetworkTest.PingSucceeded -eq $true) {
    Try{
        # Check if drive exists but is mapped to different location
        If (($CurrentDriveDetails.Name -eq $DriveLetter) -AND ($CurrentDriveDetails.DisplayRoot -ne $DriveRoot)) {
            # Remove existing drive. Using Remove-SmbMapping and Remove-PSDrive as otherwise drives mapped using group policy are not removed.
            Remove-SmbMapping -LocalPath "$SMBDriveLetter" -Force
            Remove-PSDrive -Name $DriveLetter -Force -Scope Global -ErrorAction Stop > $null
            Write-Host "$DriveLetter has been removed."
            # Map drive to new location.
            New-PSDrive -Name $DriveLetter -Root $DriveRoot -PSProvider FileSystem -Persist -Scope Global > $null
            Write-Host "$DriveLetter has been mapped to $DriveRoot."
            # Check if registry key for dispaly name exists if not create it
            If (!(Test-Path $RegKeyPath)){
                Try {
                    # Create the new path
                    New-Item $RegKeyPath -ErrorAction Stop -Force > $null
                    Write-Host "Registry path created successfully"
                }
                Catch {
                    $ErrorMsg = $_.Exception.Message
                    Write-host "Error creating registry path: $ErrorMsg"
                }
            }
            # Set the display name
            Set-ItemProperty -Path $RegKeyPath -Name "_LabelFromReg" -Value $DriveDisplayName -Type String -ErrorAction Stop -Force
        }
        # Check if drive doesn't exist.
        If ($CurrentDriveDetails.Name -eq $null) {
            # Map drive to new location.
            New-PSDrive -Name $DriveLetter -Root $DriveRoot -PSProvider FileSystem -Persist -Scope Global > $null
            Write-Host "$DriveLetter has been mapped to $DriveRoot."
            If (!(Test-Path $RegKeyPath)){
                Try {
                    # Create the new path
                    New-Item $RegKeyPath -ErrorAction Stop -Force > $null
                    Write-Host "Registry path created successfully"
                }
                Catch {
                    $ErrorMsg = $_.Exception.Message
                    Write-host "Error creating registry path: $ErrorMsg"
                }
            }
            # Set the display name
            Set-ItemProperty -Path $RegKeyPath -Name "_LabelFromReg" -Value $DriveDisplayName -Type String -ErrorAction Stop -Force
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Drive Mapping Error: $ErrorMsg"
        Exit 1
    }
}
Else {
    Write-Host "Unable to reach file server."
    Exit 1
}