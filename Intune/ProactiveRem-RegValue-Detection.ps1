<#
.Synopsis
Intune Proactive Remediations script to detect the value of registry key for the currently logged in user as system.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect the value of a registry key for the currently logged in user as system.
If the value is not found or incorrect the remediation is triggered.

.NOTES   
Name: ProactiveRem-RegValue-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 08/09/2021

.LINK
https://peterdodemont.com/
#>

# Set Variables
$RegKeyFullPaths = @("HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2\1A00")
$RegKeyExpectedValue = "0"

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

# Run check through each registry path
ForEach ($RegKeyFullPath in $RegKeyFullPaths) {
    
    # Get the parent and the leaf from each path
    $RegKeyPath = Split-Path $RegKeyFullPath -Parent
    $RegKey = Split-Path $RegKeyFullPath -Leaf

    # Get registry key value
    $RegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegKey -ErrorAction SilentlyContinue

    # Check registry key value. If it doesn't match trigger remediation.
    Try {
        If ($RegKeyCurrentValue -eq $RegKeyExpectedValue){
            Write-host "Registry key $RegKeyPath\$RegKey has correct value."
        }
        Else{
            Write-Host "Registry key $RegKeyPath\$RegKey has incorrect value."
            # Restore original PSDrive
            Remove-PSDrive HKCU
            New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
            Exit 1
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error $ErrorMsg"
        # Restore original PSDrive
        Remove-PSDrive HKCU
        New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
        Exit 1
    }
}

# Restore original PSDrive
Remove-PSDrive HKCU
New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
Exit 0