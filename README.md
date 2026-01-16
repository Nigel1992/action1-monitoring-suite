[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Nigel1992)

# 🚀 Action1 Advanced Monitoring Suite

![GitHub last commit](https://img.shields.io/github/last-commit/Nigel1992/action1-monitoring-suite)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2B-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A comprehensive PowerShell script collection for monitoring and maintaining family PCs using Action1 RMM. Features intelligent notifications, advanced system maintenance, and security monitoring.

## 🌟 Features

### 📊 Advanced Monitoring
- Real-time system performance tracking
- Disk space monitoring with smart thresholds
- Memory usage analysis
- Critical service status monitoring
- Windows Update tracking

### 🔔 Smart Notifications
- Multi-channel notifications (Email & Windows Toast)
- Notification batching to prevent alert fatigue
- Intelligent deduplication
- Severity-based filtering
- Notification history tracking
- Customizable alert thresholds

### 🛠️ System Maintenance
- Automated disk cleanup
- System file integrity checks
- Windows Update cache management
- Temporary file cleanup
- Disk health monitoring

### 🔒 Security Features
- Windows Defender status monitoring
- Firewall configuration checks
- Unauthorized user detection
- Suspicious network connection monitoring
- Security event log analysis
- System integrity verification

## 📋 Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- Action1 RMM agent installed
- Administrative privileges
- .NET Framework 4.7.2 or later

## 🚀 Quick Start

1. Clone the repository:
```powershell
git clone https://github.com/Nigel1992/action1-monitoring-suite.git
```

2. Configure notification settings:
```powershell
# Edit Action1Scripts/Notification-Module.ps1
$EmailConfig = @{
    SMTPServer = "your.smtp.server"
    From = "your@email.com"
    To = "alerts@yourdomain.com"
}
```

3. Deploy to Action1:
- Log into Action1 dashboard
- Navigate to "Policies & Scripts"
- Import the scripts
- Configure schedules

## 📦 Script Overview

### 1. System-Maintenance.ps1
Comprehensive system maintenance script with smart notifications:
- Disk cleanup and optimization
- System file verification
- Performance monitoring
- Health checks

### 2. Security-Check.ps1
Advanced security monitoring:
- Real-time threat detection
- Configuration compliance
- Network security monitoring
- User activity tracking

### 3. Software-Update-Check.ps1
Software update management:
- Windows Update status
- Common software version tracking
- Update requirement analysis
- Compatibility checking

### 4. Notification-Module.ps1
Intelligent notification system:
- Multi-channel delivery
- Smart batching
- Deduplication
- History tracking
- Threshold management

## ⚙️ Configuration

### Notification Settings
```powershell
Initialize-NotificationSystem `
    -EmailUsername "your@email.com" `
    -EmailPassword "your-app-password" `
    -ToEmail "alerts@domain.com" `
    -UseEmail $true `
    -UseWindowsNotification $true `
    -AlertLevel "Warning" `
    -BatchNotifications $true `
    -BatchWindow 300
```

### Alert Thresholds
```powershell
$NotificationConfig = @{
    DiskSpaceWarning = 20  # Percentage
    DiskSpaceCritical = 10
    MemoryWarning = 80
    MemoryCritical = 90
    BatchWindow = 300  # Seconds
    RepeatDelay = 3600  # Seconds
}
```

## 📊 Logging

All scripts create detailed logs in:
```
C:\ProgramData\Action1\Logs\
```

Log files include:
- maintenance_YYYY-MM-DD.log
- security_YYYY-MM-DD.log
- updates_YYYY-MM-DD.log
- notification_history.json

## 🔄 Scheduling Recommendations

| Script | Frequency | Time |
|--------|-----------|------|
| System-Maintenance.ps1 | Weekly | Off-hours |
| Security-Check.ps1 | Daily | Every 12h |
| Software-Update-Check.ps1 | Daily | Morning |

## 🛠️ Troubleshooting

1. Check log files in C:\ProgramData\Action1\Logs\
2. Verify PowerShell execution policy
3. Ensure administrative privileges
4. Check Action1 agent status
5. Verify network connectivity

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Nigel Hagen**
- GitHub: [@Nigel1992](https://github.com/Nigel1992)
- Created: March 7, 2025

## 🙏 Acknowledgments

- Action1 RMM team for their excellent platform
- PowerShell community for inspiration and support
- All contributors and users of this suite

## 📞 Support

For issues and questions:
1. Check the [Issues](https://github.com/Nigel1992/action1-monitoring-suite/issues) page
2. Review Action1 documentation
3. Contact Action1 support
4. Create a new issue 
