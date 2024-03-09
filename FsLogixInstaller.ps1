<#
.SYNOPSIS
Install FSLogix agent, configure profile container, and create a scheduled task to automatically detach the profile container.

.PARAMETER StorageAccountName
Name of the storage account where the FSLogix profile container will be stored.

.PARAMETER StorageAccountKey
Access key for the storage account.

.PARAMETER ShareName
Name of the file share where the FSLogix profile container will be stored.

#>

param (
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$StorageAccountKey,

    [Parameter(Mandatory=$true)]
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

Write-Host "Configuring FSLogix profile container..."
New-Item -Path $RegPath -Force
New-ItemProperty -Path $RegPath -Name "Enabled" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegPath -Name "VHDLocations" -Value $VHDPath -PropertyType MultiString -Force
New-ItemProperty -Path $RegPath -Name "FlipFlopProfileDirectoryName" -Value "FSLogixProfile" -PropertyType String -Force
New-ItemProperty -Path $RegPath -Name "SizeInMBs" -Value 30720 -PropertyType DWORD -Force
New-ItemProperty -Path $RegPath -Name "IsDynamic" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegPath -Name "ConcurrentUserSessions" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $RegPath -Name "AccountKeys" -Value $StorageAccountKey -PropertyType String -Force

# Create a scheduled task to detach the profile container
$TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"& {Get-Process -Name 'explorer' | ForEach-Object {Stop-Process -Force -Id `$_.Id}}`""
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet
$TaskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Task = New-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Principal $TaskPrincipal
Register-ScheduledTask -TaskName "DetachFSLogixProfile" -InputObject $Task -Force

Write-Host "FSLogix configuration completed successfully."