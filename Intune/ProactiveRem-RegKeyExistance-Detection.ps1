<#
.Synopsis
Intune Proactive Remediations script to detect the existance of registry key in HKLM.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect the existance of a registry key in HKEY_LOCAL_MACHINE.
If the key is found remediation is triggered.

.NOTES   
Name: ProactiveRem-RegKeyExistance-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 08/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$RegKey = "HubMode"

# Check registry key. If it exists trigger remediation.
Try {
    If (Get-ItemPropertyValue $RegKeyPath -Name $RegKey -ErrorAction Stop){
        Write-host "$RegKeyPath\$RegKey exists."
        Exit 1
    }
}
Catch {
    Write-host "$RegKeyPath\$RegKey doesn't exist."
    Exit 0
}