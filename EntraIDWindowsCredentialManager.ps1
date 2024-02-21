cmdkey.exe /add:storageavdqwsac01.file.core.windows.net /user:localhost\storageavdqwsac01 /pass:SfVat5XFOnVxejepSNGrdN4NOmVFqU/YBOh2F1bQbBJ8dcP91yzqHNla6Cx/Q4BuIgEVNVg4p/tD+AStaIjdBA==


# Add a test registry key to prove the script is running
$registryPath = "HKLM:\SOFTWARE\TestRegistryKey"
$name = "TestValueName"
$value = "TestValueData"

# Check if the registry path exists; if not, create it
If (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# Set the value in the registry
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

Write-Host "Registry key and value have been added."


Restart-Computer -Force