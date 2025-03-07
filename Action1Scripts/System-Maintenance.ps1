# System Maintenance Script for Action1
# Purpose: Performs essential system maintenance tasks
# Author: Nigel Hagen
# Last Modified: March 7, 2025

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
$LogFile = "C:\ProgramData\Action1\Logs\maintenance_$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Critical")]
        [string]$Severity = "Info"
    )
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): [$Severity] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
    
    # Send notification for Warning and Critical messages
    if ($Severity -ne "Info") {
        Send-Notification -Message $Message -Severity $Severity -Title "System Maintenance Alert"
    }
}

# Create log directory if it doesn't exist
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile -Parent)

Write-Log "Starting system maintenance..." -Severity "Info"

# 1. Disk Cleanup
Write-Log "Running Disk Cleanup..." -Severity "Info"
try {
    Start-Process -Wait cleanmgr.exe -ArgumentList '/sagerun:1' -NoNewWindow
    Write-Log "Disk Cleanup completed successfully" -Severity "Info"
} catch {
    Write-Log "Error during Disk Cleanup: $_" -Severity "Warning"
}

# 2. Check and Repair System Files
Write-Log "Checking system files..." -Severity "Info"
try {
    $sfc = Start-Process -Wait sfc.exe -ArgumentList '/scannow' -NoNewWindow -PassThru
    if ($sfc.ExitCode -eq 0) {
        Write-Log "System file check completed successfully" -Severity "Info"
    } else {
        Write-Log "System file check encountered issues. Exit code: $($sfc.ExitCode)" -Severity "Critical"
    }
} catch {
    Write-Log "Error during system file check: $_" -Severity "Critical"
}

# 3. Windows Update Cleanup
Write-Log "Cleaning Windows Update cache..." -Severity "Info"
try {
    Stop-Service -Name wuauserv -Force
    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv
    Write-Log "Windows Update cache cleaned successfully" -Severity "Info"
} catch {
    Write-Log "Error during Windows Update cleanup: $_" -Severity "Warning"
}

# 4. Clear Temporary Files
Write-Log "Cleaning temporary files..." -Severity "Info"
$TempFolders = @(
    "C:\Windows\Temp\*"
    "$env:TEMP\*"
)
foreach ($folder in $TempFolders) {
    try {
        Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned temporary files in: ${folder}" -Severity "Info"
    } catch {
        Write-Log "Error cleaning temporary files in ${folder}: $_" -Severity "Warning"
    }
}

# 5. Check Disk Health
Write-Log "Checking disk health..." -Severity "Info"
Get-Volume | Where-Object {$_.DriveLetter -ne $null} | ForEach-Object {
    try {
        $chkdsk = Start-Process -Wait chkdsk.exe -ArgumentList "$($_.DriveLetter):" -NoNewWindow -PassThru
        if ($chkdsk.ExitCode -eq 0) {
            Write-Log "Disk check completed successfully for drive $($_.DriveLetter):" -Severity "Info"
        } else {
            Write-Log "Disk check found issues on drive $($_.DriveLetter): (Exit code: $($chkdsk.ExitCode))" -Severity "Critical"
        }
    } catch {
        Write-Log "Error checking drive $($_.DriveLetter): $_" -Severity "Critical"
    }
}

# 6. System Performance Report
Write-Log "Generating system performance report..." -Severity "Info"
try {
    $perfReport = Get-WmiObject Win32_OperatingSystem | Select-Object @{
        Name = "Memory Usage (%)";
        Expression = {[math]::Round((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100, 2)}
    }
    
    # Check memory usage
    if ($perfReport.'Memory Usage (%)' -gt 90) {
        Write-Log "CRITICAL: High memory usage: $($perfReport.'Memory Usage (%)')%" -Severity "Critical"
    } elseif ($perfReport.'Memory Usage (%)' -gt 80) {
        Write-Log "WARNING: Elevated memory usage: $($perfReport.'Memory Usage (%)')%" -Severity "Warning"
    } else {
        Write-Log "Current Memory Usage: $($perfReport.'Memory Usage (%)')%" -Severity "Info"
    }

    $diskSpace = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | 
        Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
    
    foreach ($disk in $diskSpace) {
        $freeSpacePercent = ($disk.'FreeSpace(GB)' / $disk.'Size(GB)') * 100
        if ($freeSpacePercent -lt 10) {
            Write-Log "CRITICAL: Very low disk space on $($disk.DeviceID) - Only $([math]::Round($freeSpacePercent,2))% free" -Severity "Critical"
        } elseif ($freeSpacePercent -lt 20) {
            Write-Log "WARNING: Low disk space on $($disk.DeviceID) - Only $([math]::Round($freeSpacePercent,2))% free" -Severity "Warning"
        } else {
            Write-Log "Drive $($disk.DeviceID) - Total: $($disk.'Size(GB)')GB, Free: $($disk.'FreeSpace(GB)')GB" -Severity "Info"
        }
    }
} catch {
    Write-Log "Error generating performance report: $_" -Severity "Critical"
}

Write-Log "System maintenance completed!" -Severity "Info" 