<#
.Synopsis
Detect if printers are installed.

.Description
This script can be used in Intune to detect if printers have been mapped for a user.

.Notes
Name: Map-Printer.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 13/09/2021

.Link
https://peterdodemont.com/
#>

# Set variable with printer names
$Printers = @("\\prt-01.securitypete.com\PRT-SYD-01")

# Check if printers are installed
Try{
    Foreach($Printer in $Printers){
        # Throw error is printer doesn't exist
        If (!(Get-Printer -Name $Printer -ErrorAction SilentlyContinue)){
            Write-Host "$Printer not found"
            Exit 1
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