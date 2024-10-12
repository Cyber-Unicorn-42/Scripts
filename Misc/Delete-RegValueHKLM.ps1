<#
.Synopsis
Script to delete a registry value in HKLM

.DESCRIPTION
This script can be used to delete a registry value in HKEY_LOCAL_MACHINE.

.NOTES   
Name: Delete-RegValueHKLM.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 08/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$RegKeyFullPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$RegKey = "HubMode"

# Delete registry key.
Try {
    Remove-ItemProperty -Path $RegKeyFullPath -Name $RegKey -Force -ErrorAction Stop
    Write-Host "Registry value deleted successfully"
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error deleting the registry value: $ErrorMsg"
    Exit 1
}