# Notification Module for Action1 Scripts
# Purpose: Handles notifications for critical events and errors
# Author: Nigel Hagen
# Last Modified: March 7, 2025
# GitHub: https://github.com/Nigel1992/action1-monitoring-suite

# Initialize notification settings
$Script:NotificationConfig = @{
    UseEmail = $false
    UseWindowsNotification = $true
    AlertLevel = "Warning"  # Options: "Info", "Warning", "Critical"
    NotificationHistory = @()  # Store recent notifications
    MaxHistorySize = 100  # Maximum number of notifications to keep in history
    RepeatDelay = 3600  # Minimum seconds between repeated identical notifications
    BatchNotifications = $true  # Combine similar notifications
    BatchWindow = 300  # Time window in seconds for batching notifications
}

function Initialize-NotificationSystem {
    param (
        [string]$EmailUsername,
        [string]$EmailPassword,
        [string]$ToEmail,
        [bool]$UseEmail = $false,
        [bool]$UseWindowsNotification = $true,
        [string]$AlertLevel = "Warning",
        [int]$RepeatDelay = 3600,
        [bool]$BatchNotifications = $true,
        [int]$BatchWindow = 300
    )

    $Script:NotificationConfig.UseEmail = $UseEmail
    $Script:NotificationConfig.UseWindowsNotification = $UseWindowsNotification
    $Script:NotificationConfig.AlertLevel = $AlertLevel
    $Script:NotificationConfig.RepeatDelay = $RepeatDelay
    $Script:NotificationConfig.BatchNotifications = $BatchNotifications
    $Script:NotificationConfig.BatchWindow = $BatchWindow

    if ($UseEmail) {
        $Script:EmailConfig.To = $ToEmail
        $Script:EmailConfig.From = $EmailUsername
        $SecurePassword = ConvertTo-SecureString $EmailPassword -AsPlainText -Force
        $Script:EmailConfig.Credential = New-Object System.Management.Automation.PSCredential($EmailUsername, $SecurePassword)
    }

    # Create notification history file if it doesn't exist
    $historyPath = "$env:ProgramData\Action1\Logs\notification_history.json"
    if (-not (Test-Path $historyPath)) {
        New-Item -ItemType File -Path $historyPath -Force | Out-Null
        Set-Content -Path $historyPath -Value "[]"
    }
}

function Add-NotificationHistory {
    param (
        [string]$Message,
        [string]$Severity,
        [string]$Source
    )

    $historyPath = "$env:ProgramData\Action1\Logs\notification_history.json"
    $history = Get-Content -Path $historyPath | ConvertFrom-Json
    
    # Add new notification
    $notification = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Message = $Message
        Severity = $Severity
        Source = $Source
    }

    $history += $notification

    # Keep only the most recent notifications
    if ($history.Count -gt $Script:NotificationConfig.MaxHistorySize) {
        $history = $history | Select-Object -Last $Script:NotificationConfig.MaxHistorySize
    }

    # Save updated history
    $history | ConvertTo-Json | Set-Content -Path $historyPath
}

function Should-SendNotification {
    param (
        [string]$Message,
        [string]$Severity
    )

    $historyPath = "$env:ProgramData\Action1\Logs\notification_history.json"
    $history = Get-Content -Path $historyPath | ConvertFrom-Json

    # Check for recent identical notifications
    $recentNotification = $history | Where-Object {
        $_.Message -eq $Message -and
        $_.Severity -eq $Severity -and
        ([DateTime]::Parse($_.Timestamp)).AddSeconds($Script:NotificationConfig.RepeatDelay) -gt (Get-Date)
    }

    return $null -eq $recentNotification
}

