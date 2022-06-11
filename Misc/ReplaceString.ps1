<#
.Synopsis
Replace a string in a file and then restart a specified service

.DESCRIPTION
This script will replace a specified string in 1 or more files and then resart the specified service.

.Parameter TranscriptPath
The path to save the powershell transcript to.
Usefull for troubleshooting but should be disabled when deploying broadly as it will display all PowerShell input and output in a log file.

.Parameter FilePath
The full paths to the file(s) where you want to replace the string. Seperated by comma's.

.Parameter FileName
Specify the filename to look for.

.Parameter Recurse
Specify if the search should go through the file path and all subfolders and find all the files with the specified name.

.Parameter OldString
The exisiting string to look for in the file(e).

.Parameter NewString
The new string that will replace the existing string in the file(s).

.Example
.\ReplaceString.ps1 -FilePath "C:\Temp" -FileName "test.txt" -OldString "This line" -NewString "has been replaced" -Recurse

This will find all the files named text.txt in C:\Temp and all it's subfolders. Once found it will replace "This line" with "has been replaced" in each file.

.NOTES   
Name: ReplaceString.ps1
Created By: Peter Dodemont
Version: 1
Date Updated: 16/03/2022
#>

Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
,
[Parameter(Mandatory=$true)]
[string]
$FilePath
,
[Parameter(Mandatory=$true)]
[string]
$FileName
,
[Parameter(Mandatory=$false)]
[switch]
$Recurse
,
[Parameter(Mandatory=$true)]
[string]
$OldString
,
[Parameter(Mandatory=$true)]
[string]
$NewString
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\ReplaceString.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Get all the files with the specified filenames in the specified location
Try {
    If ($Recurse -eq $true) {
        $FileLocations = Get-ChildItem -Path $FilePath -Name $FileName -Recurse
    }
    Else {
        $FileLocations = Get-ChildItem -Path $FilePath -Name $FileName
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error Finding Files: $ErrorMsg"
    Exit 432
}

# Replace the string in each file found in the specified locations
If ($FileLocations) {
    Try {
        ForEach ($FileLocation in $FileLocations){
            # Combine the base path and file location to create the full path
            $FullPath = $FilePath + "\" + $FileLocation

            # Get content from file and replace string
            $NewContent = (get-content -Path $FullPath -Raw -ErrorAction Stop) -replace $OldString,$NewString 

            # Write new-content to file
            $NewContent | Set-Content -Path $FullPath
        }
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-Host "Error replacing string: $ErrorMsg"
        Exit 433
    }
}
Else {
    Write-Host "No files have been found"
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
    Exit 435
}