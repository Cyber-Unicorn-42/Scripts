<#
.Synopsis
Add a permission to a file or folder

.DESCRIPTION
This script will add the specified permission to the nominted file or folder.

.Parameter ACLPath
The path to apply the permission to.

.Parameter Identity
The name or SID of the user or group that the permission will be set for.

.Parameter FileSystemRight
The actual permission being set. For information on possbile values see https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=windowsdesktop-5.0

.Parameter Propagation
The propagation property of the access rule. This is a numeric value. For information on the accepted values see https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.propagationflags?view=windowsdesktop-5.0 

.Parameter Inheritence
The inheritance property of the access rule. This is a numeric value. For information on the accepted values see https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.inheritanceflags?view=windowsdesktop-5.0

.Parameter RuleType
Whether this is an Allow or Deny rule.

.Example
.\Add-FileFolderPermission.ps1 -ACLPath c:\Temp -Identity Users -FileSystemRight Modify -Propagation 2 -inheritance 3 -RuleType Allow
This will add a permission entry on C:\Temp giving the "Users" group modify permission.
The permission will be inherited by all subfolders and files but will not apply to the folder it is set on.

.NOTES   
Name: Add-FileFolderPermission.ps1
Created By: Peter Dodemont
Version: 1
Date Updated: 4/12/2021

.Link
https://cyberunicorn.me/
#>

Param
(
[Parameter(Mandatory=$true)]
[String]
$ACLPath
,
[Parameter(Mandatory=$true)]
[String]
$Identity
,
[Parameter(Mandatory=$true)]
[String]
$FileSystemRight
,
[Parameter(Mandatory=$true)]
[Int]
[Validateset(0,1,2,3)]
$Propagation
,
[Parameter(Mandatory=$true)]
[Int]
[Validateset(0,1,2,3)]
$inheritance
,
[Parameter(Mandatory=$true)]
[String]
[Validateset("Allow","Deny")]
$RuleType
)

Try {
    $ACL = Get-Acl -Path $ACLPath
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$FileSystemRight,$inheritance,$Propagation,$RuleType)
    $ACL.SetAccessRule($AccessRule)
    $ACL | Set-Acl -Path $ACLPath
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Set folder permissions error: $ErrorMsg"
    Exit 421
}