# Set Parameters
param (
    [Parameter(Mandatory=$false)]
    [String] $PolicyVersionToSupersede,
    [Parameter(Mandatory=$false)]
    [String] $PolicyVersionToUpload,
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("AM", "EM")]
    [Array] $EnforcementLevels,
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("1", "3")]
    [Array] $CohortIDs,
    [Parameter(Mandatory=$false)]
    [Switch] $RemoveOldAssignments,
    [Parameter(Mandatory=$false)]
    [Switch] $RemoveOldestDeployment
    )

# Check if multiple cohorts and a policy version to upload has also been specified. If they are, provide error.
If ((($CohortIDs.Count) -gt 1)-and ($PolicyVersionToUpload)) {
    # Output message
    Write-Host "Specifying multiple cohorts does not support specifying a policy version to upload." -ForegroundColor Red
    Return
}
# Check if multiple cohorts and a policy version to supersede has also been specified. If they are, provide error.
If ((($CohortIDs.Count) -gt 1)-and ($PolicyVersionToSupersede)) {
    # Output message
    Write-Host "Specifying multiple cohorts does not support specifying a policy version to supersede." -ForegroundColor Red
    Return
}

# Check if Azure AD module is installed, if not install it
If (-not ((Get-Module -ListAvailable -Name AzureAD) -or (Get-Module -ListAvailable -Name AzureADPreview))) {Install-Module AzureAD -Force -AllowClobber -scope CurrentUser}
 
# Load Azure AD module
If (-not ((Get-Module AzureAD) -or (Get-Module AzureADPreview))) {Import-Module AzureAD -Force}

# Check if IntuneWin32App is installed, if not install it
If (-not ((Get-Module -ListAvailable -Name IntuneWin32App))) {Install-Module IntuneWin32App -Force -AllowClobber -Scope CurrentUser}

# Check if IntuneWin32App is version 1.4.4 or higher, if not upgrade it
Try { 
    If (-not ((Get-Module -ListAvailable -Name IntuneWin32App)).Version -ge [System.Version]"1.4.4") {Update-Module IntuneWin32App -Force}
} Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error updating IntuneWin32App to latest verions, please update it manually and re-run the script" -ForegroundColor Red
    Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
    Return
}
 
# Load IntuneWin32App
If (-not ((Get-Module IntuneWin32App))) {Import-Module IntuneWin32App -Force}

# Base display name (used for getting details of previous package and setting the name if no previous package was found)
[String]$BaseDisplayName = "Application Control"

# Detection script path and filename
$DetectionScriptPathAndFilename = "..\Intune_Deploy_Tools\WDAC-Detection.ps1"

# Authenticate to Intune
Connect-MSIntuneGraph -TenantID "CyberUnicorn" -ClientID "9123179d-c307-44de-83df-c4381aa1e61e"

