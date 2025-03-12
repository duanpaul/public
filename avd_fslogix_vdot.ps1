
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

    # Create ConfigurationFiles directory if it doesn't exist
    $configPath = "$WorkingDirectory\Virtual-Desktop-Optimization-Tool-main\ConfigurationFiles"
    if (!(Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force
        Write-Log -Message "Created directory: $configPath" -Type 'INFO'
    }

    # Create AppxPackages.json with the specified content
    $appxJson = @'
[
  {
    "AppxPackage": "Bing Search",
    "VDIState": "Unchanged",
    "URL": "https://apps.microsoft.com/detail/9nzbf4gt040c",
    "Description": "Web Search from Microsoft Bing provides web results and answers in Windows Search"
  },
  {
    "AppxPackage": "Clipchamp.Clipchamp",
    "VDIState": "Disabled",
    "URL": "https://apps.microsoft.com/detail/9p1j8s7ccwwt?hl=en-us&gl=US",
    "Description": "Create videos with a few clicks"
  },
  {
    "AppxPackage": "Microsoft.549981C3F5F10",
    "VDIState": "Disabled",
    "URL": "https://apps.microsoft.com/detail/cortana/9NFFX4SZZ23L?hl=en-us&gl=US",
    "Description": "Cortana (could not update)"
  },
  {
    "AppxPackage": "Microsoft.BingNews",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-news/9wzdncrfhvfw",
    "Description": "Microsoft News app"
  },
  {
    "AppxPackage": "Microsoft.BingWeather",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/msn-weather/9wzdncrfj3q2",
    "Description": "MSN Weather app"
  },
  {
    "AppxPackage": "Microsoft.DesktopAppInstaller",
    "VDIState": "Disabled",
    "URL": "https://apps.microsoft.com/detail/9NBLGGH4NNS1",
    "Description": "Microsoft App Installer for Windows 10 makes sideloading Windows apps easy"
  },
  {
    "AppxPackage": "Microsoft.GamingApp",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/xbox/9mv0b5hzvk9z",
    "Description": "Xbox app"
  },
  {
    "AppxPackage": "Microsoft.GetHelp",
    "VDIState": "Disabled",
    "URL": "https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/customize-get-help-app",
    "Description": "App that facilitates free support for Microsoft products"
  },
  {
    "AppxPackage": "Microsoft.Getstarted",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-tips/9wzdncrdtbjj",
    "Description": "Windows 10 tips app"
  },
  {
    "AppxPackage": "Microsoft.MicrosoftOfficeHub",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/office/9wzdncrd29v9",
    "Description": "Office UWP app suite"
  },
  {
    "AppxPackage": "Microsoft.Office.OneNote",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/onenote-for-windows-10/9wzdncrfhvjl",
    "Description": "Office UWP OneNote app"
  },
  {
    "AppxPackage": "Microsoft.MicrosoftSolitaireCollection",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-solitaire-collection/9wzdncrfhwd2",
    "Description": "Solitaire suite of games"
  },
  {
    "AppxPackage": "Microsoft.MicrosoftStickyNotes",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-sticky-notes/9nblggh4qghw",
    "Description": "Note-taking app"
  },
  {
    "AppxPackage": "Microsoft.OutlookForWindows",
    "VDIState": "Unchanged",
    "URL": "https://apps.microsoft.com/detail/9NRX63209R7B?hl=en-us&gl=US",
    "Description": "a best-in-class email experience that is free for anyone with Windows"
  },
  {
    "AppxPackage": "Microsoft.MSPaint",
    "VDIState": "Unchanged",
    "URL": "https://apps.microsoft.com/store/detail/paint-3d/9NBLGGH5FV99",
    "Description": "Paint 3D app (not Classic Paint app)"
  },
  {
    "AppxPackage": "Microsoft.Paint",
    "VDIState": "Unchanged",
    "URL": "https://apps.microsoft.com/detail/9PCFS5B6T72H?hl=en-us&gl=US",
    "Description": "Classic Paint app"
  },
  {
    "AppxPackage": "Microsoft.People",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-people/9nblggh10pg8",
    "Description": "Contact management app"
  },
  {
    "AppxPackage": "Microsoft.PowerAutomateDesktop",
    "VDIState": "Disabled",
    "URL": "https://flow.microsoft.com/en-us/desktop/",
    "Description": "Power Automate Desktop app. Record desktop and web actions in a single flow"
  },
  {
    "AppxPackage": "Microsoft.ScreenSketch",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/snip-sketch/9mz95kl8mr0l",
    "Description": "Snip and Sketch app"
  },
  {
    "AppxPackage": "Microsoft.SkypeApp",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/skype/9wzdncrfj364",
    "Description": "Instant message, voice or video call app"
  },
  {
    "AppxPackage": "Microsoft.StorePurchaseApp",
    "VDIState": "Disabled",
    "URL": "",
    "Description": "Store purchase app helper"
  },
  {
    "AppxPackage": "Microsoft.Todos",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-to-do-lists-tasks-reminders/9nblggh5r558",
    "Description": "Microsoft To Do makes it easy to plan your day and manage your life"
  },
  {
    "AppxPackage": "Microsoft.WinDbg.Fast",
    "VDIState": "Disabled",
    "URL": "https://apps.microsoft.com/detail/9PGJGD53TN86?hl=en-us&gl=US",
    "Description": "Microsoft WinDbg"
  },
  {
    "AppxPackage": "Microsoft.Windows.DevHome",
    "VDIState": "Disabled",
    "URL": "https://learn.microsoft.com/en-us/windows/dev-home/",
    "Description": "A control center providing the ability to monitor projects in your dashboard using customizable widgets and more"
  },
  {
    "AppxPackage": "Microsoft.Windows.Photos",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/microsoft-photos/9wzdncrfjbh4",
    "Description": "Photo and video editor"
  },
  {
    "AppxPackage": "Microsoft.WindowsAlarms",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/windows-alarms-clock/9wzdncrfj3pr",
    "Description": "A combination app, of alarm clock, world clock, timer, and stopwatch."
  },
  {
    "AppxPackage": "Microsoft.WindowsCalculator",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/windows-calculator/9wzdncrfhvn5",
    "Description": "Microsoft Calculator app"
  },
  {
    "AppxPackage": "Microsoft.WindowsCamera",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/windows-camera/9wzdncrfjbbg",
    "Description": "Camera app to manage photos and video"
  },
  {
    "AppxPackage": "microsoft.windowscommunicationsapps",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/mail-and-calendar/9wzdncrfhvqm",
    "Description": "Mail & Calendar apps"
  },
  {
    "AppxPackage": "Microsoft.WindowsFeedbackHub",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/feedback-hub/9nblggh4r32n",
    "Description": "App to provide Feedback on Windows and apps to Microsoft"
  },
  {
    "AppxPackage": "Microsoft.WindowsMaps",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/windows-maps/9wzdncrdtbvb",
    "Description": "Microsoft Maps app"
  },
  {
    "AppxPackage": "Microsoft.WindowsNotepad",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/windows-notepad/9msmlrh6lzf3",
    "Description": "Fast, simple text editor for plain text documents and source code files."
  },
  {
    "AppxPackage": "Microsoft.WindowsStore",
    "VDIState": "Disabled",
    "URL": "https://blogs.windows.com/windowsexperience/2021/06/24/building-a-new-open-microsoft-store-on-windows-11/",
    "Description": "Windows Store app"
  },
  {
    "AppxPackage": "Microsoft.WindowsSoundRecorder",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/windows-voice-recorder/9wzdncrfhwkn",
    "Description": "(Voice recorder)"
  },
  {
    "AppxPackage": "Microsoft.WindowsTerminal",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701",
    "Description": "A terminal app featuring tabs, panes, Unicode, UTF-8 character support, and GPU text rendering engine."
  },
  {
    "AppxPackage": "Microsoft.Winget.Platform.Source",
    "VDIState": "Unchanged",
    "URL": "https://learn.microsoft.com/en-us/windows/package-manager/winget/",
    "Description": "The Winget tool enables users to manage applications on Win10 and Win11 devices. This tool is the client interface to the Windows Package Manager service"
  },
  {
    "AppxPackage": "Microsoft.Xbox.TCUI",
    "VDIState": "Disabled",
    "URL": "https://docs.microsoft.com/en-us/gaming/xbox-live/features/general/tcui/live-tcui-overview",
    "Description": "XBox Title Callable UI (TCUI) enables your game code to call pre-defined user interface displays"
  },
  {
    "AppxPackage": "Microsoft.XboxGameOverlay",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p",
    "Description": "Xbox Game Bar extensible overlay"
  },
  {
    "AppxPackage": "Microsoft.XboxGamingOverlay",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p",
    "Description": "Xbox Game Bar extensible overlay"
  },
  {
    "AppxPackage": "Microsoft.XboxIdentityProvider",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/xbox-identity-provider/9wzdncrd1hkw",
    "Description": "A system app that enables PC games to connect to Xbox Live."
  },
  {
    "AppxPackage": "Microsoft.XboxSpeechToTextOverlay",
    "VDIState": "Disabled",
    "URL": "https://support.xbox.com/help/account-profile/accessibility/use-game-chat-transcription",
    "Description": "Xbox game transcription overlay"
  },
  {
    "AppxPackage": "Microsoft.YourPhone",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/Your-phone/9nmpj99vjbwv",
    "Description": "Android phone to PC device interface app"
  },
  {
    "AppxPackage": "Microsoft.ZuneMusic",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/groove-music/9wzdncrfj3pt",
    "Description": "Groove Music app"
  },
  {
    "AppxPackage": "Microsoft.ZuneVideo",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/movies-tv/9wzdncrfj3p2",
    "Description": "Movies and TV app"
  },
  {
    "AppxPackage": "MicrosoftCorporationII.QuickAssist",
    "VDIState": "Unchanged",
    "URL": "https://apps.microsoft.com/detail/9P7BP5VNWKX5?hl=en-us&gl=US",
    "Description": "Microsoft remote help app"
  },
  {
    "AppxPackage": "MicrosoftWindows.Client.WebExperience",
    "VDIState": "Unchanged",
    "URL": "",
    "Description": "Windows 11 Internet information widget"
  },
  {
    "AppxPackage": "Microsoft.XboxApp",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/store/apps/9wzdncrfjbd8",
    "Description": "Xbox 'Console Companion' app (games, friends, etc.)"
  },
  {
    "AppxPackage": "Microsoft.MixedReality.Portal",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/p/mixed-reality-portal/9ng1h8b3zc7m",
    "Description": "The app that facilitates Windows Mixed Reality setup, and serves as the command center for mixed reality experiences"
  },
  {
    "AppxPackage": "Microsoft.Microsoft3DViewer",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/p/3d-viewer/9nblggh42ths",
    "Description": "App to view common 3D file types"
  },
  {
    "AppxPackage": "MicrosoftTeams",
    "VDIState": "Unchanged",
    "URL": "https://www.microsoft.com/en-us/microsoft-teams/group-chat-software",
    "Description": "Microsoft communication platform"
  },
  {
    "AppxPackage": "Microsoft.OneDriveSync",
    "VDIState": "Unchanged",
    "URL": "https://docs.microsoft.com/en-us/onedrive/one-drive-sync",
    "Description": "Microsoft OneDrive sync app (included in Office 2016 or later)"
  },
  {
    "AppxPackage": "Microsoft.Wallet",
    "VDIState": "Disabled",
    "URL": "https://www.microsoft.com/en-us/payments",
    "Description": "(Microsoft Pay) for Edge browser on certain devices"
  }
]
'@

    $appxJsonPath = "$configPath\AppxPackages.json"
    $appxJson | Out-File -FilePath $appxJsonPath -Force -Encoding UTF8
    Write-Log -Message "Created AppxPackages.json at $appxJsonPath" -Type 'INFO'

    # Run VDOT first time with basic parameters
    Write-Log -Message 'Starting initial VDOT optimization process' -Type 'INFO'
    $vdotOutput = & .\Windows_VDOT.ps1 -Verbose -AcceptEula 2>&1 | Out-String
    Write-Log -Message "VDOT Output: $vdotOutput" -Type 'INFO'

    # Run VDOT second time with AppxPackages optimization
    Write-Log -Message 'Starting VDOT AppxPackages optimization' -Type 'INFO'
    $vdotOutput = & .\Windows_VDOT.ps1 -Optimizations AppxPackages -AcceptEula -Verbose 2>&1 | Out-String
    Write-Log -Message "VDOT AppxPackages Output: $vdotOutput" -Type 'INFO'

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
