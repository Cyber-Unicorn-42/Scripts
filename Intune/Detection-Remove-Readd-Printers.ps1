#################################################################################################
#####                                                                                       #####
#####   This script can be used in Intune proactive remediations                            #####
#####   to detect if a particular print driver is installed.                                #####
#####   If the driver is found the remediation is triggered.                                #####
#####   It can be used in conjucntion with the script that removes and re-adds printers     #####
#####   to automate updates to print drivers using Intune proactive remediations.           #####
#####                                                                                       #####
#####   V 1.0                                                                               #####
#####   Created by: Peter Dodemont                                                          #####
#####   Created On: 03/09/2021                                                              #####
#####                                                                                       #####
#################################################################################################

# Set Variables
$DriverStoreInfName= "*hprub32a_x64.inf"

# Check if driver is installed. If it is trigger remediation
Try {
    If (!(Get-WindowsDriver -Online | where {$_.OriginalFileName -like $DriverStoreInfName} -ErrorAction Stop )){
        Write-host "Driver Not Found"
        #Exit 0
    }
    Else{
        Write-Host "Driver Found"
        #Exit 1
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error $ErrorMsg"
    #Exit 1
}