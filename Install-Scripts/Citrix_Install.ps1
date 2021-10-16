<#
.Synopsis
Remove Citrix Workspace store app and install standalone app

.DESCRIPTION
This script will remove the citrix receiver store app and then install the standalone app.

.NOTES   
Name: Citrix_Install.ps1
Created By: Peter Dodemont
Version: 1.3
Date Updated: 14/10/2021
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\CitrixInstall.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Get the Citrix Store app from the provisioned packages (e.g. if it was installed prior to a feature update).
Try {
    $CitrixStoreAppProvisioned = Get-AppxProvisionedPackage -Online | where {$_.DisplayName -like "*citrixReceiver*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting Citrix store app detials from provisioned packages: $ErrorMsg"
    Exit 421
}

# If store app exists in provisioned packages uninstall it.
If ($CitrixStoreAppProvisioned) {
    Try {
        Remove-AppxProvisionedPackage -PackageName $CitrixStoreAppProvisioned.PackageName -AllUsers -Online
        Write-host "Citrix Store App Uninstalled."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error uninstalling Citrix store provisioned package: $ErrorMsg"
        Exit 422
    }
}
Else {
    Write-Host "Citrix store app not detected in provisioned packages."
}

# Get Citrix Store App
Try {
    $CitrixStoreApp = Get-AppxPackage -AllUsers | where {$_.name -like "*citrixReceiver*"}
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error getting Citrix store app detials: $ErrorMsg"
    Exit 423
}


# If store app exists uninstall it.
If ($CitrixStoreApp) {
    Try {
        Remove-AppxPackage $CitrixStoreApp -AllUsers
        Write-host "Citrix Store App Uninstalled."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error uninstalling: $ErrorMsg"
        Exit 424
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
    Exit 425
}
Write-Host "Citrix Standalone App Installed."

# Stop transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Stop-Transcript
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to stop transcript: $ErrorMsg"
    Exit 432
}