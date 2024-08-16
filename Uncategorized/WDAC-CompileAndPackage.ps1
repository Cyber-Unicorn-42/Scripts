# Set parameters
param (
    [Parameter(Mandatory=$false)]
    [string] $PolicyVersionToCompile,
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("AM", "EM")]
    [array] $EnforcementLevels,
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("1","2","3")]
    [array] $CohortIDs
    )

# Set variables
# Path to intune packaging folder
[string]$IntunePackagingFolder = "..\Intune_Deploy_Tools\"
# GUID of the base policy (used in script installing policy on each device). Update with a unique GUID for your deployment
$PolicyID = "{A754CB49-BA29-433E-8C32-3854DD8590B9}"
# Name of Intune packaging executable
$IntunePackagingTool=".\IntuneWinAppUtil.exe"
# Argument list used by Intune packaging tool
$ArgumentList = "-c $IntunePackagingFolder -s $IntunePackagingFolder"+"WDAC-RefreshPolicy.ps1 -o $IntunePackagingFolder -q"
# Packaged path and filename
$PackagedPathAndFilename  = $IntunePackagingFolder+"WDAC-RefreshPolicy.intunewin"
# Set the beginning of the path to the folder containing policy XML and Binary files
$BasePolicyPathStart = "..\Policies_"
# Set the end of the path to the folder containing policy XML and Binary files
$BasePolicyXMLPathEnd = "_Cohort"
$BasePolicyBinaryPathEnd = "_BIN_Cohort"
# Set the beginning of the path to the folder containing Intune packaged files
$IntunePackageDestinationFolderStart = "..\Intune_Package_"
# Set the beginning of the filename for the Intune package file that will be stored in the
$RenamedPackagedFilenameStart = "DeployWDACPolicyCohort"

# Check if multiple cohorts and a policy version to compile has also been specified. If they are, provide error.
If ((($CohortIDs.Count) -gt 1)-and ($PolicyVersionToCompile)) {
    # Output message
    Write-Host "Specifying multiple cohorts does not support specifying a policy version to compile." -ForegroundColor Red
    Return
}

