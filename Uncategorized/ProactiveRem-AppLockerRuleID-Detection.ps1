<#
.Synopsis
Intune Proactive Remediations script to detect if specific applocker policy is set.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect if the applocker policy on the device contains specific rule IDs, if they don't remediation is kicked off.

.NOTES   
Name: ProactiveRem-AppLockerRuleID-Detection.ps1
Created By: Peter Dodemont
Version: 1.0
DateUpdated: 14/02/2024

.LINK
https://peterdodemont.com/
#>

# Set Variables
# Rule IDs to be used for validation, comma seperated.
$RuleIDs = @("3cf97403-1b4a-4492-8e70-98436cf78983","4f94c165-626b-4c6b-81c3-72913aacb03","86f235ad-3f7b-4121-bc95-ea8bde3a5db5")
# Get the current Applocker policy
$AppLockerPolicy = Get-AppLockerPolicy -Effective -Xml

# Check if Rule IDs exist, if not trigger remediation.
Try {
    ForEach ($RuleID in $RuleIDs) {
        $RuleIDTest = $AppLockerPolicy | Select-String -Pattern $RuleID -SimpleMatch
        If (!($RuleIDTest)){
            Write-host "$RuleID Not Found"
            Exit 1
        }
    }
    Write-host "All Rule IDs Found"
    Exit 0
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error $ErrorMsg"
    Exit 1
}
