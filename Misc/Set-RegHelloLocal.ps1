<#
.Synopsis
Script to set the Windows Hello requirements locally.

.DESCRIPTION
This script can be used to set Windows Hello (not Windows Hello for Business) requirements locally.

.NOTES   
Name: Set-RegHelloLocal.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 28/09/2021

.LINK
https://cyberunicorn.me/
#>

# Set variables for the path and names of all keys
$RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"
$DigitsRegKey = "Digits"
$LowercaseLettersRegKey = "LowercaseLetters"
$UppercaseLettersRegKey = "UppercaseLetters"
$SpecialCharactersRegKey = "SpecialCharacters"
$MinimumPINLengthRegKey = "MinimumPINLength"
$MaximumPINLengthRegKey = "MaximumPINLength"
$ExpirationRegKey = "Expiration"
$HistoryRegKey = "History"

# Set the complexity requirements. Set to 1 to enable the requirement, set to 2 to disable the requirement.
[int]$DigitsRegKeyValue = "1"
[int]$LowercaseLettersRegKeyValue = "2"
[int]$UppercaseLettersRegKeyValue = "2"
[int]$SpecialCharactersRegKeyValue = "2"

# Set the minimum and maximum required PIN length. If you don't want to enfore a maximum length set to 127 which is the longest allowed length.
[int]$MinimumPINLengthRegKeyValue = "8"
[int]$MaximumPINLengthRegKeyValue = "127"

# Set the expiration of the PIN in days up to a maximun of 730. Set to 0 if you do not want the PIN to expire.
[int]$ExpirationRegKeyValue = "0"

# Set the amount of PINs that should be remember and prevented from being re-used. Up to 50 PINs can be remembered. Set to 0 to disable history.
[int]$HistoryRegKeyValue = "0"

# Check if the registry path exists if not create it
If (!(Test-Path $RegKeyPath)){
    Try {
        # Create the new path
        New-Item $RegKeyPath -ErrorAction Stop -Force > $null
        Write-Host "Registry path created successfully"
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error creating registry path: $ErrorMsg"
        Exit 1
    }
}
# Set PIN Complexity values.
Try {
    # Check that reg values are within allowed values
    If (($DigitsRegKeyValue -ne 1) -AND ($DigitsRegKeyValue -ne 2)){
        Write-Host "You specified an invalid option for requiring numbers."
        Exit 1
    }
    If (($LowercaseLettersRegKeyValue -ne 1) -AND ($LowercaseLettersRegKeyValue -ne 2)){
        Write-Host "You specified an invalid option for requiring lowercase letters."
        Exit 1
    }
    If (($UppercaseLettersRegKeyValue -ne 1) -AND ($UppercaseLettersRegKeyValue -ne 2)){
        Write-Host "You specified an invalid option for requiring uppercase numbers."
        Exit 1
    }
    If (($SpecialCharactersRegKeyValue -ne 1) -AND ($SpecialCharactersRegKeyValue -ne 2)){
        Write-Host "You specified an invalid option for requiring special characters."
        Exit 1
    }
    If ($MaximumPINLengthRegKeyValue -gt 127) {
        Write-Host "The maximum PIN length needs to be less than 127."
        Exit 1
    }
    If ($MinimumPINLengthRegKeyValue -gt $MaximumPINLengthRegKeyValue){
        Write-Host "The minimum PIN length should be less than the maximum PIN length."
        Exit 1
    }
    If ($ExpirationRegKeyValue -gt 720) {
        Write-Host "The expiration needs to be less than 720 days."
        Exit 1
    }
    If ($HistoryRegKeyValue -gt 50) {
        Write-Host "The number of PINs that are remembered need to be less than 50."
        Exit 1
    }

    # Set the registry values
    Set-ItemProperty -Path $RegKeyPath -Name $DigitsRegKey -Value $DigitsRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $LowercaseLettersRegKey -Value $LowercaseLettersRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $UppercaseLettersRegKey -Value $UppercaseLettersRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $SpecialCharactersRegKey -Value $SpecialCharactersRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $MinimumPINLengthRegKey -Value $MinimumPINLengthRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $MaximumPINLengthRegKey -Value $MaximumPINLengthRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $ExpirationRegKey -Value $ExpirationRegKeyValue -Type Dword -ErrorAction Stop -Force
    Set-ItemProperty -Path $RegKeyPath -Name $HistoryRegKey -Value $HistoryRegKeyValue -Type Dword -ErrorAction Stop -Force

    Write-Host "Registry values set correctly"
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error setting the registry value: $ErrorMsg"
    Exit 1
}