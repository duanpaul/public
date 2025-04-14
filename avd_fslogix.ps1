
param (
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountKey,

    [Parameter(Mandatory = $true)]
    [string]$ShareName
)

<#
# Install FSLogix agent
Write-Host "Installing FSLogix agent..."
$InstallerUri = "https://aka.ms/fslogix_download"
$InstallerPath = "$env:TEMP\fslogix_download.zip"
Invoke-WebRequest -Uri $InstallerUri -OutFile $InstallerPath
Expand-Archive -Path $InstallerPath -DestinationPath "$env:TEMP\FSLogixInstaller"
& "$env:TEMP\FSLogixInstaller\x64\Release\FSLogixAppsSetup.exe" /install /quiet
#>
Set-ExecutionPolicy Bypass -Scope Process -Force

# -------------------------------------------------------------------
#    Example to verify it worked
# -------------------------------------------------------------------
"Hello, World!" | Out-File -FilePath C:\test.txt


# Configure FSLogix profile container
$VHDPath = "\\$StorageAccountName.file.core.windows.net\$ShareName\FSLogixProfile.vhdx"
$RegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"

$VHDPath | Out-File -FilePath C:\test.txt -Append
$StorageAccountKey | Out-File -FilePath C:\test.txt -Append
$RegPath | Out-File -FilePath C:\test.txt -Append

<#
$cmdkey = "cmdkey.exe /add:$StorageAccountName.file.core.windows.net /user:localhost\$StorageAccountName /pass:$StorageAccountKey"
$cmdkey | Out-File -FilePath C:\test.txt -Append
$cmdkey
#>
<#
# Convert the storage account key to a secure string
$secureKey = ConvertTo-SecureString -String $StorageAccountKey -AsPlainText -Force

# Create a PSCredential object from the storage account name and secure key
$credential = New-Object System.Management.Automation.PSCredential("$StorageAccountName", $secureKey)

# Run the cmdkey command to add the storage account credentials to the Windows Credential Manager
$cmdKeyArgs = "/add:$($StorageAccountName + ".file.core.windows.net") /user:AZURE\$StorageAccountName /pass:$($credential.GetNetworkCredential().Password)"
$cmdKeyProcess = Start-Process -FilePath "cmdkey.exe" -ArgumentList $cmdKeyArgs -Wait -PassThru

# Check the exit code of the cmdkey process
if ($cmdKeyProcess.ExitCode -eq 0) {
    "Storage account credentials added successfully." | Out-File -FilePath C:\test.txt -Append
}
else {
    "Failed to add storage account credentials. Exit code: $($cmdKeyProcess.ExitCode)" | Out-File -FilePath C:\test.txt -Append
}
#>

function Write-Log {
    param(
        [parameter(Mandatory)]
        [string]$Message,

        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\Windows\Temp\AVDSessionHostConfig.log'
    if (!(Test-Path -Path $Path)) {
        New-Item -Path 'C:\' -Name 'AVDSessionHostConfig.log' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

# -------------------------------------------------------------------
#    Check and Install FSLogix if NOT already installed
# -------------------------------------------------------------------
try {
  # Try to retrieve the FSLogix service (named "frxsvc")
  $fslogixService = Get-Service -Name "frxsvc" -ErrorAction SilentlyContinue

  if ($fslogixService) {
      Write-Log -Message "FSLogix agent is already installed. Skipping installation." -Type 'INFO'
  }
  else {
      Write-Log -Message "FSLogix agent not found. Proceeding with installation." -Type 'INFO'
      $InstallerUri   = "https://aka.ms/fslogix_download"
      $InstallerPath  = "$env:TEMP\fslogix_download.zip"
      $ExpandPath     = "$env:TEMP\FSLogixInstaller"
      $SetupExe       = "$ExpandPath\x64\Release\FSLogixAppsSetup.exe"

      if (Test-Path $InstallerPath) {
          Remove-Item $InstallerPath -Force
      }
      if (Test-Path $ExpandPath) {
          Remove-Item $ExpandPath -Recurse -Force
      }

      # Download FSLogix
      Invoke-WebRequest -Uri $InstallerUri -OutFile $InstallerPath -UseBasicParsing

      # Expand the archive
      Expand-Archive -Path $InstallerPath -DestinationPath $ExpandPath -Force

      # Run the FSLogix installer silently
      & $SetupExe /install /quiet

      Write-Log -Message "FSLogix agent installation has completed." -Type 'INFO'
  }
}
catch {
  Write-Log -Message "Error while checking or installing FSLogix: $($_.Exception.Message)" -Type 'ERROR'
  throw
}


$FslogixFileShare = "\\$StorageAccountName.file.core.windows.net\$ShareName\"

##############################################################
#  Add Fslogix Settings
##############################################################

$Settings += @(
    # Enables Fslogix profile containers
    [PSCustomObject]@{
        Name         = 'Enabled'
        Path         = 'HKLM:\SOFTWARE\Fslogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # Deletes local profile if it exists and matches the profile being loaded from VHD
    [PSCustomObject]@{
        Name         = 'DeleteLocalProfileWhenVHDShouldApply'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # Use username instead of SID for folder name
    [PSCustomObject]@{
        Name         = 'FlipFlopProfileDirectoryName'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # VHD Locations
    [PSCustomObject]@{
        Name         = 'VHDLocations'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'MultiString'
        Value        = $FslogixFileShare
    },
    [PSCustomObject]@{
        Name         = 'VolumeType'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'MultiString'
        Value        = 'vhdx'
    },
    # Kerberos ticket retrieval settings
    [PSCustomObject]@{
        Name         = 'CloudKerberosTicketRetrievalEnabled'
        Path         = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters'
        PropertyType = 'DWord'
        Value        = 1
    },
    [PSCustomObject]@{
        Name         = 'CloudKerberosTicketRetrievalEnabled'
        Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters'
        PropertyType = 'DWord'
        Value        = 1
    }
)

# Set registry settings
foreach ($Setting in $Settings) {
    if (!(Test-Path -Path $Setting.Path)) {
        New-Item -Path $Setting.Path -Force
    }

    $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
    $LogOutputValue = 'Path: ' + $Setting.Path + ', Name: ' + $Setting.Name + ', PropertyType: ' + $Setting.PropertyType + ', Value: ' + $Setting.Value

    if (!$Value) {
        New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force
        Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
    }
    elseif ($Value.$($Setting.Name) -ne $Setting.Value) {
        Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force
        Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
    }
    else {
        Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
    }
    Start-Sleep -Seconds 1
}

# Reboot the machine
Write-Log -Message "Configuration complete. Rebooting system." -Type 'INFO'
Restart-Computer -Force
