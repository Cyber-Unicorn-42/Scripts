<#
.Synopsis
Intune Proactive Remediations script to detect presence of a driver.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect if a particular print driver is installed.
If the driver is found the remediation is triggered.

.NOTES   
Name: ProactiveRem-Driver-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 03/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$DriverStoreInfName= "*hprub32a_x64.inf"

# Check if driver is installed. If found remediation is triggered.
Try {
    If (!(Get-WindowsDriver -Online | where {$_.OriginalFileName -like $DriverStoreInfName} -ErrorAction Stop )){
        Write-host "Driver Not Found"
        Exit 0
    }
    Else{
        Write-Host "Driver Found"
        Exit 1
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error $ErrorMsg"
    Exit 1
}