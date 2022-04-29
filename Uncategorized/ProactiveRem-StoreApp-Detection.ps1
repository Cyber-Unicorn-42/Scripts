<#
.Synopsis
Intune Proactive Remediations script to detect a store app

.DESCRIPTION
This script can be used in Intune proactive remediations to detect if a particular store app is installed or not.
Remediation will be kicked off when the store app is detected/not dected based on the detectionmode variable.

.NOTES   
Name: ProactiveRem-StoreApp-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 30/03/2022

.LINK
https://peterdodemont.com/
#>

# Set Variables
$AppName= "HPSmart"
$DetectionMode = "Installed" # Set to "Uninstalled" if you want to detect if the application is uninstalled.

# Get the store app from the provisioned packages (e.g. if it was installed prior to a feature update).
Try {
    $StoreAppProvisioned = Get-AppxProvisionedPackage -Online | where {$_.DisplayName -like "*$AppName*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting $AppName store app detials from provisioned packages: $ErrorMsg"
    Exit 1
}

# Get Store App 
Try {
    $StoreApp = Get-AppxPackage -AllUsers | where {$_.name -like "*$AppName*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting $AppName store app detials: $ErrorMsg"
    Exit 1
}

# Perform the checks for the provisioned packages and return appropriate error codes
If ($StoreAppProvisioned) {
    Write-host "$AppName store app detected in provioned packages."
    $InstalledStatusProv = $true
}
Else {
    Write-Host "$AppName store app not detected in provisioned packages."
    $InstalledStatusProv = $false
}

# If store app exists uninstall it.
If ($StoreApp) {
    Write-host "$AppName store app detected in current packages."
    $InstalledStatusCurrent = $true
}
Else {
    Write-Host "$AppName store app not detected current packages."
    $InstalledStatusCurrent = $false
}

If ($InstalledStatusProv -eq $true -or $InstalledStatusCurrent -eq $true) {
    $InstalledStatus = $true
}
Else {
    $InstalledStatus = $false
}

If ($DetectionMode -eq "Installed" -and $InstalledStatus -eq $true) {
    Write-Host "$AppName store app detected."
    Exit 0
}
Elseif ($DetectionMode -eq "Installed" -and $InstalledStatus -eq $false) {
    Write-Host "$AppName store app not detected."
    Exit 1
}
Elseif ($DetectionMode -eq "Uninstalled" -and $InstalledStatus -eq $true) {
    Write-Host "$AppName store app detected."
    Exit 1
}
Elseif ($DetectionMode -eq "Uninstalled" -and $InstalledStatus -eq $false) {
    Write-Host "$AppName store app not detected."
    Exit 0
}