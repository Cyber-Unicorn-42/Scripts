<#
.Synopsis
Intune Proactive Remediations script to detect the Startup type of one or multiple services.

.DESCRIPTION
This script can be used in Intune proactive remediations to detect the startup type of one or multiple services.
If the startup type doesn't match the requested state for any service the remediation is triggered.

.NOTES   
Name: ProactiveRem-ServiceStartupType-Detection.ps1
Created By: Peter Dodemont
Version: 1
DateUpdated: 01/07/2024

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$ServiceNames = @("AppIDSvc") # You can use the name or displayname of the services, seperate using comma
$ServiceExpectedStartupType = "Automatic" # You can use Automatic, Manual or Disabled


# Run check for each service
ForEach ($ServiceName in $ServiceNames) {
    
    # Get the service details
    $ServiceDetails = Get-Service $ServiceName
    $ServiceCurrentStartupType = $ServiceDetails.StartType
    $ServiceDisplayName = $ServiceDetails.DisplayName

    # Check the service startup type. If it doesn't match trigger remediation.
    Try {
        If ($ServiceCurrentStartupType -eq $ServiceExpectedStartupType){
            Write-host "Service $ServiceDisplayName has correct startup type of $ServiceCurrentStartupType."
        }
        Else{
            Write-Host "Service $ServiceDisplayName has incorrect startup type of $ServiceCurrentStartupType."
            Exit 1
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error $ErrorMsg"
        Exit 1
    }
}
Exit 0