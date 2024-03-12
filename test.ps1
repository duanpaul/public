

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

# Configure FSLogix profile container
$VHDPath = "\\$StorageAccountName.file.core.windows.net\$ShareName\FSLogixProfile.vhdx"
$RegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"

Set-ExecutionPolicy Bypass -Scope Process -Force
"Hello, World!" | Out-File -FilePath C:\test.txt

$VHDPath | Out-File -FilePath C:\test.txt -Append
$StorageAccountKey | Out-File -FilePath C:\test.txt -Append
$RegPath | Out-File -FilePath C:\test.txt -Append

$cmdkey = "cmdkey.exe /add:$StorageAccountName.file.core.windows.net /user:localhost\$StorageAccountName /pass:$StorageAccountKey"
$cmdkey | Out-File -FilePath C:\test.txt -Append


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
    Write-Error "Failed to add storage account credentials. Exit code: $($cmdKeyProcess.ExitCode)" | Out-File -FilePath C:\test.txt -Append
}

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


$FslogixFileShare = "\\$StorageAccountName.file.core.windows.net\$ShareName\"

##############################################################
#  Add Fslogix Settings
##############################################################

$Settings += @(
    # Enables Fslogix profile containers: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#enabled
    [PSCustomObject]@{
        Name         = 'Enabled'
        Path         = 'HKLM:\SOFTWARE\Fslogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
    [PSCustomObject]@{
        Name         = 'DeleteLocalProfileWhenVHDShouldApply'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
    [PSCustomObject]@{
        Name         = 'FlipFlopProfileDirectoryName'
        Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
        PropertyType = 'DWord'
        Value        = 1
    },
    # # Loads FRXShell if there's a failure attaching to, or using an existing profile VHD(X): https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithfailure
    # [PSCustomObject]@{
    #         Name         = 'PreventLoginWithFailure'
    #         Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
    #         PropertyType = 'DWord'
    #         Value        = 1
    # },
    # # Loads FRXShell if it's determined a temp profile has been created: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#preventloginwithtempprofile
    # [PSCustomObject]@{
    #         Name         = 'PreventLoginWithTempProfile'
    #         Path         = 'HKLM:\SOFTWARE\FSLogix\Profiles'
    #         PropertyType = 'DWord'
    #         Value        = 1
    # },
    # List of file system locations to search for the user's profile VHD(X) file: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#vhdlocations
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
    }
)

# Set registry settings
foreach ($Setting in $Settings) {
    # Create registry key(s) if necessary
    if (!(Test-Path -Path $Setting.Path)) {
        New-Item -Path $Setting.Path -Force
    }

    # Checks for existing registry setting
    $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
    $LogOutputValue = 'Path: ' + $Setting.Path + ', Name: ' + $Setting.Name + ', PropertyType: ' + $Setting.PropertyType + ', Value: ' + $Setting.Value

    # Creates the registry setting when it does not exist
    if (!$Value) {
        New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force
        Write-Log -Message "Added registry setting: $LogOutputValue" -Type 'INFO'
    }
    # Updates the registry setting when it already exists
    elseif ($Value.$($Setting.Name) -ne $Setting.Value) {
        Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force
        Write-Log -Message "Updated registry setting: $LogOutputValue" -Type 'INFO'
    }
    # Writes log output when registry setting has the correct value
    else {
        Write-Log -Message "Registry setting exists with correct value: $LogOutputValue" -Type 'INFO'    
    }
    Start-Sleep -Seconds 1
}