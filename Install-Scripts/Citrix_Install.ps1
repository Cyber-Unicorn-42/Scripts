<#
.Synopsis
Remove Citrix Workspace store app and install standalone app

.DESCRIPTION
This script will remove the citrix receiver store app and then install the standalone app.

.NOTES   
Name: Citrix_Install.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 01/10/2021
#>

# Get Citrix Store App
Try {
    $CitrixStoreApp = Get-AppxPackage -AllUsers | where {$_.name -like "*citrixReceiver*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting Citrix store app detials: $ErrorMsg"
    Exit 421
}


# If store app exists uninstall it
If ($CitrixStoreApp) {
    Try {
        Remove-AppxPackage $CitrixStoreApp -AllUsers
        Write-host "Citrix Store App Uninstalled."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error uninstalling: $ErrorMsg"
        Exit 422
    }
}
Else {
    Write-Host "Citrix Store App Not Detected."
}

# Install standalone app
Try {
    Start-Process CitrixWorkspaceApp.exe -ArgumentList "/Silent /includeSSON /noreboot"
    # Sleep for 30 seconds at a time until the receiver process has been detected.
    Write-Host "Citrix Standalone App Installation Started."
    $TimeAsleep = 0
    Do {
        Write-Host "Citrx Workspace App Not Detected in $TimeAsleep seconds. Sleeping for 30 seconds."
        $TimeAsleep += 30
        start-sleep 30
    }
    while (get-process -Name CitrixWorkspaceApp -ErrorAction SilentlyContinue)
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error installing: $ErrorMsg"
    Exit 423
}
Write-Host "Citrix Standalone App Installed."