<#
.Synopsis
Detect if printers are installed.

.Description
This script can be used in Intune to detect if printers have been mapped for a user.

.Notes
Name: Map-Printer.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 8/11/2021

.Link
https://peterdodemont.com/
#>

# Set variable with printer names
$PrinterNames = @("PRT-SYD-01")
$PrintServer = "prt-01.securitypete.com"

# Check if printers are installed
Try{
    Foreach($Printer in $PrinterNames){
        # Generate full printer name
        $PrinterShareName = "\\$PrintServer\$Printer"
        # Get the status of the printer on the print server
        $PrinterServerStatus = (Get-Printer -ComputerName $PrintServer -Name $Printer).PrinterStatus
        # Only perform check if the printer on the print server is not offline
        If ($PrinterServerStatus -ne "Offline") {
            # Throw error is printer doesn't exist
            If (!(Get-Printer -Name $PrinterShareName -ErrorAction SilentlyContinue)){
                Write-Host "$PrinterShareName not found"
                Exit 1
            }
        }
    }
    # If no errors exit with success message and exit code
    Write-Host "All printers detected"
    Exit 0
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Printer detection error: $ErrorMsg"
    Exit 1
}