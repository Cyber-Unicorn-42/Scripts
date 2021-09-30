<#
.Synopsis
Remove print driver from a device completly.

.DESCRIPTION
This script will remove printers with a specific driver, then remove the driver, followed by re-adding the printers.

.NOTES   
Name: Remove-PrintDriver.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 17/09/2021

.LINK
https://peterdodemont.com/
#>

# Set powershell execution policy so remote scripts can be run
Set-Executionpolicy Bypass -Force

# Set Variables
$CurrentPrinterDriverName = "*HP Color*"
$DriverStoreInfName= "*hprub32a_x64.inf"
$PrintServerNamesArray=@("prt-01","prt-01.securitypete.com")

# Driver selection for Removal
$CurrentDriver = Get-PrinterDriver | where {$_.name -like $CurrentPrinterDriverName}
$DriverStoreDriver = Get-WindowsDriver -Online | where {$_.OriginalFileName -like $DriverStoreInfName}

# Create temp directory if it does not exist
If (!(Test-Path $Env:SystemDrive\Temp)){New-Item -Path $Env:SystemDrive\ -Name Temp -ItemType Directory -Force > $null}

# Create base powershell files for use in scheduled tasks later
New-Item -Path $Env:SystemDrive\Temp -Name RemoveUserPrinters.ps1 -Force -ItemType File > $null
New-Item -Path $Env:SystemDrive\Temp -Name ReAddUserPrinters.ps1 -Force -ItemType File > $null

# Create Variables for easy retrieval of the script paths
$RemoveUserPrintersPath = "$Env:SystemDrive\Temp\RemoveUserPrinters.ps1"
$ReAddUserPrintersPath = "$Env:SystemDrive\Temp\ReAddUserPrinters.ps1"

# Get currently logged in user
$CurrentLoggedInUser = (Get-WmiObject -Class Win32_ComputerSystem -Property Username).Username

# Split the username into domain and username
$CurrentUserSplit = $CurrentLoggedInUser.Split("\\")
$CurrentDomain = $CurrentUserSplit[0]
$CurrentUsername = $CurrentUserSplit[1]

# Get the SID of the currently logged in user
$CurrentUserSID = ([wmi]"win32_userAccount.domain='$CurrentDomain',Name='$CurrentUsername'").SID

# Create new PSDrive to access HKEY_Users
Try{New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS > $null}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Printer PSDrive Creation Error: $ErrorMsg"
}

# Get all user's network printer entries from the registry
$RegistryPrinters = Get-ChildItem HKU:\$CurrentUserSID\Printers\Connections

# Run through each registry entry and get the Printer Name and Server to put in the powershell scripts.
If($RegistryPrinters){
    Try {
        ForEach ($RegistryPrinter in $RegistryPrinters){
            $RegistryPrinterPath = $RegistryPrinter.Name
            $RegistryPrinterName = $RegistryPrinter.Name.Split(",")[-1]
            $RegistryPrinterServer = Get-ItemPropertyValue Registry::$RegistryPrinterPath -Name Server
            $RegistryPrinterNetworkPath = $RegistryPrinterServer + "\" + $RegistryPrinterName

            # Create line for printer removal and add it to the powershell scripts
            $PrinterRemovalLine = 'Remove-Printer -Name ' + $RegistryPrinterNetworkPath
            Add-Content -Path $RemoveUserPrintersPath -Value $PrinterRemovalLine
            # Clear the line variable
            Clear-Variable -Name PrinterRemovalLine -Force

            # Check if the servername of the printer matches any of the specified print servers. If it does add a line to the printer re-add script.
            ForEach ($PrintServerName in $PrintServerNamesArray){
                If ($RegistryPrinterServer -like "\\$PrintServerName") {
                    $PrinterReAddLine = 'Add-Printer -ConnectionName ' + $RegistryPrinterNetworkPath
                    Add-Content -Path $ReAddUserPrintersPath -Value $PrinterReAddLine
                    # Clear the line variable
                    Clear-Variable -Name PrinterReAddLine -Force
                }
            }
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer Script Creation Error: $ErrorMsg"
    }
}

# Create a Scheduled Task for printer removal. Then run it and wait till it completes. Finally remove the task
If($RegistryPrinters){
    Try {
        $RemovalTaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command $RemoveUserPrintersPath"
        $RemovalTrigger = New-ScheduledTaskTrigger -AtLogOn
        $RemovalPrincipal = New-ScheduledTaskPrincipal -UserId $CurrentLoggedInUser
        $RemovalTask = New-ScheduledTask -Action $RemovalTaskAction -Trigger $RemovalTrigger -Principal $RemovalPrincipal
        Register-ScheduledTask -TaskName PrinterRemoval -InputObject $RemovalTask > $null
        Start-ScheduledTask -TaskName PrinterRemoval
        Do {
            Start-sleep -Seconds 15
            $RemovalProgressState = (Get-ScheduledTask -TaskName PrinterRemoval).State
            $RemovalProgressResult = (Get-ScheduledTaskInfo -TaskName PrinterRemoval).LastTaskResult
            If (($RemovalProgressState -eq "Ready") -And ($RemovalProgressResult -ne "0")){
                Unregister-ScheduledTask -TaskName PrinterRemoval -Confirm:$false
                Throw "Printer Removal Scheduled Task Error Code: $RemovalProgressResult"
            }
        }
        While ($RemovalProgressState -ne "Ready")
        Unregister-ScheduledTask -TaskName PrinterRemoval -Confirm:$false

    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer Removal Error: $ErrorMsg"
    }
}

# Delete the removal script file
Try {Remove-Item -Path $RemoveUserPrintersPath -Force}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Printer Removal Script Seletion Error: $ErrorMsg"
}