# Run process for each provided enforcement level
Foreach ($EnforcementLevel in $EnforcementLevels) {
    # Set Variable
    # Base path to policy XML file for each enforcement level
    [string]$BasePolicyXMLPath = $BasePolicyPathStart + $EnforcementLevel + $BasePolicyXMLPathEnd
    # Base path to policy binary file for each enforcement level
    [string]$BasePolicyBinaryPath = $BasePolicyPathStart + $EnforcementLevel + $BasePolicyBinaryPathEnd
    # Destination folder of the Intune packaged files
    [string]$IntunePackageDestinationFolder = $IntunePackageDestinationFolderStart + $EnforcementLevel + "\"

    # Run process for each provided cohort
    ForEach ($CohortID in $CohortIDs) {
        # Set variables
        # Full path to policy XML file for each cohort
        [string]$FullPolicyXMLPath = $BasePolicyXMLPath + $CohortID + "\"
        # Full path to policy binary file for each cohort
        [string]$FullPolicyBinaryPath = $BasePolicyBinaryPath + $CohortID + "\"
        
        # Check if policy version was provided
        if ($PolicyVersionToCompile) {
            # Get specific policy version XML file from folder with XML files
            $PolicyXMLFile  = Get-ChildItem -Path $FullPolicyXMLPath -Include *$PolicyVersionToCompile* -File -Recurse -ErrorAction SilentlyContinue
        } else {
            # Get latest policy XML file from folder with XML files
            $PolicyXMLFile  = Get-ChildItem -Path $FullPolicyXMLPath -File -Recurse -ErrorAction SilentlyContinue | Sort LastWriteTime | select -last 1
            # Get policy version from the filename by first spit by the last underscore character followed by removing the letter v
            [string]$NewPolicyVersionToCompile = ($PolicyXMLFile.BaseName).split("_")[-1]
            [string]$NewPolicyVersionToCompile = $NewPolicyVersionToCompile -Replace "v"
        }

        If (!($PolicyXMLFile)){
            Write-host "Error getting details of policy XML file" -ForegroundColor Red
            Return
        }

        # Set variables that include details gathered above
        # Full path, including filename, to policy XML file 
        $FullPathToPolicyXML = $PolicyXMLFile.FullName
        # Path and filename for binary policy file
        $BinaryPolicyPathAndFilename = $FullPolicyBinaryPath + $PolicyXMLFile.BaseName + ".cip"
        # Path and filename with GUID for Intune package. As per Microsoft documentation: Policy binary files should be named as {GUID}.cip for multiple policy format files (where {GUID} = <PolicyId> from the Policy XML)
        $IntuneBinaryPolicyPathAndFilename  = $IntunePackagingFolder + $PolicyID + ".cip"
        # Path and filename of the renamed Intune package
        $RenamedPackagedPathAndFilename = $IntunePackageDestinationFolder + $RenamedPackagedFilenameStart + $CohortID + $EnforcementLevel + $NewPolicyVersionToCompile + ".intunewin"

        # Generate new WDAC Policy binary file for cohort and Enforcement level.
        Try {
            ConvertFrom-CIPolicy -XmlFilePath $FullPathToPolicyXML -BinaryFilePath $BinaryPolicyPathAndFilename
            Write-Host "Binary policy file for $EnforcementLevel cohort $CohortID version $NewPolicyVersionToCompile successfully generated" -ForegroundColor Magenta
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error generating WDAC policy" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }

        # Copy generated binary policy to Intune packaging folder
        Try {
            
            Copy-Item -Path $BinaryPolicyPathAndFilename -Destination $IntuneBinaryPolicyPathAndFilename -Force
            Write-Host "Binary policy file for $EnforcementLevel cohort $CohortID version $NewPolicyVersionToCompile successfully copied to Intune packaging folder" -ForegroundColor Magenta
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-host "Error copying binary policy file to Intune packaging folder" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }

        # Run Intune packaging tool
        Try {
            (Start-Process -FilePath $IntunePackagingTool -ArgumentList $ArgumentList -PassThru:$true -ErrorAction Stop -NoNewWindow).WaitForExit()
            Write-host "Intune package for $EnforcementLevel cohort $CohortID version $NewPolicyVersionToCompile successfully generated" -ForegroundColor Magenta
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error running Intune packaging tool" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }

        # Move the packaged file to final destination
        Try {
            Move-Item -Path $PackagedPathAndFilename -Destination $RenamedPackagedPathAndFilename -Force
            Write-Host "Intune package for $EnforcementLevel cohort $CohortID version $NewPolicyVersionToCompile successfully moved to final destination" -ForegroundColor Magenta
        } Catch {
            $ErrorMsg = $_.Exception.Message
            Write-Host "Error moving Intune package to final destination" -ForegroundColor Red
            Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
            Return
        }

        # Remove variables that could cause issues on next run
        Remove-Variable FullPolicyXMLPath -Force
        Remove-Variable FullPolicyBinaryPath -Force
        Remove-Variable PolicyXMLFile -Force
        Remove-Variable FullPathToPolicyXML -Force
        Remove-Variable BinaryPolicyPathAndFilename -Force
        Remove-Variable IntuneBinaryPolicyPathAndFilename -Force
        Remove-Variable RenamedPackagedPathAndFilename -Force
        Remove-Variable NewPolicyVersionToCompile -Force

        # Display final success message
        Write-Host "$EnforcementLevel Cohort $CohortID version $NewPolicyVersionToCompile successfully generated and packaged" -ForegroundColor Green
    }
    # Remove variables that could cause issues on next run
    Remove-Variable BasePolicyXMLPath -Force
    Remove-Variable BasePolicyBinaryPath -Force
    Remove-Variable IntunePackageDestinationFolder -Force
}
# Display final completion message
Write-Host "All policies successfully generated and packaged" -ForegroundColor DarkGreen