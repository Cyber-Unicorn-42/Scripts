<#
.Synopsis
Script to create file and/or folders

.DESCRIPTION
This script can be used to create one or multiple file and/or folders. It will check if the file and/or folder already exists before creating it.

.NOTES   
Name: Create-FileAndFolder.ps1
Created By: Peter Dodemont
Version: 1.1
DateUpdated: 12/03/2022

.LINK
https://cyberunicorn.me/
#>

# Set Variables
$FolderPaths = @("$Env:SystemDrive\Temp\Test\path1","$Env:SystemDrive\Test\path1\Path2")
$FilePaths = @("$Env:SystemDrive\Temp\Test.txt","$Env:SystemDrive\Test\path1\Path2\test.txt")

# Check if folders exist, if not create them.
If ($FolderPaths){
    Try {
        ForEach ($FolderPath in $FolderPaths) {
            $FolderTest = Test-Path $FolderPath

            # Get the parent and the leaf from each path
            $FolderParent = Split-Path $FolderPath -Parent
            $FolderLeaf = Split-Path $FolderPath -Leaf

            If (!($FolderTest)){
                New-item -Path $FolderParent -Name $FolderLeaf -Force -ItemType Directory
                Write-Host "Folder $FolderPath Created Successfully."
            }
            Else {
                Write-Host "Folder $FolderPath exists already."
            }
        }
        Write-Host "All Folders Created Successfully."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error $ErrorMsg"
        Exit 1
    }
}

# Check if files exist, if not create them.
If ($FilePaths){
    Try {
        ForEach ($FilePath in $FilePaths) {
            $FileTest = Test-Path $FilePath

            # Get the parent and the leaf from each path
            $FileParent = Split-Path $FilePath -Parent
            $FileLeaf = Split-Path $FilePath -Leaf

            If (!($FileTest)){
                New-item -Path $FileParent -Name $FileLeaf -Force -ItemType File
                Write-Host "File $FilePath Created Successfully."
            }
            Else {
                Write-Host "File $FilePath exists already."
            }
        }
        Write-Host "All Files Created Successfully."
    }
    Catch {
        $ErrorMsg = $_.Exception.Message
        Write-host "Error $ErrorMsg"
        Exit 1
    }
}