# Run commands for each supplied enforcement level
ForEach ($EnforcementLevel in $EnforcementLevels) {
    # Set variables
    # Add enforcement level to base display name
    Switch ($EnforcementLevel) {
        "AM" {[String]$EnforcementDisplayName = " Audit " + $BaseDisplayName}
        "EM" {[String]$EnforcementDisplayName = " Enforced " + $BaseDisplayName}
        Default {
            Write-Host "You managed to specify an enforcement level that is not allowed" -ForegroundColor Cyan
            Return
        }
    }
    # Path to folder with the Intune packaged files
    [string]$IntunePackagesFolder = "..\Intune_Package_" + $EnforcementLevel + "\"
    # String used for detection of enforcement level in detection script
    [string]$EnforcementDetectionString = "CyberUnicorn_WDAC_" + $EnforcementLevel + "_"

    # Create variable for old display name here so it will remain available after being set inside for each loop below
    [String]$OldDeploymentDisplayName = ""

    ForEach ($CohortID in $CohortIDs) {
        # Display message to advise what package upload is being started
        Write-Host "Application deployment for cohort $CohortID $EnforcementLevel has started" -ForegroundColor DarkMagenta
        # Add cohort ID to enforcement level display name
        Switch ($CohortID) {
            1 {[String]$CohortDislayName = "Cohort " + $CohortID + $EnforcementDisplayName }
            3 {[String]$CohortDislayName = "Cohort " + $CohortID + $EnforcementDisplayName }
            Default {
                Write-Host "You managed to specify an cohort that is not allowed" -ForegroundColor Cyan
                Return
            }
        }

        # Get details of previous deployment
        # Check if a version to supersede was provided
        If ($PolicyVersionToSupersede) {
            # Set display name of old deployment
            [String]$OldDeploymentDisplayName = $CohortDislayName + " " + $PolicyVersionToSupersede
            # Get the details of the old deployment
            $OldDeploymentDetails = Get-IntuneWin32App -DisplayName $OldDeploymentDisplayName -ErrorAction SilentlyContinue
        }
        Else {
            # If no version to supersede was provided get the details of the highest version deployment
            $OldDeploymentDetails = Get-IntuneWin32App -DisplayName $CohortDislayName -ErrorAction SilentlyContinue | Sort -Property DisplayVersion -Descending | select -First 1
            # Set old policy version dislay name
            $OldDeploymentDisplayName = $OldDeploymentDetails.DisplayName
        }

        # Get assignment details of previous deployment
        [Array]$OldDeploymentAssignments = Get-IntuneWin32AppAssignment -ID ($OldDeploymentDetails.ID)

        # Absolute path to Intune file to upload
        # Check if policy version to upload was provided
        If ($PolicyVersionToUpload) {
            # Base path to Intune package file to upload
            [String]$BaseUploadIntunePackagePath = $IntunePackagesFolder + "DeployWDACPolicyCohort" + $CohortID + $EnforcementLevel
            # Set relative path to Intune package file to upload
            [String]$UploadIntunePackageRelatviePath = $BaseUploadIntunePackagePath + $PolicyVersionToUpload + ".intunewin"
            # Set absolute path to Intune package file to upload
            [String]$UploadIntunePackageAbsolutePath = (Get-childItem -Path $UploadIntunePackageRelatviePath -File -Recurse -ErrorAction SilentlyContinue).FullName
            # Set display version for new deployment
            [String]$NewDisplayVersion = $PolicyVersionToUpload
        } Else {
            # If no policy version to upload was provided, set absolute path to the most recently modified file for this enforcement level and cohort
            # Searchstring used for selecting files
            [String]$UploadIntunePackageSearch = "DeployWDACPolicyCohort" + $CohortID + $EnforcementLevel
            # Get details of the most recent file version
            $UploadIntunePackageDetails = Get-ChildItem -Path $IntunePackagesFolder -Include $UploadIntunePackageSearch* -File -Recurse -ErrorAction SilentlyContinue | sort -Property LastWriteTime -Descending | Select -First 1
            # If no policy version to upload was provided, set absolute path to the most recently modified file for this enforcement level and cohort
            [String]$UploadIntunePackageAbsolutePath = $UploadIntunePackageDetails.FullName
            # Get filename with out extension for the Intune package file to upload
            [String]$UploadIntunePackageBaseName = $UploadIntunePackageDetails.BaseName
            # Set display version for new deployment
            [String]$NewDisplayVersion = $UploadIntunePackageBaseName -split ($UploadIntunePackageSearch) | Select -Last 1
        }
        If ($null -eq $UploadIntunePackageAbsolutePath) {
            Write-Host "No package found to upload to Intune" -ForegroundColor Red
            Return
        }
        
        # Populate details for new Win32
        # Create requirements rule
        $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedWindowsRelease W10_1909
        # Set detection rule details
        # String used for detection of cohort in detection script 
        [string]$CohortDetectionString = "_Cohort" + $CohortID
        # Create content for PowerShell script used for detection
        $DetectionScript = @'
$PolicyLoadEvent = Get-WinEvent -LogName Microsoft-Windows-CodeIntegrity/Operational -FilterXPath "*[System/EventID=3099]" | Select -First 1
$EventMessage = $PolicyLoadEvent.Message
Try {
 If ($EventMessage -like "*
'@ + $EnforcementDetectionString + @'
*") {
  If ($EventMessage -like "*
'@ + $CohortDetectionString + @'
*") {
   If ($EventMessage -like "*v
'@ + $NewDisplayVersion + @'
*") {
    Write-Host "Correct WDAC policy detected"
    Exit 0
   } Else {
    Write-Host "Incorrect WDAC policy version detected"
    Exit 1
   }
  } Else {
    Write-Host "Incorrect WDAC cohort detected"
    Exit 1
  } 
 } Else {
    Write-Host "Incorrect WDAC enforcement level detected"
    Exit 1
 }
} Catch {
 $ErrorMsg = $_.Exception.Message
 Write-Host "Error during detection on WDAC policy version"
 Write-Host "Detailed error message: $ErrorMsg"
 Exit 1
}
'@
        Try {
            # Check if detection script file already exists
            If ($DetectionScriptPathAndFilename) {
                # If detection script file exists clear content of file
                Clear-Content -Path $DetectionScriptPathAndFilename -Force
            } Else {
                # If script file does not exist ,create PowerShell script file used for detection
                New-Item -Path $DetectionScriptPathAndFilename -ItemType File -Force | Out-Null
            }
            # Populate the conent of the PowerShell script file with the script for detecting the new version
            Set-Content -Path $DetectionScriptPathAndFilename -Value $DetectionScript

            Write-Host "PowerShell detection script successfully generated" -ForegroundColor Magenta
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error Creating PowerShell Detection Script" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }
        # Create detection rule
        $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $DetectionScriptPathAndFilename
        # Set new display name
        $NewDisplayName = $CohortDislayName + " " + $NewDisplayVersion

        # If old deployment is found use that for the details
        If ($OldDeploymentDetails){
            [String]$NewPublisher = $OldDeploymentDetails.Publisher
            [String]$NewInstallExperience = $OldDeploymentDetails.InstallExperience.RunAsAccount
            [String]$NewDeviceRestartBehavior = $OldDeploymentDetails.InstallExperience.DeviceRestartBehavior
            [String]$NewInstallCommandLine = $OldDeploymentDetails.InstallCommandLine
            [String]$NewUninstallCommandLine = $OldDeploymentDetails.UninstallCommandLine
            
        } Else {
            # If no old deployment is found use these default values
            [String]$NewPublisher = "Microsoft"
            [String]$NewInstallExperience = "system" # valid options are system or user
            [String]$NewDeviceRestartBehavior = "suppress" # valid options are allow, basedOnReturnCode, suppress or force.
            [String]$NewInstallCommandLine = "PowerShell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command .\Refresh-WDACPolicy.ps1"
            [String]$NewUninstallCommandLine = "PowerShell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command .\Refresh-WDACPolicy.ps1"
        }
        # Populate details for Win32 app upload
        $Win32AppDetails = @{
            "FilePath" = $UploadIntunePackageAbsolutePath
            "AppVersion" = $NewDisplayVersion
            "DisplayName" = $NewDisplayName
            "Description" = $NewDisplayName
            "Publisher" = $NewPublisher
            "InstallExperience" = $NewInstallExperience
            "RestartBehavior" = $NewDeviceRestartBehavior
            "DetectionRule" = $DetectionRule
            "RequirementRule" = $RequirementRule
            "InstallCommandLine" = $NewInstallCommandLine
            "UninstallCommandLine" = $NewUninstallCommandLine
        }
        # Run upload and store output in a variable for later, so ID of the newly created deployment can be retrieved
        $NewDeploymentDetails = Add-IntuneWin32App @Win32AppDetails

        # Check if upload was successfull
        If ($NewDeploymentDetails) {
            Write-Host "Upload of application deployment for $NewDisplayName successfull" -ForegroundColor Green
        } Else {
            Write-Host "Upload of application deployment for $NewDisplayName failed" -ForegroundColor Red
            Return
        }

        # Check if old deployment assignments exist
        If ($OldDeploymentAssignments) {
            # If old deployment assignments exist, iterate through each and re-add to the new deployment
            ForEach ($OldDeploymentAssignment in $OldDeploymentAssignments){
                # Set values for the assignment
                # Set ID of the newly uploaded deployment
                $NewDeploymentAssignentDetails = @{"ID" = $NewDeploymentDetails.ID}
                # Set the same group ID as the old assignment
                $NewDeploymentAssignentDetails += @{"GroupID" = $OldDeploymentAssignment.GroupID}
                # Set the same intent as the old assignment
                $NewDeploymentAssignentDetails += @{"Intent" = $OldDeploymentAssignment.Intent}
                # Check if old assignment was an exclude or include assignment
                If ($OldDeploymentAssignment.GroupMode -eq "Exclude") {
                    # Set group mode
                    $NewDeploymentAssignentDetails += @{"Exclude" = $true}
                } Elseif ($OldDeploymentAssignment.GroupMode -eq "Include") {
                    # Set group mode
                    $NewDeploymentAssignentDetails += @{"Include" = $true}
                    # Get notification setting from old assignment
                    $NewDeploymentAssignentDetails += @{"Notification" = $OldDeploymentAssignment.Notifications}
                    # Check if intent is required
                    If ($OldDeploymentAssignment.Intent -eq "required") {
                        # Set assignment available and dealine time
                        $NewDeploymentAssignmentTime = (Get-Date).AddMinutes(5)
                        $NewDeploymentAssignentDetails += @{"AvailableTime" = $NewDeploymentAssignmentTime}
                        $NewDeploymentAssignentDetails += @{"DeadlineTime" = $NewDeploymentAssignmentTime}
                        # Get as UTC or local time
                        $NewDeploymentAssignentDetails += @{"UseLocalTime" = $true}
                    }
                } Else {
                    [String]$SkipAssignment = "yes"
                }
                # Check if assignment should be skipped
                If ($SkipAssignment -eq "yes") {
                    Write-Host "Unknown groupmode, skipping this assignment" -ForegroundColor Magenta
                } Else {
                    # Add assignment to new deployment
                    Try {
                        Add-IntuneWin32AppAssignmentGroup @NewDeploymentAssignentDetails
                    } Catch {
                        $ErrorMsg = $_.Exception.Message
                        Write-Host "Error assigning group to new deployment: $NewDisplayName" -ForegroundColor Red
                        Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                        Return
                    }

                    # Get name of group of the assignment of the old deployment
                    $NewDeploymentAssignentGroupName = $OldDeploymentAssignment.GroupName
                    # Get intent of the assignment of the old deployment
                    $NewDeploymentAssignentIntent = $OldDeploymentAssignment.Intent
                    Write-host "Group $NewDeploymentAssignentGroupName was assigned as an $NewDeploymentAssignentIntent assignment to application deployment $NewDisplayName" -ForegroundColor Green
                }

                # Clear skip assignment variable before next run, if it exists
                If ($SkipAssignment -eq "yes") {
                    Remove-Variable -Name SkipAssignment -Force
                }
            }
            # Remove assignments from previous deployment
            If ($RemoveOldAssignments) {
                Try {
                    ForEach ($OldDeploymentAssignment in $OldDeploymentAssignments){
                        Remove-IntuneWin32AppAssignmentGroup -ID $OldDeploymentDetails.ID -GroupID $OldDeploymentAssignment.GroupID
                    }
                    Write-Host "Removed all assignments from $OldDeploymentDisplayName"
                } Catch {
                    $ErrorMsg = $_.Exception.Message
                    Write-Host "Error removing assigned group from old deployment: $OldDeploymentDisplayName" -ForegroundColor Red
                    Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                    Return
                }
            }
        } Else {
            # Use these default groups id no old assignments exist
            # Check enforcement level
            Switch ($EnforcementLevel) {

                "AM" {
                    # Check Cohort ID
                    Switch ($CohortID) {
                        1 {
                            $DefaultRequiredGroups = @(
                            "GRP - FUNC - WDAC Audit - PRD - Required")
                        
                            $DefaultAvailableGroups = @(
                            "GRP - FUNC - WDAC Audit - PRD - Available")
                        }
                        3 {
                            $DefaultRequiredGroups = @(
                            "GRP - FUNC - Cohort 3 Audit Application Control - PRD - Required")
                            $DefaultAvailableGroups = @(
                            "GRP - FUNC - Cohort 3 Audit Application Control - PRD - Available")
                        }
                    }
                }
                "EM" {
                    # Check Cohort ID
                    Switch ($CohortID) {
                        1 {
                            $DefaultRequiredGroups = @(
                            "GRP - FUNC - WDAC Enforced - QA - Required",
                            "All Windows 10 Corporate Devices",
                            "All Windows 11 Corporate Devices")
                        
                            $DefaultExcludedGroups = @(
                            "GRP - FUNC - Cohort 3 Audit Application Control - PRD - Required",
                            "GRP - FUNC - Cohort 3 Enforced Application Control - PRD - Required",  
                            "GRP - FUNC - WDAC Audit - PRD - Available",
                            "GRP - FUNC - WDAC Audit - PRD - Required", 
                            "GRP - Intune - PCR - WDAC Deployment Testing - Enforced", 
                            "GRP - Intune - PCR - WDAC Deployment Testing Dev - Audit")
                        
                            $DefaultAvailableGroups = @(
                            "GRP - FUNC - Cohort 1 Enforced Application Control - PRD - Available")
                        }
                        3 {
                            $DefaultRequiredGroups = @(
                            "GRP - FUNC - Cohort 3 Enforced Application Control - PRD - Required")

                            $DefaultExcludedGroups = @(
                            "GRP - FUNC - WDAC Audit - PRD - Required",
                            "GRP - FUNC - WDAC Audit - PRD - Available",
                            "GRP - FUNC - Cohort 3 Audit Application Control - PRD - Required")

                            $DefaultAvailableGroups = @(
                            "GRP - FUNC - Cohort 3 Enforced Application Control - PRD - Available")
                        }
                    }
                }
            }
            # Run assignments for each default group
            # Connect to Azure AD to be able retrieve object ID of groups
            Connect-AzureAD

            # Run assignments for excluded groups
            # Check there are excluded groups to add
            if ($DefaultExcludedGroups.Count -gt 0) {
                # Run assignment for each excluded group
                foreach ($ExcludedGroup in $DefaultExcludedGroups) {
                    # Get the object ID of the group from Azure AD
                    $NewDeploymentAssignmentGroupID = Get-AzureADGroup -SearchString $ExcludedGroup | Select-Object -ExpandProperty "ObjectId"
                    # Set values for the assignment
                    $NewDeploymentAssignentDetails = @{
                        "Exclude" = $true
                        "ID" = $NewDeploymentDetails.ID
                        "GroupID" = $NewDeploymentAssignmentGroupID
                        "Intent" = "required"
                    }
                    # Add assignment to new deployment
                    Try {
                        Add-IntuneWin32AppAssignmentGroup @NewDeploymentAssignentDetails
                    } Catch {
                        $ErrorMsg = $_.Exception.Message
                        Write-Host "Error adding default excluded group $ExcludedGroup to deployment $NewDisplayName" -ForegroundColor Red
                        Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                        Return
                    }
                    Write-host "Group $ExcludedGroup was assigned as an excluded assignment to application deployment $NewDisplayName" -ForegroundColor Green
                }
                # Remove variables that could cause issues on next run
                Remove-Variable -Name DefaultExcludedGroups -Force          
            }
            # Check there are required groups to add
            if ($DefaultRequiredGroups.Count -gt 0) {
                # Run assignment for each excluded group        
                foreach ($RequiredGroup in $DefaultRequiredGroups) {
                    # Get the object ID of the group from Azure AD
                    $NewDeploymentAssignmentGroupID = Get-AzureADGroup -SearchString $RequiredGroup | Select-Object -ExpandProperty "ObjectId"
                    # Set values for the assignment
                    $NewDeploymentAssignentDetails = @{
                        "Include" = $true
                        "ID" = $NewDeploymentDetails.ID
                        "GroupID" = $NewDeploymentAssignmentGroupID
                        "Intent" = "required"
                        "Notification" = "hideAll"
                        "AvailableTime" = (Get-Date).AddMinutes(5)
                        "DeadlineTime" = (Get-Date).AddMinutes(5)
                        "UseLocalTime" = $true
                    }
                    # Add assignment to new deployment      
                    Try {  
                        Add-IntuneWin32AppAssignmentGroup @NewDeploymentAssignentDetails
                    } Catch {
                        $ErrorMsg = $_.Exception.Message
                        Write-Host "Error adding default excluded group $RequiredGroup to deployment $NewDisplayName" -ForegroundColor Red
                        Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                        Return
                    }
                    Write-host "Group $RequiredGroup was assigned as an required assignment to application deployment $NewDisplayName" -ForegroundColor Green
                }
                # Remove variables that could cause issues on next run
                Remove-Variable -Name DefaultRequiredGroups -Force 
            }
            # Check there are available groups to add
            if ($DefaultAvailableGroups.Count -gt 0) {
                # Run assignment for each excluded group 
                foreach ($AvailableGroup in $DefaultAvailableGroups) {
                    # Get the object ID of the group from Azure AD
                    $NewDeploymentAssignmentGroupID = Get-AzureADGroup -SearchString $AvailableGroup | Select-Object -ExpandProperty "ObjectId"
            
                    # Set values for the assignment
                    $NewDeploymentAssignentDetails = @{
                    "Include" = $true
                        "ID" = $NewDeploymentDetails.ID
                        "GroupID" = $NewDeploymentAssignmentGroupID
                        "Intent" = "available"
                        "Notification" = "showAll"
                    }
                    # Add assignment to new deployment
                    Try {
                        Add-IntuneWin32AppAssignmentGroup @NewDeploymentAssignentDetails
                    } Catch {
                        $ErrorMsg = $_.Exception.Message
                        Write-Host "Error adding default excluded group $AvailableGroup to deployment $NewDisplayName" -ForegroundColor Red
                        Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                        Return
                    }
                    Write-host "Group $AvailableGroup was assigned as an available assignment to application deployment $NewDisplayName" -ForegroundColor Green
                }
                # Remove variables that could cause issues on next run
                Remove-Variable -Name DefaultAvailableGroups -Force
            }
        }
        # Create supersedence rule
        $NewDeploymentSupersedenceRule = New-IntuneWin32AppSupersedence -ID $OldDeploymentDetails.id -SupersedenceType "Update" # Replace for uninstall, Update for updating
        Try {
            Add-IntuneWin32AppSupersedence -ID $NewDeploymentDetails.id -Supersedence $NewDeploymentSupersedenceRule
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error adding supersedence rule to deployment $NewDisplayName" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }
        Write-Host "$NewDisplayName set to supersede $OldDeploymentDisplayName" -ForegroundColor Green

        # Remove oldest deployment
        If ($RemoveOldestDeployment) {
            Try {
                # Remove supersedence rule from old deployment
                Remove-IntuneWin32AppSupersedence -ID $OldDeploymentDetails.id

                # Get oldest deployment details
                $OldestDeploymentDetails = Get-IntuneWin32App -DisplayName $CohortDislayName -ErrorAction SilentlyContinue | Sort -Property DisplayVersion -Descending | select -Last 1
                # Get ID of oldest deployment
                $OldestDeploymentID = $OldestDeploymentDetails.ID
                # Get display name of oldest deployment
                $OldestDeploymentDisplayName = $OldestDeploymentDetails.DisplayName
                # Remove oldest deployment
                Remove-IntuneWin32App -ID $OldestDeploymentID
                Write-Host "Deployment $OldestDeploymentDisplayName was successfully deleted." -ForegroundColor DarkCyan
                # Remove variables that could cause issues on next run
                Remove-Variable -Name OldestDeploymentID -Force
            } Catch {
                $ErrorMsg = $_.Exception.Message
                Write-Host "Error deleting oldest deployment: $OldestDeploymentDisplayName" -ForegroundColor Red
                Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
                Return
            }
        }

        # Remove variables that could cause issues on next run
        Remove-Variable -Name NewDeploymentSupersedenceRule -Force
        Remove-Variable -Name OldDeploymentDetails -Force
        Remove-Variable -Name NewDeploymentDetails -Force
        Remove-Variable -Name OldDeploymentAssignments -Force
        Remove-Variable -Name DetectionRule -Force

        # Sleep for 60 seconds to let Intune finish processing the upload
        Start-Sleep -Seconds 60
    }
}
