# Action1 PowerShell Scripts Collection

This collection contains useful PowerShell scripts designed to be used with Action1 RMM for managing and maintaining family PCs.

## Scripts Overview

1. **System-Maintenance.ps1**
   - Performs comprehensive system maintenance tasks
   - Cleans temporary files and Windows Update cache
   - Runs system file checker
   - Checks disk health
   - Generates system performance reports

2. **Software-Update-Check.ps1**
   - Checks for pending Windows Updates
   - Scans for outdated common software
   - Verifies Windows Defender status
   - Monitors available disk space for updates

3. **Security-Check.ps1**
   - Monitors Windows Defender and Firewall status
   - Checks for unauthorized user accounts
   - Monitors critical system services
   - Analyzes security event logs
   - Checks network connections
   - Verifies system integrity

## Setup Instructions

1. Log in to your Action1 dashboard
2. Navigate to "Policies & Scripts"
3. Click "Add New Script"
4. Copy and paste the content of each script
5. Save the scripts with appropriate names

## Deployment Instructions

1. In the Action1 dashboard, go to "Endpoints"
2. Select the target computers
3. Click "Run Script"
4. Choose the desired script from your saved scripts
5. Set the schedule (one-time or recurring)
6. Click "Run" to execute

## Script Scheduling Recommendations

- **System-Maintenance.ps1**: Run weekly during off-hours
- **Software-Update-Check.ps1**: Run daily
- **Security-Check.ps1**: Run daily or every 12 hours

## Log Files

All scripts create detailed logs in the following location:
```
C:\ProgramData\Action1\Logs\
```

Log files are named with the following pattern:
- maintenance_YYYY-MM-DD.log
- updates_YYYY-MM-DD.log
- security_YYYY-MM-DD.log

## Requirements

- Windows 10 or later
- Action1 RMM agent installed
- Administrative privileges
- PowerShell 5.1 or later

## Best Practices

1. Review logs regularly to monitor system health
2. Adjust scheduling based on your specific needs
3. Keep scripts updated with latest security practices
4. Test scripts on a single machine before mass deployment
5. Maintain backups before running maintenance tasks

## Troubleshooting

If you encounter issues:

1. Check the log files for detailed error messages
2. Verify PowerShell execution policy
3. Ensure proper permissions are set
4. Verify Action1 agent is running
5. Check network connectivity

## Security Notes

- Scripts run with elevated privileges
- All actions are logged for accountability
- Network connections are monitored
- System changes are documented
- User account modifications are tracked

## Support

For issues or questions:
1. Check Action1 documentation
2. Contact Action1 support
3. Review Windows PowerShell documentation

## Customization

Feel free to modify these scripts to:
- Add more software to monitor
- Adjust cleaning parameters
- Modify logging details
- Add custom security checks
- Include additional maintenance tasks 