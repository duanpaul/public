#write code to add fslogix settings to the registry 
$registryPath = "HKLM:\SOFTWARE\FSLogix"
$registryName = "SettingName"
$registryValue = "SettingValue"

# Check if the registry path exists, create it if it doesn't
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# Set the registry value
Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue

# Search for events related to AVD agent issues
$eventLog = Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = 'AVD Agent'
}

# Display the events
$eventLog | Format-Table -AutoSize
# Write code to update the registry key for OneDrive login
$registryPath = "HKCU:\Software\Microsoft\OneDrive"
$registryName = "SilentAccountConfig"
$registryValue = 1

# Check if the registry path exists, create it if it doesn't
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# Set the registry value
Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue

# Search for events related to AVD agent issues
$eventLog = Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = 'AVD Agent'
}

# Display the events
$eventLog | Format-Table -AutoSize
