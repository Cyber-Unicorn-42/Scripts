<#
.Synopsis
Add items to WDAC XML policy file.

.DESCRIPTION
This script can be used to add items to a WDAC policy XML file.
It will create a new version for each xml that is being added, as well as create files for audit mode (AM) and enforced mode (EM).
It will do this for the group specified.

.Parameter CohortID
The ID's of the different groups you will rollout WDAC to. Add, remove or change the accepted values in the paramter set if the ones provided don't suit.

.Parameter AddToScan
The relative path to the XML files that need to be added.

.Parameter OldBasePolicyVersion
Specify a specific old policy version number you would like to use. If not specified the latest audit mode version found will be used.

.Parameter NewBasePolicyVersion
Specify the new version number to be used with the first xml file that was loaded. If not specified version number will increase by 0.01.

.Example
.\WDAC-MergePolicy.ps1 -CohortID 1 -AddToScan "Firefox\Firefox_11-08-2024.xml","ShareX\ShareX_uninstall.xml"
This will add the items in the Firefox_11-08-2024.xml and ShareX_uninstall.xml files to the most recent audit mode policy file version found in the path of the $PolicyPathAM variable.
Each file will be added in sequence so the version will be incremented by 2.
Each version will also have a enforced mode policy created (by copying the audit mode policy and adjusting the audit mode option).
This will be run for the group with the ID of 1.

.\WDAC-MergePolicy.ps1 -CohortID 3 -AddToScan "Firefox\Firefox_11-08-2024.xml","ShareX\ShareX_uninstall.xml" -OldBasePolicyVersion 3.42 -NewBasePolicyVersion 4.0
This will add the items in the Firefox_11-08-2024.xml and ShareX_uninstall.xml files to the audit mode policy file with version 3.42 found in the path of the $PolicyPathAM variable.
Each file will be added in sequence so the version will be incremented by 2, with the first version being 4.0. The final version will be 4.01.
Each version will also have a enforced mode policy created (by copying the audit mode policy and adjusting the audit mode option).
This will be run for the group with the ID of 3.

.NOTES   
Name: WDAC-MergePolicy.ps1
Created By: Peter Dodemont
Version: 1.0
DateUpdated: 11/08/2024

.LINK
https://peterdodemont.com/
#>

# Set parameters
param (
    [Parameter(Mandatory=$false)]
    [decimal] $OldBasePolicyVersion,
    [Parameter(Mandatory=$false)]
    [decimal] $NewBasePolicyVersion,
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("1", "2", "3")]
    [string] $CohortID,
    [Parameter(Mandatory=$true,Position=1)]
    [array] $AddToScan
)

# Set variables
# Set paths for policy XML files
[String]$PolicyPathAM = "..\Policies_AM_Cohort"+$CohortID+"\"
[String]$PolicyPathEM = "..\Policies_EM_Cohort"+$CohortID+"\"

# Set path to folder containing XML files to be added
[String]$ApplicationXMLPath = "..\Application scans\"

# Get the current date for use in file names
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Set the the policy base filenames
[String]$NewPolicyBaseNameAM = "CyberUnicorn_WDAC_AM_Cohort"
[String]$NewPolicyBaseNameEM = "CyberUnicorn_WDAC_EM_Cohort"

# Create Array to contain missing and merged XML files
$MissingXMLFiles = @()
$MergedXMLFiles = @()

# Check if old base policy version was provided, if not get the latest policy version from the most recently modified file
If ($OldBasePolicyVersion) {
    # Parse the version numbers into decimal format to be manipulated later
    [Decimal]$OldBasePolicyVersion = [Decimal]::Parse("{0:0.00}" -f ($OldBasePolicyVersion))
} Else {
    # If no policy version to supersede was provided, get the filename without extension of the most recently modified file for this cohort, using audit mode policy as base.
    [String]$OldPolicyVersionBasePath = (Get-ChildItem -Path $PolicyPathAM -File -Recurse -ErrorAction SilentlyContinue | sort -Property LastWriteTime -Descending | Select -First 1).BaseName
    # Split the filename so only the version remains
    [String]$OldBasePolicyVersion = $OldPolicyVersionBasePath -split ("_") | Select -Last 1
    # Remove the "v" character from remaining information to get just the version number
    [String]$OldBasePolicyVersion = $OldBasePolicyVersion -Replace "v"
    # Parse the version numbers into decimal format to be manipulated later
    [Decimal]$OldBasePolicyVersion = [Decimal]::Parse("{0:0.00}" -f ($OldBasePolicyVersion))
}

