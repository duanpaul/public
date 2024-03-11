

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

Set-ExecutionPolicy Bypass -Scope Process -Force
"Hello, World!" | Out-File -FilePath C:\test.txt

$VHDPath | Out-File -FilePath C:\test.txt -Append
$StorageAccountKey | Out-File -FilePath C:\test.txt -Append
$RegPath | Out-File -FilePath C:\test.txt -Append