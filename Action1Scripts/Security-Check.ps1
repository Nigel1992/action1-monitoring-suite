# Security Check Script for Action1
# Purpose: Performs security checks and monitoring
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
$LogFile = "C:\ProgramData\Action1\Logs\security_$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Create log directory if it doesn't exist
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile -Parent)

Write-Log "Starting security check..."

# 1. Check Windows Defender Status
Write-Log "Checking Windows Defender status..."
try {
    $DefenderStatus = Get-MpComputerStatus
    $DefenderPreference = Get-MpPreference
    
    Write-Log "Windows Defender Status:"
    Write-Log "- Real-time Protection: $($DefenderStatus.RealTimeProtectionEnabled)"
    Write-Log "- Antivirus Enabled: $($DefenderStatus.AntivirusEnabled)"
    Write-Log "- Behavior Monitor Enabled: $($DefenderStatus.BehaviorMonitorEnabled)"
    Write-Log "- Cloud Protection Level: $($DefenderPreference.MAPSReporting)"
    Write-Log "- Last Scan Time: $($DefenderStatus.LastFullScanTime)"
    Write-Log "- Signatures Last Updated: $($DefenderStatus.AntivirusSignatureLastUpdated)"
} catch {
    Write-Log "Error checking Windows Defender: $_"
}

# 2. Check Firewall Status
Write-Log "Checking Windows Firewall status..."
try {
    $FirewallProfiles = Get-NetFirewallProfile
    foreach ($Profile in $FirewallProfiles) {
        Write-Log "Firewall Profile '$($Profile.Name)':"
        Write-Log "- Enabled: $($Profile.Enabled)"
        Write-Log "- Default Inbound Action: $($Profile.DefaultInboundAction)"
        Write-Log "- Default Outbound Action: $($Profile.DefaultOutboundAction)"
    }
} catch {
    Write-Log "Error checking Firewall: $_"
}

# 3. Check for Unauthorized User Accounts
Write-Log "Checking user accounts..."
try {
    $LocalUsers = Get-LocalUser | Where-Object {$_.Enabled -eq $true}
    Write-Log "Enabled local user accounts:"
    foreach ($User in $LocalUsers) {
        Write-Log "- $($User.Name) (Last logon: $($User.LastLogon))"
    }
    
    $AdminUsers = Get-LocalGroupMember -Group "Administrators"
    Write-Log "Users in Administrators group:"
    foreach ($Admin in $AdminUsers) {
        Write-Log "- $($Admin.Name)"
    }
} catch {
    Write-Log "Error checking user accounts: $_"
}

# 4. Check Running Services
Write-Log "Checking running services..."
try {
    $Services = Get-Service | Where-Object {$_.Status -eq 'Running'}
    Write-Log "Number of running services: $($Services.Count)"
    
    # Check for critical services
    $CriticalServices = @(
        "WinDefend",
        "MpsSvc",
        "SecurityHealthService",
        "Winmgmt",
        "EventLog"
    )
    
    foreach ($ServiceName in $CriticalServices) {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            Write-Log "Critical Service '$ServiceName' status: $($Service.Status)"
        } else {
            Write-Log "WARNING: Critical service '$ServiceName' not found!"
        }
    }
} catch {
    Write-Log "Error checking services: $_"
}

# 5. Check Event Logs for Security Issues
Write-Log "Checking security event logs..."
try {
    $StartTime = (Get-Date).AddDays(-1)
    $SecurityEvents = Get-WinEvent -FilterHashtable @{
        LogName='Security'
        StartTime=$StartTime
        ID=@(4624,4625,4648,4719,4720,4722,4723,4725,4728,4732,4756,4738)
    } -ErrorAction SilentlyContinue
    
    Write-Log "Security events in the last 24 hours:"
    Write-Log "- Failed login attempts: $($SecurityEvents | Where-Object {$_.Id -eq 4625} | Measure-Object | Select-Object -ExpandProperty Count)"
    Write-Log "- Account modifications: $($SecurityEvents | Where-Object {$_.Id -in @(4720,4722,4723,4725)} | Measure-Object | Select-Object -ExpandProperty Count)"
    Write-Log "- Group modifications: $($SecurityEvents | Where-Object {$_.Id -in @(4728,4732,4756)} | Measure-Object | Select-Object -ExpandProperty Count)"
} catch {
    Write-Log "Error checking security events: $_"
}

# 6. Check Network Connections
Write-Log "Checking network connections..."
try {
    $Connections = Get-NetTCPConnection -State Established
    Write-Log "Active network connections: $($Connections.Count)"
    
    $SuspiciousConnections = $Connections | Where-Object {
        $_.RemotePort -in @(22,23,3389,5900) -or
        $_.State -eq 'Listen'
    }
    
    if ($SuspiciousConnections) {
        Write-Log "Potentially suspicious connections found:"
        foreach ($Conn in $SuspiciousConnections) {
            Write-Log "- Local:$($Conn.LocalAddress):$($Conn.LocalPort) -> Remote:$($Conn.RemoteAddress):$($Conn.RemotePort) ($($Conn.State))"
        }
    }
} catch {
    Write-Log "Error checking network connections: $_"
}

# 7. Check System Integrity
Write-Log "Checking system integrity..."
try {
    # Check boot configuration
    $BCDEdit = bcdedit /enum | Out-String
    if ($BCDEdit -match "nointegritychecks") {
        Write-Log "WARNING: System integrity checks might be disabled!"
    }
    
    # Check UAC settings
    $UACLevel = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
    Write-Log "UAC Level: $($UACLevel.ConsentPromptBehaviorAdmin)"
} catch {
    Write-Log "Error checking system integrity: $_"
}

Write-Log "Security check completed!" 