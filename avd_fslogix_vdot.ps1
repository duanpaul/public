
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

##############################################################
#  Install and Configure VDOT
##############################################################

# Set Variables
$ErrorActionPreference = 'Stop'
$Directory = 'optimize'
$Drive = 'C:\'
$WorkingDirectory = $Drive + '\' + $Directory
$Url = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
$Zip = 'VDOT.zip'
$OutputPath = $WorkingDirectory + '\' + $Zip

try {
    Write-Log -Message 'Starting Virtual Desktop Optimization Tool (VDOT) installation' -Type 'INFO'

    # Create directory for VDOT
    if (!(Test-Path -Path $WorkingDirectory)) {
        New-Item -Path $Drive -Name $Directory -ItemType 'Directory'
        Write-Log -Message "Created directory: $WorkingDirectory" -Type 'INFO'
    }
    
    Set-Location $WorkingDirectory

    # Download VDOT
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
    Write-Log -Message "Downloaded VDOT to $OutputPath" -Type 'INFO'

    # Extract VDOT
    Expand-Archive -LiteralPath $OutputPath -DestinationPath $WorkingDirectory -Force
    Write-Log -Message 'Extracted VDOT archive' -Type 'INFO'

    # Set execution policy and location
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
    Set-Location -Path "$WorkingDirectory\Virtual-Desktop-Optimization-Tool-main"

    # Run VDOT with basic parameters
    Write-Log -Message 'Starting VDOT optimization process' -Type 'INFO'
    & .\Windows_VDOT.ps1 -Verbose -AcceptEula
    Write-Log -Message 'Completed VDOT optimization process' -Type 'INFO'

} catch {
    Write-Log -Message "Error during VDOT installation: $($_.Exception.Message)" -Type 'ERROR'
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
