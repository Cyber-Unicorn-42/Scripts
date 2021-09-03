##################################################################################################
#####                                                                                        #####
#####   This script will remove printers with a specific driver.                             #####
#####   Then remove the driver completely from the device.                                   #####
#####   Next it will re-add the printers that were removed.                                  #####
#####   This is usefull when updating the driver on the server does                          #####
#####   not update the driver on local devices (e.g. changing from Type 3 to Type 4 drivers) #####
#####                                                                                        #####
#####   V 1.0                                                                                #####
#####   Created by: Peter Dodemont                                                           #####
#####   Created On: 03/09/2021                                                               #####
#####                                                                                        #####
##################################################################################################

# Set Variables
$CurrentPrinterDriverName = "*HP Color*"
$DriverStoreInfName= "*hprub32a_x64.inf"

# Printer and driver selection for Removal
$CurrentPrinters = get-printer | where {$_.drivername -like $CurrentPrinterDriverName}
$CurrentDriver = Get-PrinterDriver | where {$_.name -like $CurrentPrinterDriverName}
$DriverStoreDriver = Get-WindowsDriver -Online | where {$_.OriginalFileName -like $DriverStoreInfName}

# Remove matched printers if there are any printers
If ($CurrentPrinters){
    Try {
        Foreach ($Printer in $CurrentPrinters) {
        Remove-Printer $Printer.Name -ErrorAction Stop
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer Removal Error: $ErrorMsg"
    }
}

# Remove the current printer driver from the "print server"
If ($CurrentDriver){
    Try {
        Remove-PrinterDriver -Name $CurrentDriver.Name -ErrorAction Stop
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
        Throw "PnpUtil Error:  $PnpUtilRun"
    } 
}

# Re-add printers that were removed (with updated driver if driver on server was updated)
If ($CurrentPrinters){
    Try {
        Foreach ($Printer in $CurrentPrinters) {
            Add-Printer -ConnectionName $Printer.Name -ErrorAction Stop
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer Re-add error: $ErrorMsg"
    }
}