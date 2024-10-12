<#
.Synopsis
This script will uninstall a store app.

.DESCRIPTION
This script will uninstall the provided store app based on the name provided even if it was installed prior to a feature update.

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Example
.\Install-Fonts.ps1 -TranscriptPath c:\temp -Fonts "IBMPlexSans-Regular.otf","IBMPlexSerif-Regular.otf"
This will install the supplied fonts, and a transcript off all commands run in PowerShell and their output will be placed in a log file in C:\temp.

.NOTES   
Name: Uninstall-StoreApp.ps1
Created By: Peter Dodemont
Version: 1.0
DateUpdated: 30/03/2022

.LINK
https://cyberunicorn.me/
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
,
[Parameter(Mandatory=$true)]
[string]
$AppName
)

# Get the Store app from the provisioned packages (e.g. if it was installed prior to a feature update).
Try {
    $StoreAppProvisioned = Get-AppxProvisionedPackage -Online | where {$_.DisplayName -like "*$AppName*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting $AppName store app detials from provisioned packages: $ErrorMsg"
    Exit 421
}

# If store app exists in provisioned packages uninstall it.
If ($StoreAppProvisioned) {
    Try {
        Remove-AppxProvisionedPackage -PackageName $StoreAppProvisioned.PackageName -AllUsers -Online
        Write-host "$AppName Store App Uninstalled."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error uninstalling $AppName store provisioned package: $ErrorMsg"
        Exit 422
    }
}
Else {
    Write-Host "$AppName store app not detected in provisioned packages."
}

# Get Store App 
Try {
    $StoreApp = Get-AppxPackage -AllUsers | where {$_.name -like "*$AppName*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting $AppName store app detials: $ErrorMsg"
    Exit 423
}


# If store app exists uninstall it.
If ($StoreApp) {
    Try {
        Remove-AppxPackage $StoreApp -AllUsers
        Write-host "$AppName Store App Uninstalled."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error uninstalling: $ErrorMsg"
        Exit 424
    }
}
Else {
    Write-Host "$AppName Store App Not Detected."
}