# Check if new policy version was provided, if not increment old policy version by 0.01 for new version number
If ($NewBasePolicyVersion) {
    # Parse the version numbers into decimal format to be manipulated later
    [Decimal]$NewBasePolicyVersion = [Decimal]::Parse("{0:0.00}" -f ($NewBasePolicyVersion))
} else {
    # Set new policy version to old policy version incremented by 0.01 and parse the version numbers into decimal format to be manipulated later
    [Decimal]$NewBasePolicyVersion = [Decimal]::Parse("{0:0.00}" -f ($OldBasePolicyVersion + 0.01))
}

# Iterate through each XML to be added to see they exist 
foreach ($SoftwareScanToAdd in $AddToScan) {

# Set variable containing full path to the XML file
$ApplicationToAddFullName = $ApplicationXMLPath+$SoftwareScanToAdd

    # Test if XML paths exist
    if (-not (Test-Path -Path $ApplicationToAddFullName)) {
        Write-Host "XML file '$ApplicationToAddFullName' does not exist, skipping merge." -ForegroundColor Red

        # Add file to array of missing files
        $MissingXMLFiles += $SoftwareScanToAdd
    }else{
        Write-Host "XML file '$ApplicationToAddFullName' exists and will be merged." -ForegroundColor Green
        
        # Set the search string old policy path (Using Audit Mode policy as base)
        $OldPolicyPathSearchString = $PolicyPathAM+"*"+$OldBasePolicyVersion+"*"
        # Get old policy file name (Using Audit Mode policy as base)
        $OldPolicyName = Get-ChildItem –Path $OldPolicyPathSearchString -File -Force -ErrorAction SilentlyContinue
        $OldBasePolicyFileXML = $OldPolicyName.FullName
        # Display old policy filename (Using Audit Mode policy as base)
        Write-Host "Old base policy XML filename (Audit mode policy used as base):" -ForegroundColor Magenta
        Write-Host $OldBasePolicyFileXML -ForegroundColor Magenta
        # Set names of new policies
        $NewPolicyNameAM = $NewPolicyBaseNameAM+$CohortID+"_"+$CurrentDate+"_v"+$NewBasePolicyVersion
        $NewPolicyNameEM = $NewPolicyBaseNameEM+$CohortID+"_"+$CurrentDate+"_v"+$NewBasePolicyVersion
        # Set full path to new policy files
        $NewBasePolicyAMFileXML = $PolicyPathAM+$NewPolicyNameAM+".xml"
        $NewBasePolicyEMFileXML = $PolicyPathEM+$NewPolicyNameEM+".xml"

        Try {
            # Merge new XML file into old policy for audit mode
            Write-Host "Starting policy merge, this could take a while to complete" -ForegroundColor DarkCyan
            Merge-CIPolicy -PolicyPaths $OldBasePolicyFileXML, $ApplicationToAddFullName  -OutputFilePath $NewBasePolicyAMFileXML | Out-Null
            # Set policy version and name on the new Audit Mode policy file (can be used when looking at the logs)
            Set-CIPolicyVersion -FilePath $NewBasePolicyAMFileXML -Version $NewBasePolicyVersion
            Set-CIPolicyIdInfo -FilePath $NewBasePolicyAMFileXML -PolicyName $NewPolicyNameAM
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error creating Audit mode policy for xml $ApplicationToAddFullName" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }
        
        Try {
            # Copy and rename Audit Mode policy to Enforce Mode folder
            Copy-Item -Path $NewBasePolicyAMFileXML -Destination $NewBasePolicyEMFileXML -Force
            # Set policy name on the new Enforce Mode policy file (can be used when looking at the logs)
            Set-CIPolicyIdInfo -FilePath $NewBasePolicyEMFileXML -PolicyName $NewPolicyNameEM
            # Change the policy file from Audit Mode to Enforce Mode
            Set-RuleOption -FilePath $NewBasePolicyEMFileXML -Option 3 -Delete
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error creating Enforce mode policy for xml $ApplicationToAddFullName" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }

        # Add file to array containing files that were merged
        $MergedXMLFiles += $SoftwareScanToAdd

        # Sleep for 10 seconds
        Start-Sleep -Seconds 10

        # Increment policy version numbers
        $OldBasePolicyVersion = [Decimal]$NewBasePolicyVersion
        $NewBasePolicyVersion = [Decimal]::Parse("{0:0.00}" -f ($NewBasePolicyVersion + 0.01))
    }
}

# Set final policy version number
$FinalPolicyVersion = $OldBasePolicyVersion

# Display message with failed XML files
if ($MissingXMLFiles) {
    Write-Host "The following XML files were NOT merged: $MissingXMLFiles" -ForegroundColor Red
    Write-Host "Please check these files exist and re-run merge for these files." -ForegroundColor Red
}
# Display message with successful XML files
if ($MergedXMLFiles) {
    Write-Host "The following XML files were merged: $MergedXMLFiles" -ForegroundColor Green
    Write-Host "The final policy version is $FinalPolicyVersion" -ForegroundColor Cyan
}