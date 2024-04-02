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


# powershell to join a computer to a domain with provided credentials and OU
Add-Computer -DomainName "contoso.com" -Credential (Get-Credential) -OUPath "OU=Computers,OU=MyBusiness,DC=contoso,DC=com" -Restart
Add-Computer -DomainName "contoso.com" -Credential (Get-Credential) -Restart

# powershell to create a new ou
New-ADOrganizationalUnit -Name "MyBusiness" -Path "DC=contoso,DC=com"

# powershell to search windows application logs from source hyperspaceweb with event id 0 and include "epic.core.wrongwebserverexception" on a list of remote servers
$computers = @("server1", "server2", "server3")
foreach ($computer in $computers) {
    $events = Get-WinEvent -ComputerName $computer -LogName Application -FilterXPath "*[System[Provider[@Name='HyperspaceWeb'] and (EventID=0)] and EventData[Data='epic.core.wrongwebserverexception']]"
    $events | Format-Table -AutoSize
}
Get-WinEvent -LogName Application -FilterXPath "*[System[Provider[@Name='HyperspaceWeb'] and (EventID=0)] and EventData[Data='epic.core.wrongwebserverexception']]"