# Windows Security Audit Script

**Version:** 1.0  
**Author:** Bartłomiej Pogwizd / [YouTube@pTech-pl](https://youtube.com/@pTech-pl)

A comprehensive PowerShell script that performs a security audit on Windows systems, checks for common misconfigurations, and offers automated fixes.

## Features

- **System Security** – Windows Defender, Firewall, BitLocker, UAC, Secure Boot, TPM, Credential Guard, AppLocker, ASLR/DEP
- **Privacy & Telemetry** – Telemetry level, Advertising ID, Activity History, Cortana, Location tracking
- **Sharing & Remote Access** – RDP, WinRM, Remote Registry, SMB1, SMB shares
- **System Services** – Disables risky services (Telnet, SNMP, IIS, etc.)
- **Network** – Lists open TCP/UDP ports, checks DNS-over-HTTPS
- **User Accounts** – Guest, built-in Admin, empty passwords, password policies, lockout, audit policy
- **Startup & Tasks** – Run keys, Startup folder, non-Microsoft scheduled tasks
- **SSH Hardening** – Checks `sshd_config` settings
- **Software Inventory** – Lists installed applications and flags risky ones
- **Event Log Health** – Verifies Security/System/Application logs are enabled
- **Reports** – Generates JSON and HTML reports with detailed findings
- **Auto-Fix** – Interactive repair of discovered issues

## Requirements

- Windows 7 / 8 / 10 / 11 (or Server 2012+)
- PowerShell 5.1 or later
- **Administrator privileges** (recommended – some checks require admin)

## Usage

1. Download the script: `auditWIN.ps1`
2. Open PowerShell **as Administrator**.
3. Navigate to the script folder:
   ```powershell
   cd C:\path\to\script

## Run

   powershell -ExecutionPolicy Bypass -File .\auditWIN.ps1

## After 
Wait for the audit to complete – results appear on screen.

At the end, you'll be asked whether to apply automatic fixes (type t for yes, n for no, a for all, q to quit).

Reports are saved as windows_security_report.json and windows_security_report.html in the script folder.
