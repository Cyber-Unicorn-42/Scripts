<#
.Synopsis
Intune Proactive Remediations script to detect if a user or group has to correct permissions to a path.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect if a user or group exists and if it exists does it has to correct permissions to a path.
If the correct rights are not found remediation is triggered.
The script does not check effective access, it only checks if a specific file access right exists for the user or group.
This doesn't matter as permissions are additive so adding rights a user or group already has won't have any impact.

.NOTES   
Name: ProactiveRem-ACL-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 22/06/2021

.LINK
https://peterdodemont.com/
#>

# Set Variables
$ACLPath = "$env:SystemDrive\Temp" # The file or folder you want to check permissions for
$ACLAccount = "Administrators" # The user or group you want to check access for. Domain can be omited, but the user or group name needs to be defined in full.
$ACLAccessType = "Allow" # If the tytpe of access you want to check is Allow or Deny
$ACLFileSystemRight = "FullControl" # The permission you want to check the user or group has. See the following URL for possible values https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=windowsdesktop-5.0

# Get ACL for the path
$ACL = Get-Acl -Path $ACLPath
$Permissions = $ACL.Access

# Define variable that need to persist outside of foreach loop
$ACLAccountFound = ""
$ACLAccountPermissionFound = ""

# Run through each permissions entry
ForEach ($Permission in $Permissions) {

    # Check if account exists on permissions entry
    If ($Permission.IdentityReference -like "*$ACLAccount") {

        # If account is found set variable that account was found. This is to account for if multiple entries for the account exist.
        $ACLAccountFound = "1"

        # Check if the access type matches what is being checked
        If ($Permission.AccessControlType -eq "$ACLAccessType"){

            # If the account is found and the access type matches check that it has the correct permissions
            If ($Permission.FileSystemRights -like "*$ACLFileSystemRight*") {

                # If the correct permissions exist set variable to indicate it does. This is to account for if multiple entries for the account exist.
                $ACLAccountPermissionFound = "1"
            }
        }
    }
}

# Check if correct account permissions where found
If ($ACLAccountPermissionFound -eq "1") {
    Write-Host "$ACLAccount has $ACLFileSystemRight $ACLAccessType access to $ACLPath"
}
Else {
    # Check if the variable that the account was found matches
    If ($ACLAccountFound -eq "1") {
        Write-Host "$ACLAccount exists but doesn't have $ACLFileSystemRight $ACLAccessType access to $ACLPath"
        #Exit 1
    }
    Else {
        Write-Host "$ACLAccount doesn't exist on $ACLPath"
        #Exit 1
    }
}