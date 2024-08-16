Param
(
[Parameter(Mandatory=$false)]
[String]
$TranscriptPath
)

# Start transcript when Transcript parameter is passed.
Try {
    If ($TranscriptPath){
        Start-Transcript -Path "$TranscriptPath\RefreshWDACPolicy.log" -Force
    }
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Unable to start transcript: $ErrorMsg"
    Exit 431
}

# Set Variables

# Set name of the policy binary file
[String]$PolicyBinaryFilename = "{A754CB49-BA29-433E-8C32-3854DD8590B9}.cip"
# Set filename of the policy refresh tool. This tool will apply all WDAC policies on a device and is provided by Microsoft at this URL https://www.microsoft.com/en-us/download/details.aspx?id=102925
[String]$RefreshPolicyTool = "RefreshPolicy.exe"
# Set destination folder where policy files will be loaded from
[String]$DestinationFolder = $env:WinDir+"\System32\CodeIntegrity\CIPolicies\Active\"

# Copy policy file from source to destination
Try {
    Copy-Item -Path $PolicyBinaryFilename -Destination $DestinationFolder -Force
} catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Failed to copy policy to destination folder: $_" -ForegroundColor Red
    Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
    Exit 421
}

# Run the policy refresh tool
Try {
    Start-Process -FilePath $RefreshPolicyTool -Wait
} catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Failed to policy refresh tool: $_" -ForegroundColor Red
    Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
    Exit 422
}

# Regenerate .NET native images for each .NET version so they are marked as allowed to run. This is done using the ngnen utility.
Try {
    # Get ngen utility for installed .NET versions
    $NetNgenVersions = Get-ChildItem  $env:SystemRoot\Microsoft.NET\Framework ngen.exe -Recurse 
    # Run ngen utility for each version of .NET with the update parameter to regenerate images
    ForEach ($NetNgenVersion in $NetNgenVersions) { 
    Start-Process -FilePath $_.FullName -ArgumentList update
    }
} catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Failed to regenerate .NET native images: $_" -ForegroundColor Red
    Write-host "Detailed error message: $ErrorMsg" -ForegroundColor Red
    Exit 423
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