<#
.Synopsis
Script to set the startup type of a one or multiple services

.DESCRIPTION
This script can be used to set the startup type of a one or multiple services. The script won't check the current the state, it will just set to the desired state.

.NOTES   
Name: Set-ServiceStartupType.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 01/07/2024

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$ServiceNames = @("AppIDSvc") # You can use the name or displayname of the services, seperate using comma
$ServiceStartupType = "Automatic" # You can use Automatic, AutomaticDelayedStart, Manual or Disabled

# Run through each Service
ForEach ($ServiceName in $ServiceNames) {

    # Get service details
    $ServiceDetails = Get-Service $ServiceName
    $ServiceDisplayName = $ServiceDetails.DisplayName

    # Set startup type of each service.
    Try {
        Set-Service $ServiceName -StartupType $ServiceStartupType
        Write-Host "Startup type for service $ServiceDisplayName value set to $ServiceStartupType"
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error setting the startup type for service $ServiceDisplayName value: $ErrorMsg"
        Exit 1
    }
}