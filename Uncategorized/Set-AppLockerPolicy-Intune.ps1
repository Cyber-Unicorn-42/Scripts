<#
.Synopsis
Set a new applocker policy through Powershell.

.DESCRIPTION
This script can be used to set an applocker policy through Intune, for example if you need to set multiple managed installers for Windows Defender Application Control.

.NOTES   
Name: Set-AppLockerPolicy-Intune.ps1
Created By: Peter Dodemont
Version: 1.0
DateUpdated: 14/02/2024

.LINK
https://cyberunicorn.me/
#>

# Set Variables
# New Applocker policy to apply
$NewPolicy = @"
<AppLockerPolicy Version="1">
<RuleCollection Type="Dll" EnforcementMode="AuditOnly" >
    <FilePathRule Id="86f235ad-3f7b-4121-bc95-ea8bde3a5db5" Name="Benign DENY Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
      <Conditions>
        <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.dll" />
      </Conditions>
    </FilePathRule>
    <RuleCollectionExtensions>
      <ThresholdExtensions>
        <Services EnforcementMode="Enabled" />
      </ThresholdExtensions>
      <RedstoneExtensions>
        <SystemApps Allow="Enabled"/>
      </RedstoneExtensions>
    </RuleCollectionExtensions>
  </RuleCollection>
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePathRule Id="9420c496-046d-45ab-bd0e-455b2649e41e" Name="Benign DENY Rule" Description="" UserOrGroupSid="S-1-1-0" Action="Deny">
      <Conditions>
        <FilePathCondition Path="%OSDRIVE%\ThisWillBeBlocked.exe" />
      </Conditions>
    </FilePathRule>
    <RuleCollectionExtensions>
      <ThresholdExtensions>
        <Services EnforcementMode="Enabled" />
      </ThresholdExtensions>
      <RedstoneExtensions>
        <SystemApps Allow="Enabled"/>
      </RedstoneExtensions>
    </RuleCollectionExtensions>
  </RuleCollection>
  <RuleCollection Type="ManagedInstaller" EnforcementMode="AuditOnly">
	<FilePublisherRule Id="3cf97403-1b4a-4492-8e70-98436cf78983" Name="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE version 1.37.200.8 or above in MICROSOFT INTUNE from O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" Description="2" UserOrGroupSid="S-1-1-0" Action="Allow">
    <Conditions>
      <FilePublisherCondition PublisherName="O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US" ProductName="*" BinaryName="MICROSOFT.MANAGEMENT.SERVICES.INTUNEWINDOWSAGENT.EXE">
        <BinaryVersionRange LowSection="1.37.200.8" HighSection="*" />
      </FilePublisherCondition>
    </Conditions>
  </FilePublisherRule>
  <FilePublisherRule Id="4f94c165-626b-4c6b-81c3-72913aacb036" Name="CREATIVE CLOUD DESKTOP version 6.0.0.571 or above in CREATIVE CLOUD DESKTOP from O=ADOBE INC., L=SAN JOSE, S=CA, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
    <Conditions>
      <FilePublisherCondition PublisherName="O=ADOBE INC., L=SAN JOSE, S=CA, C=US" ProductName="CREATIVE CLOUD DESKTOP" BinaryName="CREATIVE CLOUD DESKTOP">
        <BinaryVersionRange LowSection="6.0.0.571" HighSection="*" />
      </FilePublisherCondition>
    </Conditions>
  </FilePublisherRule>
  <FilePublisherRule Id="a8b026cb-dc1a-4f29-879b-6d8823048999" Name="ARTICULATE 360 Certificate from O=ARTICULATE GLOBAL, INC., L=NEW YORK, S=NEW YORK, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
    <Conditions>
        <FilePublisherCondition PublisherName="O=ARTICULATE GLOBAL, INC., L=NEW YORK, S=NEW YORK, C=US" ProductName="*" BinaryName="*">
            <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
    </Conditions>
  </FilePublisherRule>
  <FilePublisherRule Id="24e7483c-c382-4fcc-89f9-df72aa6143b3" Name="ARTICULATE 360 Certificate from O=ARTICULATE GLOBAL, INC., L=NEW YORK, S=NEW YORK, C=US" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
    <Conditions>
        <FilePublisherCondition PublisherName="O=ARTICULATE GLOBAL, LLC., L=NEW YORK, S=NEW YORK, C=US" ProductName="*" BinaryName="*">
            <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
    </Conditions>
  </FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
"@
# Path used to save policy XML file
$PolicyXMLFilePath = "$env:tmp\AppLockerPolicy.xml"

# Set new Applocker Policy.
Try {
    # Save policy to XML file to be used by next command
    $PolicyXMLFile = $NewPolicy | Out-file -FilePath $PolicyXMLFilePath -Force -ErrorAction Stop

    # Set the policy using the saved policy file
    Set-AppLockerPolicy -XmlPolicy $PolicyXMLFilePath -ErrorAction Stop

    # Remove the XML file
    Remove-Item -Path $PolicyXMLFilePath -Force -ErrorAction SilentlyContinue

    # Report Success
    Write-host "New Applocker Policy Loaded"
    #Exit 0
}
Catch {
    $ErrorMsg = $_.Exception.Message
    Write-host "Error $ErrorMsg"
    #Exit 1
}