<#
.Synopsis
Script to set the value of a dword registry key for the currently logged in user.

.DESCRIPTION
This script can be used to set the value of a dword registry key for the currently logged in user. It will work even when running as another user (e.g. system)

.NOTES   
Name: Set-RegDwordValue.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 08/09/2021

.LINK
https://peterdodemont.com/
#>

# Set Variables
$RegKeyFullPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
$RegKey = "1A00"
$RegKeyValue = "0"

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
New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_USERS\$CurrentUserSID  > $null

# Check if the registry path exists if not create it
If (!(Test-Path $RegKeyFullPath)){
    # Get the last key name from the path so it can be created
    $RegKeyPathLeaf = Split-Path $RegKeyFullPath -Leaf
    $RegKeyPath = Split-Path $RegKeyFullPath
    Try {
        # Create the new path
        New-Item -Path $RegKeyPath -Name $RegKeyPathLeaf -ErrorAction Stop -Force
        Write-Host "Registry path created successfully"
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error creating registry path: $ErrorMsg"
        # Restore original PSDrive
        Remove-PSDrive HKCU
        New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
        Exit 1
    }
}
# Set dword value of registry key.
Try {
    Set-ItemProperty -Path $RegKeyFullPath -Name $RegKey -Value $RegKeyValue -Type Dword -ErrorAction Stop -Force
    Write-Host "Registry value set correctly"
    # Restore original PSDrive
    Remove-PSDrive HKCU
    New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER  > $null
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error setting the registry value: $ErrorMsg"
    # Restore original PSDrive
    Remove-PSDrive HKCU
    New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
    Exit 1
}