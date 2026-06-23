# 🔒 Windows Security Audit

A comprehensive PowerShell-based security auditing toolkit for Windows that checks system hardening settings against security best practices and generates JSON/HTML reports.

> Created by **Bartłomiej Pogwizd** · https://www.youtube.com/@pTech-pl

---

## Overview

This PowerShell script performs a full security audit on Windows systems, checking:
- System security settings (Defender, Firewall, BitLocker, UAC, Secure Boot)
- Privacy and telemetry configurations
- Remote access and sharing settings
- User account security (passwords, policies, empty accounts)
- Network listening ports and services
- Startup items and scheduled tasks
- SSH hardening (if installed)
- Event log health

Results are displayed in the terminal with colour-coded statuses and automatically saved as **JSON** and **HTML** reports.

---

## Screenshot

<img width="2480" height="1200" alt="Zrzut ekranu 2026-06-23 094154" src="https://github.com/user-attachments/assets/b85cf7af-4059-4f23-888b-ad4ce48bacc3" />


---

## Requirements

- Windows 7 / 8 / 10 / 11 or Windows Server 2012+
- PowerShell 5.1 or later (pre-installed on modern Windows)
- **Administrator privileges** (recommended – some checks require elevated access)

---

## Usage

### Step 1 — Download the script

Save the script as `audit.ps1` in a convenient folder (e.g. `C:\Scripts\`).

### Step 2 — Run the audit

Open **PowerShell as Administrator** and navigate to the script folder:

```powershell
cd C:\Scripts
powershell -ExecutionPolicy Bypass -File .\audit.ps1
The script will:

detect if you're running as Administrator (and warn if not)

run ~80+ security checks across 11 categories

print colour-coded results to the terminal

display a Security Score (0–100) and Risk Level (Low/Medium/High)

offer interactive auto-fix for detected issues

Step 3 — Auto-fix options
After the audit, you'll be prompted with auto-fix options:

Option	Description
t / y	Apply the fix for this specific issue
n	Skip this fix
a	Apply all remaining fixes automatically
q	Quit auto-fix and skip all remaining
Step 4 — Review reports
Two files are generated in the script folder:

windows_security_report.json — structured data format

windows_security_report.html — human-readable report with styling

What Gets Checked
Category	Checks
System Security	Windows Defender (AV, Real-Time, Tamper Protection), Firewall profiles, Windows Update service, Secure Boot, BitLocker (with TPM/no-TPM support), UAC, ASLR/DEP, Credential Guard, AppLocker
Privacy & Telemetry	Telemetry level, Advertising ID, Activity History, Cortana, Location tracking, Feedback frequency
Sharing & Remote Access	Remote Desktop (RDP + NLA), WinRM, Remote Registry, SMB (LanmanServer), SMB1 protocol, Custom SMB shares
System Services	Risky services: Telnet, TFTP, SNMP, Simple TCP, FTP, IIS, RAS, Xbox services, Print Spooler
Network & Ports	Open TCP/UDP listening ports (with process names), DNS over HTTPS (DoH)
Users & Privileges	Guest account, built-in Administrator, accounts with empty passwords, password policies (age/length), account lockout, audit policy (Logon/Privilege Use), local Administrators group members
Startup & Scheduled Tasks	Registry Run/RunOnce keys, Startup folder, non-Microsoft scheduled tasks
SSH Hardening	OpenSSH Server status, PermitRootLogin, PasswordAuthentication, MaxAuthTries, LoginGraceTime, AllowUsers
Installed Software	Full list of installed applications, flags known risky software (TeamViewer, AnyDesk, VNC, Adobe Flash, old Java versions)
Event Log Health	Security, System, Application logs (enabled and size), recent failed logon events
Output Example
text
========================================
Windows Security / Audit Report
Author: Bartlomiej Pogwizd / youtube.com/@pTech-pl
Version: 2.0
========================================

1. System Security
----------------------------------------
Windows Defender (AV)                  OK       Enabled
Real-Time Protection                   OK       Enabled
Firewall (Public)                      OK       Enabled
BitLocker (C:)                         FAIL     Disabled (TPM available)
Secure Boot                            OK       Enabled
UAC                                    OK       Enabled (level 5)
...

11. Security Score
----------------------------------------
Security Score                         78/100
Risk Level:                            Medium

Passed                                 45
Warnings                               12
Failures                               8
Status legend:

Status	Meaning
OK	Setting meets the recommended value
WARN	Setting could not be determined or is a grey area
FAIL	Setting does not meet the recommendation
INFO	Informational only, no pass/fail judgement
Security Score
The score is calculated as:

text
score = (passed × 100 + warnings × 50) / total_checks
Score	Risk Level
80–100	🟢 Low
50–79	🟡 Medium
0–49	🔴 High
Notes
The audit is read-only — it never modifies any system settings unless you explicitly approve an auto-fix

Some checks require Administrator privileges — the script will warn you if not running as admin

The script attempts to detect and work around missing features (e.g. no TPM, older Windows versions)

Temporary files are created in %TEMP% and automatically cleaned up on exit

The HTML report is self-contained and can be opened in any modern browser

Event log checks require the Security log to be enabled and accessible

Troubleshooting
"Execution Policy" error
If you see:

text
File cannot be loaded because running scripts is disabled on this system
Run the script with:

powershell
powershell -ExecutionPolicy Bypass -File .\audit.ps1
Or permanently allow local scripts:

powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
"Access denied" on some checks
Run PowerShell as Administrator for full access to system checks.

Missing BitLocker module
BitLocker checks may fail on Windows editions without BitLocker support (e.g. Home edition) — this is normal.

Security & Privacy
No data is sent anywhere — everything stays on your local machine

The JSON and HTML reports contain detailed system information — do not share them publicly

The script uses silentlycontinue error handling — no exceptions are thrown

All temporary files are created with restricted permissions and deleted on exit

CIS Benchmark Mapping
Many checks in the HTML/JSON report are mapped to corresponding CIS Windows Benchmark recommendations (where applicable). This helps cross-reference with official security documentation for remediation guidance.

License
MIT — feel free to use, modify, and share.

Contributing
Pull requests and issues are welcome. If a check produces incorrect results on your Windows version, please open an issue with:

Windows version (winver)

PowerShell version ($PSVersionTable.PSVersion)

Output of the failing check (or relevant section)

Version v2.0

Added: Exploit Protection (ASLR/DEP) checks

Added: Credential Guard detection

Added: AppLocker/WDAC detection

Added: DNS over HTTPS (DoH) check

Added: Account lockout threshold check

Added: Empty password account detection and fix

Added: Recent failed logon events

Added: Risky software detection

Added: Print Spooler security warning (PrintNightmare)

Added: SMB1 protocol detection and fix

Added: Event log health checks

Added: Interactive auto-fix with t/n/a/q options

Improved: HTML report styling and readability

Fixed: Auto-fix error handling

Core system security checks

Basic privacy and telemetry checks

User and privilege audits

Network port scanning

JSON/HTML report generation<img width="2480" height="1200" alt="Zrzut ekranu 2026-06-23 094154" src="https://github.com/user-attachments/assets/97312b0d-a35f-451f-b58e-0c1c380cecd4" />