function Send-BatchedNotifications {
    param (
        [array]$Notifications,
        [string]$Title,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if ($Notifications.Count -eq 0) { return }

    # Group notifications by severity
    $groupedNotifications = $Notifications | Group-Object -Property Severity

    foreach ($group in $groupedNotifications) {
        $severity = $group.Name
        $messages = $group.Group.Message -join "`n- "

        $batchMessage = @"
Multiple notifications ($($group.Count)):
- $messages
"@

        # Windows Notification
        if ($Script:NotificationConfig.UseWindowsNotification) {
            try {
                $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
                $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
                
                $toastXml = [xml]$template.GetXml()
                $toastXml.GetElementsByTagName("text")[0].AppendChild($toastXml.CreateTextNode("$Title - $severity")) > $null
                $toastXml.GetElementsByTagName("text")[1].AppendChild($toastXml.CreateTextNode("$ComputerName - $batchMessage")) > $null
                
                $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Action1 Monitor").Show($toast)
            } catch {
                Write-Warning "Failed to send Windows notification: $_"
            }
        }

        # Email Notification
        if ($Script:NotificationConfig.UseEmail) {
            try {
                $emailParams = @{
                    SmtpServer = $Script:EmailConfig.SMTPServer
                    Port = $Script:EmailConfig.Port
                    UseSsl = $Script:EmailConfig.UseSsl
                    From = $Script:EmailConfig.From
                    To = $Script:EmailConfig.To
                    Subject = "[$severity] $Title - Batch Notification - $ComputerName"
                    Body = @"
Severity: $severity
Computer: $ComputerName
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

$batchMessage

This is an automated notification from Action1 Scripts.
"@
                    Credential = $Script:EmailConfig.Credential
                }
                
                Send-MailMessage @emailParams
            } catch {
                Write-Warning "Failed to send email notification: $_"
            }
        }
    }
}

$Script:PendingNotifications = @()
$Script:LastBatchSent = Get-Date

function Send-Notification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Info", "Warning", "Critical")]
        [string]$Severity,
        
        [string]$Title = "Action1 Script Notification",
        
        [string]$ComputerName = $env:COMPUTERNAME,

        [string]$Source = "Unknown"
    )

    # Check if severity meets the alert level threshold
    $severityLevels = @{
        "Info" = 1
        "Warning" = 2
        "Critical" = 3
    }

    if ($severityLevels[$Severity] -ge $severityLevels[$Script:NotificationConfig.AlertLevel]) {
        # Add to notification history
        Add-NotificationHistory -Message $Message -Severity $Severity -Source $Source

        # Check if we should send this notification
        if (-not (Should-SendNotification -Message $Message -Severity $Severity)) {
            return
        }

        if ($Script:NotificationConfig.BatchNotifications) {
            # Add to pending notifications
            $Script:PendingNotifications += @{
                Message = $Message
                Severity = $Severity
                Title = $Title
                ComputerName = $ComputerName
            }

            # Check if it's time to send batched notifications
            if ((Get-Date) -gt $Script:LastBatchSent.AddSeconds($Script:NotificationConfig.BatchWindow)) {
                Send-BatchedNotifications -Notifications $Script:PendingNotifications -Title $Title -ComputerName $ComputerName
                $Script:PendingNotifications = @()
                $Script:LastBatchSent = Get-Date
            }
        } else {
            # Send immediate notification
            if ($Script:NotificationConfig.UseWindowsNotification) {
                try {
                    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
                    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
                    
                    $toastXml = [xml]$template.GetXml()
                    $toastXml.GetElementsByTagName("text")[0].AppendChild($toastXml.CreateTextNode($Title)) > $null
                    $toastXml.GetElementsByTagName("text")[1].AppendChild($toastXml.CreateTextNode("$ComputerName - $Message")) > $null
                    
                    $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
                    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Action1 Monitor").Show($toast)
                } catch {
                    Write-Warning "Failed to send Windows notification: $_"
                }
            }

            if ($Script:NotificationConfig.UseEmail) {
                try {
                    $emailParams = @{
                        SmtpServer = $Script:EmailConfig.SMTPServer
                        Port = $Script:EmailConfig.Port
                        UseSsl = $Script:EmailConfig.UseSsl
                        From = $Script:EmailConfig.From
                        To = $Script:EmailConfig.To
                        Subject = "[$Severity] $Title - $ComputerName"
                        Body = @"
Severity: $Severity
Computer: $ComputerName
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source: $Source

Message:
$Message

This is an automated notification from Action1 Scripts.
"@
                        Credential = $Script:EmailConfig.Credential
                    }
                    
                    Send-MailMessage @emailParams
                } catch {
                    Write-Warning "Failed to send email notification: $_"
                }
            }
        }
    }
}

# Example usage:
# Initialize-NotificationSystem -EmailUsername "your-email@gmail.com" -EmailPassword "your-app-password" -ToEmail "your-email@gmail.com" -UseEmail $true
# Send-Notification -Message "Disk space is critically low" -Severity "Critical" 