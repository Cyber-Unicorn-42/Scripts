<#
.Synopsis
Script to set the value of a dword registry key for the currently logged in user

.DESCRIPTION
This script can be used to set the value of a dword registry key for the currently logged in user (including for the currently logged in user when running as system). It will work even when running as another user (e.g. system)

.NOTES   
Name: Set-RegStringValue.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 15/10/2021

.LINK
https://peterdodemont.com/
#>

# Set Variables
$RegKeyFullPaths = @("HKCU:\SOFTWARE\Policies\Microsoft\Edge\Recommended\NewTabPageLocation")
$RegKeyValue = "https://peterdodemont.com"
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

# Run through each registry path
ForEach ($RegKeyFullPath in $RegKeyFullPaths) {
    
    # Get the parent and the leaf from each path
    $RegKeyPath = Split-Path $RegKeyFullPath -Parent
    $RegKey = Split-Path $RegKeyFullPath -Leaf

    # Check if the registry path exists if not create it
    If (!(Test-Path $RegKeyPath)){
        Try {
            # Create the new path
            New-Item $RegKeyPath -ErrorAction Stop -Force > $null
            Write-Host "Registry path created successfully"
        }
        Catch {
            $ErrorMsg = $_.Exception.Message
            Write-host "Error creating registry path: $ErrorMsg"
            If ($CurrentUserAsSystem -eq $true){
                # Restore original PSDrive
                Remove-PSDrive HKCU
                New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
            }
            Exit 1
        }
    }
    # Set dword value of registry key.
    Try {
        Set-ItemProperty -Path $RegKeyPath -Name $RegKey -Value $RegKeyValue -Type String -ErrorAction Stop -Force
        Write-Host "Registry value set correctly"
        If ($CurrentUserAsSystem -eq $true){
            # Restore original PSDrive
            Remove-PSDrive HKCU
            New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error setting the registry value: $ErrorMsg"
        If ($CurrentUserAsSystem -eq $true){
            # Restore original PSDrive
            Remove-PSDrive HKCU
            New-PSDrive -PSProvider Registry -Name HKCU -Root HKEY_CURRENT_USER > $null
        }
        Exit 1
    }
}