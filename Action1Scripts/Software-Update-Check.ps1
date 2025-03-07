# Software Update Checker Script for Action1
# Purpose: Checks for Windows Updates and common software updates
# Author: Your Name
# Last Modified: 2024

#region Email Configuration
# ================================
# Edit these settings for email notifications
$EmailSettings = @{
    UseEmail              = $false                  # Set to $true to enable email notifications
    SMTPServer           = "smtp.gmail.com"        # Your SMTP server
    Port                 = 587                     # SMTP port
    UseSsl              = $true                   # Use SSL for SMTP
    Username            = "your@gmail.com"        # Your email address
    Password            = "your-app-password"     # Your email password or app-specific password
    ToEmail             = "alerts@domain.com"     # Where to send alerts
    FromEmail           = "your@gmail.com"        # Sender email address
}

# Alert Settings
$AlertSettings = @{
    UseWindowsNotification = $true                # Enable/disable Windows notifications
    AlertLevel            = "Warning"             # Minimum alert level: "Info", "Warning", "Critical"
    BatchNotifications    = $true                 # Combine multiple alerts
    BatchWindow          = 300                    # Seconds to wait before sending batched notifications
    RepeatDelay          = 3600                  # Seconds to wait before sending duplicate alerts
}
#endregion

# Import notification module
. "$PSScriptRoot\Notification-Module.ps1"

# Initialize notifications with custom settings
Initialize-NotificationSystem `
    -EmailUsername $EmailSettings.Username `
    -EmailPassword $EmailSettings.Password `
    -ToEmail $EmailSettings.ToEmail `
    -UseEmail $EmailSettings.UseEmail `
    -UseWindowsNotification $AlertSettings.UseWindowsNotification `
    -AlertLevel $AlertSettings.AlertLevel `
    -BatchNotifications $AlertSettings.BatchNotifications `
    -BatchWindow $AlertSettings.BatchWindow `
    -RepeatDelay $AlertSettings.RepeatDelay

# Error handling
$ErrorActionPreference = "Continue"
$LogFile = "C:\ProgramData\Action1\Logs\updates_$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Create log directory if it doesn't exist
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile -Parent)

Write-Log "Starting software update check..."

# 1. Check Windows Update Status
Write-Log "Checking Windows Updates..."
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
    
    if ($SearchResult.Updates.Count -gt 0) {
        Write-Log "Found $($SearchResult.Updates.Count) pending Windows updates:"
        foreach ($Update in $SearchResult.Updates) {
            Write-Log "- $($Update.Title)"
        }
    } else {
        Write-Log "No pending Windows updates found."
    }
} catch {
    Write-Log "Error checking Windows Updates: $_"
}

# 2. Check Common Software Versions
Write-Log "Checking installed software versions..."

# Function to get software version
function Get-SoftwareVersion {
    param (
        [string]$RegPath,
        [string]$DisplayName
    )
    
    $software = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -like "*$DisplayName*" } |
        Select-Object DisplayName, DisplayVersion
    
    if ($software) {
        return "$($software.DisplayName) - Version: $($software.DisplayVersion)"
    }
    return $null
}

$RegPaths = @(
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$CommonSoftware = @(
    "Google Chrome",
    "Mozilla Firefox",
    "Adobe Acrobat",
    "Adobe Reader",
    "7-Zip",
    "VLC",
    "Microsoft Office"
)

foreach ($Software in $CommonSoftware) {
    Write-Log "Checking $Software..."
    $found = $false
    
    foreach ($RegPath in $RegPaths) {
        $version = Get-SoftwareVersion -RegPath $RegPath -DisplayName $Software
        if ($version) {
            Write-Log $version
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Log "$Software not found"
    }
}

# 3. Check Windows Defender Status
Write-Log "Checking Windows Defender status..."
try {
    $DefenderStatus = Get-MpComputerStatus
    Write-Log "Antivirus Enabled: $($DefenderStatus.AntivirusEnabled)"
    Write-Log "Real-time Protection Enabled: $($DefenderStatus.RealTimeProtectionEnabled)"
    Write-Log "Antivirus Signature Last Updated: $($DefenderStatus.AntivirusSignatureLastUpdated)"
} catch {
    Write-Log "Error checking Windows Defender status: $_"
}

# 4. Check Disk Space Requirements for Updates
Write-Log "Checking available disk space for updates..."
try {
    $SystemDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $FreeSpaceGB = [math]::Round($SystemDrive.FreeSpace / 1GB, 2)
    Write-Log "Available space on system drive: $FreeSpaceGB GB"
    
    if ($FreeSpaceGB -lt 10) {
        Write-Log "WARNING: Low disk space might affect update installation"
    }
} catch {
    Write-Log "Error checking disk space: $_"
}

Write-Log "Software update check completed!" 