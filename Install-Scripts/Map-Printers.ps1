<#
.Synopsis
Map or remove printers from supplied parameters.

.Description
This script will add and/or remove the printers supplied through the parameter on the commandline.
A parameter can also be passed so the script removes any of the printers provided before re-adding them (if they exist).
The script will check both the FQDN and Netbios name for removal but will only add it using the FQDN.

.Parameter PrintServerFQDN
The printer server's FQDN

.Parameter PrintShareNames
The name or names of printers you want to add. values should be seperated by commas

.Parameter RemoveFirst
A switch to check if the printers already exist. If they do remove the printers first. If no existing printers will not be re-added.

.Parameter RemoveOnly
When this parameter is provided no installation is performed, only removal.

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Example
.\Map-Printers.ps1 -PrintServerFQDN prt-01.securitypete.com -PrinterShareNames PRT-SYD-01,PRT-SYD-02 -RemoveFirst
This will check the local device is any printer with a name of \\prt-01.securitypete.com\PRT-SYD-01, \\prt-01.securitypete.com\PRT-SYD-02, \\prt-01\PRT-SYD-01 or \\prt-01\PRT-SYD-02 exist and then remove them all.
Next it will re-add 2 printers \\prt-01.securitypete.com\PRT-SYD-01 and \\prt-01.securitypete.com\PRT-SYD-02.

.\Map-Printers.ps1 -PrintServerFQDN prt-01.securitypete.com -PrinterShareNames PRT-SYD-01 -RemoveOnly
This will just remove the printer at \\prt-01.securitypete.com\PRT-SYD-01 without re-adding after.

.Notes
Name: Map-Printer.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 14/10/2021

.Link
https://peterdodemont.com/
#>

Param
(
[Parameter(Mandatory=$true)]
[ValidateScript({If($_ -like "*.*"){$true}Else{Throw "$_ is not an FQDN. Please enter a FQDN."}})]
[string]
$PrintServerFQDN
,
[Parameter(Mandatory=$true)]
[string[]]
$PrinterShareNames=@()
,
[Parameter(Mandatory=$False)]
[switch]
$RemoveFirst
,
[Parameter(Mandatory=$False)]
[switch]
$RemoveOnly
,
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\PrinterInstall.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Normalize the Print server FQDN
If ($PrintServerFQDN -notlike "\\*") {$PrintServerFQDN = "\\" + $PrintServerFQDN}

# Get the non FQDN name of the print server from the FQDN
$PrintServerName = $PrintServerFQDN.Split(".")[0]

# Remove printers
If (($RemoveFirst -eq $true) -Or ($RemoveOnly -eq $true)){
    Try {
        Foreach ($Printer in $PrinterShareNames){
            # Generate printer names
            $PrinterNameFQDN = $PrintServerFQDN + "\" + $Printer
            $PrinterName = $PrintServerName + "\" + $Printer

            # Remove Printer if it exists
            If (get-printer -Name $PrinterNameFQDN -ErrorAction SilentlyContinue) {Remove-Printer -Name $PrinterNameFQDN}
            If (get-printer -Name $PrinterName -ErrorAction SilentlyContinue) {Remove-Printer -Name $PrinterName}
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer removal error: $ErrorMsg"
    }
}

# (Re)Add printer
If ($RemoveOnly -eq $false){
    Try {
        Foreach ($Printer in $PrinterShareNames){
            # Generate correct printer name for (re)adding
            $PrinterNameFQDN = $PrintServerFQDN + "\" + $Printer

            # (Re)Add printer
            Add-Printer -ConnectionName $PrinterNameFQDN
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Printer add error: $ErrorMsg"
    }
}

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