# Remove the current printer driver from the "print server"
If ($CurrentDriver){
    Try {
        # Get driver name
        $CurrentDriverName = $CurrentDriver.Name
        # Get driver print processor
        $CurrentDriverProcessor = (Get-WmiObject -Namespace Root\StandardCimv2 -Class MSFT_PrinterDriver | where {$_.Name -eq $CurrentDriverName}).PrintProcessor
        # Get driver print environment
        $CurrentDriverEnvironment = (Get-WmiObject -Namespace Root\StandardCimv2 -Class MSFT_PrinterDriver | where {$_.Name -eq $CurrentDriverName}).PrinterEnvironment
        # Generate names for print processor regkey
        $PrintProcessorRegKeyCurrentName = $CurrentDriverProcessor
        $PrintProcessorRegKeyNewName = $PrintProcessorRegKeyCurrentName + ".old"
        # Set paths for print processor regkey
        $PrintProcessorRegKeyCurrentPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\" + $CurrentDriverEnvironment + "\Print Processors\" + $PrintProcessorRegKeyCurrentName
        $PrintProcessorRegKeyRenamedPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\" + $CurrentDriverEnvironment + "\Print Processors\" + $PrintProcessorRegKeyNewName
        # rename print processor to Remove driver from use
        Rename-Item -Path $PrintProcessorRegKeyCurrentPath -NewName $PrintProcessorRegKeyNewName -Force
        # Restart Print Spooler Service
        Restart-Service -Name spooler
        #Remove Printer driver
        Remove-PrinterDriver -Name $CurrentDriverName -ErrorAction Stop
        # rename print processor back to original name
        Rename-Item -Path $PrintProcessorRegKeyRenamedPath -NewName $PrintProcessorRegKeyCurrentName -Force
        # Restart Print Spooler Service
        Restart-Service -Name spooler
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Driver Removal Error: $ErrorMsg"
    }
}

# Delete driver from windows driver store
If ($DriverStoreDriver) {
    $PnpUtilRun = pnputil /delete-driver $DriverStoreDriver.Driver 2>&1
    If ($LASTEXITCODE -ne 0){
        Throw "Printer PnpUtil Error: $PnpUtilRun"
    } 
}

# Create a Scheduled Task for Re-adding the printer. Then run it and wait till it completes. Finally remove the task.
If($RegistryPrinters){
    Try {
        $ReAddTaskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command $ReAddUserPrintersPath"
        $ReAddTrigger = New-ScheduledTaskTrigger -AtLogOn
        $ReAddPrincipal = New-ScheduledTaskPrincipal -UserId $CurrentLoggedInUser
        $ReAddTask = New-ScheduledTask -Action $ReAddTaskAction -Trigger $ReAddTrigger -Principal $ReAddPrincipal
        Register-ScheduledTask -TaskName PrinterReAdd -InputObject $ReAddTask > $null
        Start-ScheduledTask -TaskName PrinterReAdd
        Do {
            Start-sleep -Seconds 15
            $ReAddProgressState = (Get-ScheduledTask -TaskName PrinterReAdd).State
            $ReAddProgressResult = (Get-ScheduledTaskInfo -TaskName PrinterReAdd).LastTaskResult
            If (($ReAddProgressState -eq "Ready") -And ($ReAddProgressResult -ne "0")){
                Unregister-ScheduledTask -TaskName PrinterReAdd -Confirm:$false
                Throw "Printer Re-Adding Scheduled Task Error Code: $ReAddProgressResult"
            }
        }
        While ($ReAddProgressState -ne "Ready")
        Unregister-ScheduledTask -TaskName PrinterReAdd -Confirm:$false

    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer Re-Add Error: $ErrorMsg"
    }
}

# Delete the re-adding script file
Try {Remove-Item -Path $ReAddUserPrintersPath -Force}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Printer Re-Add Script Deletion Error: $ErrorMsg"
}

# Remove PSDrive
Try{Remove-PSDrive -Name HKU -Force}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Printer PSDrive Removal Error: $ErrorMsg"
}