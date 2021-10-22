<#
.Synopsis
Install SQL Express with default settings

.DESCRIPTION
This script will install SQL Express 2019 with default settings. You will need to download the SQL install file and generate a configuration file to use.
The script can also remove start menu shortcuts if dsesired. It assumes the configuration file is in the same folder as the exe

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Parameter ConfigFile
Name of the config file. The config file should be located in the same folder as setup.exe.

.Parameter SQLInstallFilesPath
Relative path to the location of the setup.exe file if it is in a sub-folder.

.Parameter RemoveShortcuts
When specified removes shortcuts created in the start menu.

.Example
.\Install-SQLExpress.ps1 ConfigFile Install.ini -SQLInstallFilesPath SQLExpress -RemoveShortcuts
This will install SQL Express using the install.ini configuration file located in the SQLExpress subfolder relative to where the PowerShell script is located.
Finally it will remove the shortcuts created in the start menu.

.\Install-SQLExpress.ps1 ConfigFile Install.ini -TranscriptPath
This will install SQL Express using the install.ini configuration file located in the same folder where the PowerShell script is run from.
A transcript of the input and outputs will be added in c:\temp\SQLExpress2019Install.log

.NOTES   
Name: Install-SQLExpress.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 14/10/2021
#>

Param
(
[Parameter(Mandatory=$true)]
[string]
$ConfigFile
,
[parameter(Mandatory=$false)]
[ValidateScript({If(Get-Childitem $_ | Where Name -eq "setup.exe"){$true}Else{Throw "Setup.exe not found. Please specify the path that contains setup.exe"}})]
[String]
$SQLInstallFilesPath
,
[Parameter(Mandatory=$false)]
[switch]
$RemoveShortcuts
,
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\SQLExpress2019Install.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Set Variable
If ($SQLInstallFilesPath -eq "") {
    $SqlSetupLocation = "setup.exe"
    $SqlConfigLocation = $ConfigFile
}
Else {
    $SqlSetupLocation = $SQLInstallFilesPath + "\setup.exe"
    $SqlConfigLocation = $SQLInstallFilesPath + "\" + $ConfigFile
}

# Check if ODBC Driver 17 is installed already and remove it. Otherwise SQL instrall will fail.
Try {
    $ODBC17 = Get-WmiObject -Class Win32_Product -Property IdentifyingNumber -Filter "IdentifyingNumber = '{12DC69AF-787B-4D76-B69D-2716DACA79FB}'" -Namespace root\cimv2
    If ($ODBC17.IdentifyingNumber -eq "{12DC69AF-787B-4D76-B69D-2716DACA79FB}") {
        msiexec /x "{12DC69AF-787B-4D76-B69D-2716DACA79FB}" /q
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error uninstalling ODBC Driver 17: $ErrorMsg"
    Exit 421
}

# Install SQL
Try {
    Start-Process $SqlSetupLocation -ArgumentList "/q /SUPPRESSPRIVACYSTATEMENTNOTICE /ConfigurationFile=$SqlConfigLocation" -Wait
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error Install SQL Express: $ErrorMsg"
    Exit 422
}

# Remove Start Menu Shortcuts
If ($RemoveShortcuts -eq $true){
    Try {
        Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft SQL Server 2019" -Force -Recurse
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error Removing SQL Express Shortcuts: $ErrorMsg"
        Exit 423
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