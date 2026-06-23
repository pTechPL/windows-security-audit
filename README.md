# 🛡️ Windows Security Audit

A PowerShell-based security auditing toolkit for Windows that checks system hardening settings, privacy configuration, remote access exposure, user security, and other security controls. Generates a security score and offers optional auto-remediation for selected findings.

> Created by **Bartłomiej Pogwizd** · https://www.youtube.com/@pTech-pl

---

## Overview

**auditWIN.ps1** is a Windows security auditing script designed to help administrators and home users quickly assess the security posture of their systems.

The script:

* performs security checks across multiple categories
* displays colour-coded results in the console
* calculates a security score and risk level
* identifies weak or insecure configurations
* offers optional auto-fixes for selected findings
* logs audit results to a TSV report file

---

## Screenshot

<img width="2480" height="1200" alt="Zrzut ekranu 2026-06-23 094154" src="https://github.com/user-attachments/assets/5d82fa7c-7107-478f-8115-8706ed8719f9" />



```
========================================
Windows Security / Audit Report
Author: Bartlomiej Pogwizd
Version: 1.0
========================================

1. System Security
----------------------------------------
Windows Defender (AV)           OK       Enabled
Firewall (Domain)               OK       Enabled
Firewall (Private)              OK       Enabled
Firewall (Public)               OK       Enabled
Windows Update Service          OK       Running

Security Score                  86/100
Risk Level: Low
```

---

## Requirements

* Windows 10 or Windows 11
* PowerShell 5.1 or newer
* Administrator privileges recommended
* Windows Defender (for Defender-specific checks)

---

## Usage

### Run the audit

Open PowerShell and execute:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "C:\skrypt\auditWIN.ps1"
```

For best results, launch PowerShell as Administrator.

---

## What the Script Does

The audit covers the following security areas:

| Category                            | Checks                                                                                                          |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| **System Security**                 | Windows Defender, Real-Time Protection, Tamper Protection, AV signatures, SmartScreen, Firewall, Windows Update |
| **Privacy & Telemetry**             | Telemetry level, Advertising ID, privacy-related settings                                                       |
| **Sharing & Remote Access**         | Remote Desktop, Network Level Authentication (NLA), remote access exposure                                      |
| **System Services**                 | Telnet, SNMP, FTP, IIS, Print Spooler, Xbox services and other potentially risky services                       |
| **Network & Listening Ports**       | Open TCP/UDP ports and exposed services                                                                         |
| **Users & Privileges**              | Guest account, Built-in Administrator account, password requirements                                            |
| **Startup Items & Scheduled Tasks** | Auto-start applications and scheduled tasks                                                                     |
| **SSH Hardening**                   | OpenSSH configuration, root login, password authentication, public key authentication                           |
| **Installed Software**              | Inventory of installed applications and detection of potentially risky software                                 |
| **Event Log Health**                | Security, System and Application logs, recent failed logon attempts                                             |

---

## Auto-Fix Mode

For many failed checks the script can automatically apply recommended settings.

When a problem is detected, the script offers options such as:

```text
[y] Yes
[n] No
[a] Fix all
[q] Quit
```

Examples of automatic remediation:

* Enable Windows Defender
* Enable Real-Time Protection
* Enable SmartScreen
* Enable Windows Firewall
* Enable Windows Update service
* Disable Guest account
* Disable Remote Desktop
* Enable Network Level Authentication (NLA)

After applying fixes, rerunning the audit is recommended.

---

## Output Status

| Status | Meaning                                                   |
| ------ | --------------------------------------------------------- |
| `OK`   | Configuration meets recommended security settings         |
| `WARN` | Potential issue or manual review recommended              |
| `FAIL` | Configuration does not meet recommended security settings |
| `INFO` | Informational finding only                                |

---

## Security Score

The score is calculated using audit results:

```text
score = (passed × 100 + warnings × 50) / total_checks
```

### Risk Levels

| Score  | Risk Level |
| ------ | ---------- |
| 80–100 | 🟢 Low     |
| 50–79  | 🟡 Medium  |
| 0–49   | 🔴 High    |

---

## Example Findings

### Good

```text
Windows Defender (AV)      OK
Firewall (Public)          OK
SmartScreen                OK
```

### Warning

```text
Tamper Protection          WARN
Built-in Administrator     WARN
Recent Failed Logons       WARN
```

### Failure

```text
Remote Desktop             FAIL
Guest Account              FAIL
Windows Update Service     FAIL
```

---

## Potentially Risky Software Detection

The script highlights commonly abused remote-access or legacy software, including:

* TeamViewer
* AnyDesk
* UltraVNC
* RealVNC
* LogMeIn
* Adobe Flash
* Legacy Java versions

These findings are informational and should be reviewed manually.

---

## Notes

* The script is primarily read-only except when using Auto-Fix mode.
* Administrator rights improve audit accuracy.
* Some security settings cannot be safely modified automatically and require manual review.
* Results are saved to a temporary TSV file for later analysis.
* Auto-remediation is always optional and requires user confirmation.

---

## License

MIT — feel free to use, modify, and share.

---

## Contributing

Pull requests and issues are welcome.

If a check behaves differently on your Windows version, please include:

```powershell
winver
```

or

```powershell
Get-ComputerInfo | Select WindowsProductName, WindowsVersion
```

when reporting the issue.
