<#
.Synopsis
Intune Proactive Remediations script to detect the Windows Hello requirments.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect if the Windows Hello (not Windows Hello for Business) requirements match the expected settings.
If they don't match remediation is triggered.

.NOTES   
Name: ProactiveRem-RegHelloLocal-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 28/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"
$DigitsRegKey = "Digits"
$LowercaseLettersRegKey = "LowercaseLetters"
$UppercaseLettersRegKey = "UppercaseLetters"
$SpecialCharactersRegKey = "SpecialCharacters"
$MinimumPINLengthRegKey = "MinimumPINLength"
$MaximumPINLengthRegKey = "MaximumPINLength"
$ExpirationRegKey = "Expiration"
$HistoryRegKey = "History"

# Set the expected values for the complexity requirements. 1 if the requirement is enabled, 2 if disabled.
[int]$DigitsRegKeyExpectedValue = "1"
[int]$LowercaseLettersRegKeyExpectedValue = "2"
[int]$UppercaseLettersRegKeyExpectedValue = "2"
[int]$SpecialCharactersRegKeyExpectedValue = "2"

# Set the expected values for minimum and maximum required PIN length. The maximum length needs to be less than 127.
[int]$MinimumPINLengthRegKeyExpectedValue = "8"
[int]$MaximumPINLengthRegKeyExpectedValue = "127"

# Set the expected value of the expiration of the PIN in days up to a maximun of 730. 0 if there is no expiry.
[int]$ExpirationRegKeyExpectedValue = "0"

# Set the expected amount of PINs that should be remember and prevented from being re-used. Up to 50 PINs can be remembered. 0 disables history.
[int]$HistoryRegKeyExpectedValue = "0"

# Get current values of registry keys
$DigitsRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $DigitsRegKey -ErrorAction SilentlyContinue
$LowercaseLettersRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $LowercaseLettersRegKey -ErrorAction SilentlyContinue
$UppercaseLettersRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $UppercaseLettersRegKey -ErrorAction SilentlyContinue
$SpecialCharactersRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $SpecialCharactersRegKey -ErrorAction SilentlyContinue
$MinimumPINLengthRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $MinimumPINLengthRegKey -ErrorAction SilentlyContinue
$MaximumPINLengthRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $MaximumPINLengthRegKey -ErrorAction SilentlyContinue
$ExpirationRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $ExpirationRegKey -ErrorAction SilentlyContinue
$HistoryRegKeyCurrentValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $HistoryRegKey -ErrorAction SilentlyContinue

# Check registry key values. If it doesn't match trigger remediation.
Try {
    # Check that reg values are within allowed values
    If (($DigitsRegKeyExpectedValue -ne 1) -AND ($DigitsRegKeyExpectedValue -ne 2)){
        Write-Host "You specified an invalid option for requiring numbers."
        Exit 1
    }
    If (($LowercaseLettersRegKeyExpectedValue -ne 1) -AND ($LowercaseLettersRegKeyExpectedValue -ne 2)){
        Write-Host "You specified an invalid option for requiring lowercase letters."
        Exit 1
    }
    If (($UppercaseLettersRegKeyExpectedValue -ne 1) -AND ($UppercaseLettersRegKeyExpectedValue -ne 2)){
        Write-Host "You specified an invalid option for requiring uppercase numbers."
        Exit 1
    }
    If (($SpecialCharactersRegKeyExpectedValue -ne 1) -AND ($SpecialCharactersRegKeyExpectedValue -ne 2)){
        Write-Host "You specified an invalid option for requiring special characters."
        Exit 1
    }
    If ($MaximumPINLengthRegKeyExpectedValue -gt 127) {
        Write-Host "The maximum PIN length needs to be less than 127."
        Exit 1
    }
    If ($MinimumPINLengthRegKeyExpectedValue -gt $MaximumPINLengthRegKeyExpectedValue){
        Write-Host "The minimum PIN length should be less than the maximum PIN length."
        Exit 1
    }
    If ($ExpirationRegKeyExpectedValue -gt 720) {
        Write-Host "The expiration needs to be less than 720 days."
        Exit 1
    }
    If ($HistoryRegKeyExpectedValue -gt 50) {
        Write-Host "The number of PINs that are remembered need to be less than 50."
        Exit 1
    }

    # Perform checks
    If ($DigitsRegKeyCurrentValue -ne $DigitsRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$DigitsRegKey has incorrect value."
        Exit 1
    }
    If ($LowercaseLettersRegKeyCurrentValue -ne $LowercaseLettersRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$LowercaseLettersRegKey has incorrect value."
        Exit 1
    }
    If ($UppercaseLettersRegKeyCurrentValue -ne $UppercaseLettersRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$UppercaseLettersRegKey has incorrect value."
        Exit 1
    }
    If ($SpecialCharactersRegKeyCurrentValue -ne $SpecialCharactersRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$SpecialCharactersRegKey has incorrect value."
        Exit 1
    }
    If ($MinimumPINLengthRegKeyCurrentValue -ne $MinimumPINLengthRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$MinimumPINLengthRegKey has incorrect value."
        Exit 1
    }
    If ($MaximumPINLengthRegKeyCurrentValue -ne $MaximumPINLengthRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$MaximumPINLengthRegKey has incorrect value."
        Exit 1
    }
    If ($ExpirationRegKeyCurrentValue -ne $ExpirationRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$ExpirationRegKey has incorrect value."
        Exit 1
    }
    If ($HistoryRegKeyCurrentValue -ne $HistoryRegKeyExpectedValue){
        Write-host "Registry key $RegKeyPath\$HistoryRegKey has incorrect value."
        Exit 1
    }

    # If all checks pass exit with success code.
    Write-Host "All registry keys have correct values."
    Exit 0
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error $ErrorMsg"
    Exit 1
}