<#
.Synopsis
Intune Proactive Remediations script to report the value of registry key.

.DESCRIPTION
This script can be used in Intune proactive remediations to report the value of a registry key (including for the currently logged in user when run as System).
It never reports a failure.

.NOTES   
Name: ProactiveRem-RegValue-Reporting.ps1
Created By: Peter Dodemont
Version: 1.0
DateUpdated: 06/10/2021

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$RegKeyFullPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\VersionToReport"
$CurrentUserAsSystem = $false

# Check if you need to check it for the current user as system
If ($CurrentUserAsSystem -eq $true){
    # Get currently logged in user
    $CurrentLoggedInUser = (Get-WmiObject -Class Win32_ComputerSystem -Property Username).Username

    # Split the username into domain and username
    $CurrentUserSplit = $CurrentLoggedInUser.Split("\\")
    $CurrentDomain = $CurrentUserSplit[0]
    $CurrentUsername = $CurrentUserSplit[1]

    # Get the SID of the currently logged in user
    $CurrentUserSID = ([wmi]"win32_userAccount.domain='$CurrentDomain',Name='$CurrentUsername'").SID

    # Remove Current PSDrive pointing to HKCU
    Remove-PSDrive HKCU

    # Create new PSDrive for HKCU pointing to the SID of the currently logged in user under HKEY_USERS
    New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_USERS\$CurrentUserSID > $null
}

Try {
# Get the parent and the leaf from each path
$RegKeyPath = Split-Path $RegKeyFullPath -Parent
$RegKey = Split-Path $RegKeyFullPath -Leaf

# Get registry key value
$RegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegKey -ErrorAction Stop

# Report registry key value.
Write-host "$RegKeyCurrentValue"

# Check if you need to check it for the current user as system
If ($CurrentUserAsSystem -eq $true){

    # Restore original PSDrive
    Remove-PSDrive HKCU
    New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
}
Exit 0
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error checking registry value $ErrorMsg"

    # Check if you need to check it for the current user as system
    If ($CurrentUserAsSystem -eq $true){

        # Restore original PSDrive
        Remove-PSDrive HKCU
        New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
        }
    Exit 1
}
