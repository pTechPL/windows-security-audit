# ========================================
# Windows Security / Hardening Report
# Author: Bartlomiej
# Version: 2.0
# Developed with assistance from AI tools
# and public security documentation.
# ========================================

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# GLOBALS
# ============================================================

$AUTHOR  = "Author: Bartlomiej Pogwizd / youtube.com/@pTech-pl"
$VERSION = "Version: 2.0"
$TITLE   = "Windows Security / Audit Report"
$LINE    = "========================================"
$DASH    = "----------------------------------------"

$script:PASS_COUNT = 0
$script:WARN_COUNT = 0
$script:FAIL_COUNT = 0

$script:FIX_REGISTRY = [System.Collections.Generic.List[hashtable]]::new()

$DATA_FILE = [System.IO.Path]::Combine($env:TEMP, "win_audit_$([System.IO.Path]::GetRandomFileName()).tsv")
"label`tstatus`tdetail" | Out-File -FilePath $DATA_FILE -Encoding UTF8

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Write-Color {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::White)
    $prev = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $prev
}

function Print-Title {
    Write-Color $LINE    -Color Cyan
    Write-Color $TITLE   -Color Cyan
    Write-Color $AUTHOR  -Color DarkGray
    Write-Color $VERSION -Color DarkGray
    Write-Color $LINE    -Color Cyan
    Write-Host ""
}

function Print-Section {
    param([string]$Title)
    Write-Host ""
    Write-Color $Title -Color Yellow
    Write-Color $DASH  -Color Yellow
}

function Print-Row {
    param(
        [string]$Label,
        [string]$Status,
        [string]$Detail,
        [ConsoleColor]$Color
    )
    $labelPad  = $Label.PadRight(36)
    $statusPad = $Status.PadRight(8)
    $prev = $Host.UI.RawUI.ForegroundColor
    Write-Host -NoNewline $labelPad
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host -NoNewline $statusPad
    $Host.UI.RawUI.ForegroundColor = $prev
    Write-Host " $Detail"
}

function Log-Result {
    param([string]$Label, [string]$Status, [string]$Detail)
    "$Label`t$Status`t$Detail" | Out-File -FilePath $DATA_FILE -Append -Encoding UTF8
}

function ok {
    param([string]$Label, [string]$Detail = "")
    Print-Row -Label $Label -Status "OK"   -Detail $Detail -Color Green
    $script:PASS_COUNT++
    Log-Result $Label "OK" $Detail
}

function warn {
    param([string]$Label, [string]$Detail = "")
    Print-Row -Label $Label -Status "WARN" -Detail $Detail -Color Yellow
    $script:WARN_COUNT++
    Log-Result $Label "WARN" $Detail
}

function fail {
    param([string]$Label, [string]$Detail = "")
    Print-Row -Label $Label -Status "FAIL" -Detail $Detail -Color Red
    $script:FAIL_COUNT++
    Log-Result $Label "FAIL" $Detail
}

function info {
    param([string]$Label, [string]$Detail = "")
    Print-Row -Label $Label -Status "INFO" -Detail $Detail -Color DarkGray
    Log-Result $Label "INFO" $Detail
}

function Register-Fix {
    param(
        [string]$Label,
        [string]$Description,
        [scriptblock]$Command
    )
    $script:FIX_REGISTRY.Add(@{
        Label       = $Label
        Description = $Description
        Command     = $Command
    })
}

function Run-Fixes {
    if ($script:FIX_REGISTRY.Count -eq 0) {
        Write-Host ""
        Write-Color $LINE -Color Green
        Write-Color "  AUTO-FIX -- No problems to fix" -Color Green
        Write-Color $LINE -Color Green
        Write-Color "[OK] Great! No issues detected that can be auto-fixed." -Color Green
        Write-Color "  Check WARN sections manually if any appeared." -Color DarkGray
        return
    }

    Write-Host ""
    Write-Color $LINE -Color Cyan
    Write-Color "  AUTO-FIX -- Available fixes ($($script:FIX_REGISTRY.Count) issue(s))" -Color Cyan
    Write-Color $LINE -Color Cyan
    Write-Color "The following issues can be automatically fixed." -Color Yellow
    Write-Color "Options: [y] yes  [n] no  [a] all  [q] quit" -Color Yellow
    Write-Host ""

    $fixed        = 0
    $skipped      = 0
    $failed       = 0
    $failedLabels = @()
    $fixAll       = $false

    foreach ($entry in $script:FIX_REGISTRY) {
        Write-Color "[FAIL] $($entry.Label)" -Color Red
        Write-Host  "       Fix: $($entry.Description)"

        $doFix = $false
        if ($fixAll) {
            $doFix = $true
            Write-Color "       [auto] Applying (all-fix mode)..." -Color DarkGray
        } else {
            Write-Host -NoNewline "       Apply? [y/n/a/q]: "
            $answer = Read-Host
            if ($answer -match '^[qQ]$') {
                Write-Color "       Aborting auto-fix." -Color DarkGray
                break
            } elseif ($answer -match '^[aA]$') {
                $fixAll = $true
                $doFix  = $true
                Write-Color "       Mode: fix all remaining." -Color Yellow
            } elseif ($answer -match '^[yY]$') {
                $doFix = $true
            }
        }

        if ($doFix) {
            Write-Color "       Applying..." -Color Yellow
            try {
                & $entry.Command
                Write-Color "       [OK] Fixed successfully" -Color Green
                $fixed++
            } catch {
                Write-Color "       [!!] Failed -- check manually or run as Administrator" -Color Red
                $failed++
                $failedLabels += $entry.Label
            }
        } else {
            Write-Color "       Skipped" -Color DarkGray
            $skipped++
        }
        Write-Host ""
    }

    Write-Color $DASH -Color Cyan
    Write-Host -NoNewline "Fixed:   "; Write-Color "$fixed"   -Color Green
    Write-Host -NoNewline "Skipped: "; Write-Color "$skipped" -Color Yellow
    Write-Host -NoNewline "Failed:  "; Write-Color "$failed"  -Color Red

    if ($failedLabels.Count -gt 0) {
        Write-Host ""
        Write-Color "The following fixes failed:" -Color Red
        foreach ($lbl in $failedLabels) { Write-Color "  * $lbl" -Color Red }
        Write-Color "Tip: Run the script as Administrator and try again." -Color DarkGray
    }
    if ($fixed -gt 0) {
        Write-Host ""
        Write-Color "Recommended: run the script again to verify changes." -Color Yellow
    }
}

# ============================================================
# ADMIN CHECK
# ============================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

Clear-Host
Print-Title

if (-not $isAdmin) {
    Write-Color "WARNING: Script is not running as Administrator." -Color Red
    Write-Color "Some checks will be unavailable or inaccurate." -Color Yellow
    Write-Color "Recommended: run PowerShell as Administrator." -Color Yellow
    Write-Host ""
}

# System info header
$os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cpu = Get-CimInstance Win32_Processor        -ErrorAction SilentlyContinue | Select-Object -First 1
if ($os) {
    info "OS" "$($os.Caption) (Build $($os.BuildNumber))"
    $lastBoot = $os.LastBootUpTime
    $uptime   = (Get-Date) - $lastBoot
    info "Last Boot" "$($lastBoot.ToString('yyyy-MM-dd HH:mm')) (uptime: $([int]$uptime.TotalHours)h)"
}
if ($cpu) { info "CPU" $cpu.Name.Trim() }
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1GB, 1)
if ($ram) { info "RAM" "$ram GB" }
Write-Host ""

# ============================================================
# 1. SYSTEM SECURITY
# ============================================================
Print-Section "1. System Security"

# --- Windows Defender ---
$av = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($av) {
    if ($av.AntivirusEnabled) {
        ok "Windows Defender (AV)" "Enabled"
    } else {
        fail "Windows Defender (AV)" "Disabled"
        Register-Fix "Windows Defender (AV)" "Enable antivirus protection" {
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
    }

    if ($av.RealTimeProtectionEnabled) {
        ok "Real-Time Protection" "Enabled"
    } else {
        fail "Real-Time Protection" "Disabled"
        Register-Fix "Real-Time Protection" "Enable real-time protection" {
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
    }

    if ($av.IsTamperProtected) {
        ok "Tamper Protection" "Enabled"
    } else {
        warn "Tamper Protection" "Disabled -- enable in Windows Security app"
    }

    $daysOld = [int]((Get-Date) - $av.AntivirusSignatureLastUpdated).TotalDays
    if ($daysOld -le 3) {
        ok "AV Signatures" "Up to date ($daysOld days old)"
    } elseif ($daysOld -le 7) {
        warn "AV Signatures" "$daysOld days since last update"
    } else {
        fail "AV Signatures" "$daysOld days since last update"
        Register-Fix "AV Signatures" "Update Windows Defender signatures" { Update-MpSignature }
    }
} else {
    warn "Windows Defender" "Cannot query (third-party AV or service stopped)"
}

# --- SmartScreen ---
$ssApp = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name EnableSmartScreen -ErrorAction SilentlyContinue).EnableSmartScreen
if ($ssApp -eq 1) {
    ok "SmartScreen (Apps)" "Enabled by policy"
} elseif ($ssApp -eq 0) {
    fail "SmartScreen (Apps)" "Disabled by policy"
    Register-Fix "SmartScreen (Apps)" "Enable SmartScreen for apps" {
        Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableSmartScreen -Value 1 -Type DWord -Force
    }
} else {
    $ssReg = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" `
        -Name SmartScreenEnabled -ErrorAction SilentlyContinue).SmartScreenEnabled
    if ($ssReg -eq "Off") {
        fail "SmartScreen (Apps)" "Disabled"
        Register-Fix "SmartScreen (Apps)" "Enable SmartScreen for apps" {
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -Value "RequireAdmin" -Force
        }
    } else {
        ok "SmartScreen (Apps)" "Enabled (default)"
    }
}

# --- Firewall ---
$fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
if ($fwProfiles) {
    foreach ($profile in $fwProfiles) {
        $pname = $profile.Name
        if ($profile.Enabled) {
            ok "Firewall ($pname)" "Enabled"
        } else {
            fail "Firewall ($pname)" "Disabled"
            Register-Fix "Firewall ($pname)" "Enable firewall for $pname profile" {
                Set-NetFirewallProfile -Profile $pname -Enabled True
            }
        }
    }
} else {
    warn "Firewall" "Cannot query firewall profiles"
}

# --- Windows Update service ---
$updateSvc = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if ($updateSvc -and $updateSvc.StartType -ne 'Disabled') {
    ok "Windows Update Service" "Enabled ($($updateSvc.Status))"
} else {
    fail "Windows Update Service" "Disabled"
    Register-Fix "Windows Update Service" "Enable Windows Update service" {
        Set-Service -Name wuauserv -StartupType Automatic
        Start-Service -Name wuauserv
    }
}

# --- Last Windows Update ---
$hotfix = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($hotfix -and $hotfix.InstalledOn) {
    $patchAge = [int]((Get-Date) - $hotfix.InstalledOn).TotalDays
    if ($patchAge -le 30) {
        ok "Last Windows Update" "$($hotfix.HotFixID) installed $patchAge days ago"
    } elseif ($patchAge -le 60) {
        warn "Last Windows Update" "$patchAge days ago ($($hotfix.HotFixID)) -- consider updating"
    } else {
        fail "Last Windows Update" "$patchAge days ago -- system is outdated"
    }
} else {
    warn "Last Windows Update" "Cannot determine last patch date"
}

# --- Secure Boot ---
try {
    $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
    if ($secureBoot) { ok "Secure Boot" "Enabled" } else { fail "Secure Boot" "Disabled" }
} catch {
    info "Secure Boot" "Cannot determine (not UEFI or requires admin)"
}

# --- BitLocker ---
$bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
if ($bl) {
    $blStatus = $bl.ProtectionStatus
    $blMethod = $bl.EncryptionMethod
    if ($blStatus -eq 'On') {
        ok "BitLocker ($env:SystemDrive)" "Enabled -- $blMethod"
    } else {
        $tpm      = Get-Tpm -ErrorAction SilentlyContinue
        $tpmReady = $tpm -and $tpm.TpmPresent -and $tpm.TpmReady
        if ($tpmReady) {
            fail "BitLocker ($env:SystemDrive)" "Disabled (TPM available)"
            Register-Fix "BitLocker" "Enable disk encryption (TPM + recovery key)" {
                Enable-BitLocker -MountPoint $env:SystemDrive -EncryptionMethod XtsAes256 `
                    -UsedSpaceOnly -SkipHardwareTest -RecoveryPasswordProtector
            }
        } else {
            fail "BitLocker ($env:SystemDrive)" "Disabled -- no TPM (enable in BIOS or use password mode)"
            Register-Fix "BitLocker" "Configure BitLocker without TPM (startup password)" {
                $gpPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
                if (-not (Test-Path $gpPath)) { New-Item -Path $gpPath -Force | Out-Null }
                Set-ItemProperty -Path $gpPath -Name EnableBDEWithNoTPM -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $gpPath -Name UseAdvancedStartup -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $gpPath -Name UseTPM             -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $gpPath -Name UseTPMKey          -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $gpPath -Name UseTPMKeyPIN       -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $gpPath -Name UseTPMPIN          -Value 2 -Type DWord -Force
                Write-Host "  [INFO] Registry configured. Run manually:" -ForegroundColor Yellow
                Write-Host "  manage-bde -on $env:SystemDrive -Password -RecoveryPassword" -ForegroundColor Cyan
            }
        }
    }
} else {
    warn "BitLocker" "Cannot query (requires admin or edition not supported)"
}

# --- TPM ---
$tpmInfo = Get-Tpm -ErrorAction SilentlyContinue
if ($tpmInfo) {
    if ($tpmInfo.TpmPresent -and $tpmInfo.TpmReady) {
        ok "TPM" "Present and ready"
    } elseif ($tpmInfo.TpmPresent) {
        warn "TPM" "Present but not ready (check BIOS settings)"
    } else {
        warn "TPM" "Not present or disabled in BIOS"
    }
} else {
    info "TPM" "Cannot query TPM status"
}

# --- UAC ---
$uacKey   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$uacLevel = (Get-ItemProperty -Path $uacKey -Name ConsentPromptBehaviorAdmin -ErrorAction SilentlyContinue).ConsentPromptBehaviorAdmin
if ($null -eq $uacLevel) {
    warn "UAC" "Cannot read registry value"
} elseif ($uacLevel -ge 2) {
    ok "UAC" "Enabled (level $uacLevel)"
} else {
    fail "UAC" "Disabled or suppressed (level $uacLevel)"
    Register-Fix "UAC" "Restore default UAC level" {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
            -Name ConsentPromptBehaviorAdmin -Value 5
    }
}

# --- Exploit Protection (DEP / ASLR) ---
$dep = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
    -Name MoveImages -ErrorAction SilentlyContinue).MoveImages
$aslr = (Get-ProcessMitigation -System -ErrorAction SilentlyContinue)
if ($aslr) {
    if ($aslr.ASLR.BottomUp -eq 'ON' -or $aslr.ASLR.ForceRelocateImages -eq 'ON') {
        ok "ASLR (System)" "Enabled"
    } else {
        warn "ASLR (System)" "Not fully enabled -- check Exploit Protection settings"
    }
    if ($aslr.DEP.Enable -eq 'ON') {
        ok "DEP (System)" "Enabled"
    } else {
        fail "DEP (System)" "Disabled"
        Register-Fix "DEP" "Enable Data Execution Prevention system-wide" {
            Set-Processmitigation -System -Enable DEP
        }
    }
} else {
    info "Exploit Protection" "Cannot query (Get-ProcessMitigation unavailable)"
}

# --- Credential Guard ---
$cgKey = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" `
    -Name EnableVirtualizationBasedSecurity -ErrorAction SilentlyContinue).EnableVirtualizationBasedSecurity
$cgRun = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" `
    -Name LsaCfgFlags -ErrorAction SilentlyContinue).LsaCfgFlags
if ($cgKey -ge 1 -and $cgRun -ge 1) {
    ok "Credential Guard" "Enabled (VBS + LSA)"
} elseif ($cgKey -ge 1) {
    warn "Credential Guard" "VBS enabled but LSA protection not confirmed"
} else {
    warn "Credential Guard" "Not enabled -- requires VBS-capable hardware"
}

# --- AppLocker / WDAC ---
$appLocker = Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue
if ($appLocker -and $appLocker.RuleCollections.Count -gt 0) {
    $ruleCount = ($appLocker.RuleCollections | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    ok "AppLocker" "Active ($ruleCount rules configured)"
} else {
    $wdacKey = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" `
        -Name VulnerableDriverBlocklistEnable -ErrorAction SilentlyContinue)
    if ($wdacKey) {
        info "AppLocker / WDAC" "No AppLocker rules; WDAC driver blocklist active"
    } else {
        warn "AppLocker / WDAC" "No application control policy configured"
    }
}

# ============================================================
# 2. PRIVACY & TELEMETRY
# ============================================================
Print-Section "2. Privacy & Telemetry"

# --- Telemetry ---
$telVal = $null
foreach ($telKey in @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
)) {
    $v = (Get-ItemProperty -Path $telKey -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry
    if ($null -ne $v) { $telVal = $v; break }
}
if ($null -eq $telVal) {
    warn "Telemetry" "No policy set (default: Full)"
} elseif ($telVal -eq 0) {
    ok "Telemetry" "Disabled (Security level)"
} elseif ($telVal -eq 1) {
    ok "Telemetry" "Basic / Required only"
} else {
    warn "Telemetry" "Level $telVal -- consider reducing to 1"
}

# --- Advertising ID ---
$advId = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
    -Name Enabled -ErrorAction SilentlyContinue).Enabled
if ($advId -eq 0) {
    ok "Advertising ID" "Disabled"
} else {
    fail "Advertising ID" "Enabled"
    Register-Fix "Advertising ID" "Disable advertising ID" {
        $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        Set-ItemProperty $p -Name Enabled -Value 0 -Type DWord -Force
    }
}

# --- Activity History ---
$actHist = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
    -Name PublishUserActivities -ErrorAction SilentlyContinue).PublishUserActivities
if ($actHist -eq 0) {
    ok "Activity History" "Disabled"
} else {
    warn "Activity History" "Enabled or no policy -- check Settings > Privacy > Activity History"
}

# --- Cortana ---
$cortana = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
    -Name AllowCortana -ErrorAction SilentlyContinue).AllowCortana
if ($cortana -eq 0) {
    ok "Cortana" "Disabled by policy"
} elseif ($cortana -eq 1) {
    warn "Cortana" "Enabled by policy"
} else {
    info "Cortana" "No policy set (default enabled)"
}

# --- Location tracking ---
$locKey = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
    -Name DisableLocation -ErrorAction SilentlyContinue).DisableLocation
if ($locKey -eq 1) {
    ok "Location Tracking" "Disabled by policy"
} else {
    $locUser = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" `
        -Name Value -ErrorAction SilentlyContinue).Value
    if ($locUser -eq "Deny") {
        ok "Location Tracking" "Denied by user"
    } else {
        warn "Location Tracking" "Allowed -- check Settings > Privacy > Location"
    }
}

# --- Diagnostic data (feedback) ---
$diagFreq = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" `
    -Name NumberOfSIUFInPeriod -ErrorAction SilentlyContinue).NumberOfSIUFInPeriod
if ($diagFreq -eq 0) {
    ok "Feedback Frequency" "Disabled"
} else {
    info "Feedback Frequency" "Not suppressed -- check Settings > Privacy > Diagnostics"
}

# ============================================================
# 3. SHARING & REMOTE ACCESS
# ============================================================
Print-Section "3. Sharing & Remote Access"

# --- Remote Desktop ---
$rdpVal = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
if ($rdpVal -eq 1) {
    ok "Remote Desktop (RDP)" "Disabled"
} else {
    fail "Remote Desktop (RDP)" "Enabled"
    Register-Fix "Remote Desktop (RDP)" "Disable Remote Desktop" {
        Set-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 1 -Type DWord -Force
        Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    }
}

# --- RDP NLA (Network Level Authentication) ---
$nlaDep = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name UserAuthentication -ErrorAction SilentlyContinue).UserAuthentication
if ($rdpVal -ne 1) {
    if ($nlaDep -eq 1) {
        ok "RDP NLA" "Required (Network Level Authentication)"
    } else {
        fail "RDP NLA" "Not required -- anyone can connect without pre-auth"
        Register-Fix "RDP NLA" "Enforce NLA for RDP connections" {
            Set-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                -Name UserAuthentication -Value 1 -Type DWord -Force
        }
    }
}

# --- WinRM ---
$winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
if ($winrm -and $winrm.Status -eq 'Running') {
    fail "WinRM (Remote Management)" "Running"
    Register-Fix "WinRM" "Stop and disable WinRM" {
        Stop-Service WinRM -Force
        Set-Service  WinRM -StartupType Disabled
    }
} else {
    ok "WinRM (Remote Management)" "Stopped / Disabled"
}

# --- Remote Registry ---
$remReg = Get-Service -Name RemoteRegistry -ErrorAction SilentlyContinue
if ($remReg -and $remReg.Status -eq 'Running') {
    fail "Remote Registry" "Running"
    Register-Fix "Remote Registry" "Disable Remote Registry" {
        Stop-Service RemoteRegistry -Force
        Set-Service  RemoteRegistry -StartupType Disabled
    }
} else {
    ok "Remote Registry" "Stopped / Disabled"
}

# --- SMB ---
$smbSvc = Get-Service -Name LanmanServer -ErrorAction SilentlyContinue
if ($smbSvc -and $smbSvc.Status -eq 'Running') {
    warn "File & Printer Sharing (SMB)" "LanmanServer running -- verify intentional"
} else {
    ok "File & Printer Sharing (SMB)" "Disabled"
}

# --- SMB1 (EternalBlue vuln) ---
$smb1 = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
if ($smb1) {
    if ($smb1.EnableSMB1Protocol) {
        fail "SMB1 Protocol" "Enabled -- CRITICAL vulnerability (EternalBlue)"
        Register-Fix "SMB1 Protocol" "Disable SMB1 protocol" {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        }
    } else {
        ok "SMB1 Protocol" "Disabled"
    }
} else {
    info "SMB1 Protocol" "Cannot query SMB configuration"
}

# --- Custom Shares ---
$shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^\w+\$$' }
if ($shares) {
    $shareNames = ($shares | Select-Object -ExpandProperty Name) -join ', '
    warn "Custom SMB Shares" "$($shares.Count) share(s): $shareNames"
} else {
    ok "Custom SMB Shares" "None (only default admin shares)"
}

# ============================================================
# 4. SYSTEM SERVICES
# ============================================================
Print-Section "4. System Services"

$riskyServices = @(
    @{ Name = "Telnet";         Display = "Telnet"                        },
    @{ Name = "simptcp";        Display = "Simple TCP/IP Services"        },
    @{ Name = "snmp";           Display = "SNMP Service"                  },
    @{ Name = "tftp";           Display = "TFTP Client"                   },
    @{ Name = "FtpSvc";         Display = "FTP Server (IIS)"              },
    @{ Name = "IISADMIN";       Display = "IIS Admin Service"             },
    @{ Name = "W3SVC";          Display = "World Wide Web Publishing"     },
    @{ Name = "RasAuto";        Display = "Remote Access Auto-Connection" },
    @{ Name = "XboxGipSvc";     Display = "Xbox Accessory Management"     },
    @{ Name = "XblGameSave";    Display = "Xbox Live Game Save"           },
    @{ Name = "XboxNetApiSvc";  Display = "Xbox Live Networking"          },
    @{ Name = "WMPNetworkSvc";  Display = "Windows Media Player Sharing"  },
    @{ Name = "Spooler";        Display = "Print Spooler"                 }
)

foreach ($svc in $riskyServices) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        $svcName    = $svc.Name
        $svcDisplay = $svc.Display
        if ($s.Status -eq 'Running') {
            if ($svc.Name -eq "Spooler") {
                warn $svcDisplay "Running -- disable if no printer is used (PrintNightmare risk)"
            } else {
                fail $svcDisplay "Running -- disable if not needed"
                Register-Fix $svcDisplay "Stop and disable $svcDisplay" {
                    Stop-Service $svcName -Force -ErrorAction SilentlyContinue
                    Set-Service  $svcName -StartupType Disabled
                }
            }
        } else {
            ok $svcDisplay "Stopped ($($s.StartType))"
        }
    } else {
        info $svc.Display "Not installed"
    }
}

# ============================================================
# 5. NETWORK & LISTENING PORTS
# ============================================================
Print-Section "5. Network & Listening Ports"

Write-Color "Open listening ports (TCP):" -Color Green
$tcpListeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort,
        @{ N='Process'; E={ (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name } }
if ($tcpListeners) {
    $tcpListeners | Format-Table -AutoSize | Out-String | Write-Host
} else {
    Write-Host "  No open TCP listening ports found."
}

Write-Color "Open listening ports (UDP):" -Color Green
$udpListeners = Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
    Sort-Object LocalPort |
    Select-Object -First 20 LocalAddress, LocalPort,
        @{ N='Process'; E={ (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name } }
if ($udpListeners) {
    $udpListeners | Format-Table -AutoSize | Out-String | Write-Host
} else {
    Write-Host "  No open UDP endpoints found."
}

# --- DNS over HTTPS ---
$dohKey = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" `
    -Name EnableAutoDoh -ErrorAction SilentlyContinue).EnableAutoDoh
if ($dohKey -eq 2) {
    ok "DNS over HTTPS (DoH)" "Enabled"
} else {
    warn "DNS over HTTPS (DoH)" "Not enabled -- DNS queries are unencrypted"
    Register-Fix "DNS over HTTPS" "Enable DNS over HTTPS (DoH)" {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" `
            -Name EnableAutoDoh -Value 2 -Type DWord -Force
    }
}

# ============================================================
# 6. USERS & PRIVILEGES
# ============================================================
Print-Section "6. Users & Privileges"

# --- Guest account ---
$guest = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
if ($guest -and $guest.Enabled) {
    fail "Guest Account" "Enabled"
    Register-Fix "Guest Account" "Disable Guest account" { Disable-LocalUser -Name "Guest" }
} else {
    ok "Guest Account" "Disabled"
}

# --- Built-in Administrator ---
$builtinAdmin = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID -like 'S-1-5-*-500' }
if ($builtinAdmin -and $builtinAdmin.Enabled) {
    warn "Built-in Administrator" "Enabled -- consider disabling or renaming"
} else {
    ok "Built-in Administrator" "Disabled"
}

# --- Accounts with empty/no password ---
$emptyPwUsers = Get-LocalUser -ErrorAction SilentlyContinue |
    Where-Object { $_.Enabled -and $_.PasswordRequired -eq $false }
if ($emptyPwUsers) {
    $names = ($emptyPwUsers | Select-Object -ExpandProperty Name) -join ', '
    fail "Empty Password Accounts" "Found: $names"
    Register-Fix "Empty Password Accounts" "Enforce password requirement for accounts without password" {
        foreach ($u in (Get-LocalUser | Where-Object { $_.Enabled -and $_.PasswordRequired -eq $false })) {
            Set-LocalUser -Name $u.Name -PasswordRequired $true
        }
    }
} else {
    ok "Empty Password Accounts" "None found"
}

# --- Password policy ---
$netAccts  = net accounts 2>&1
$maxPwLine = $netAccts | Select-String "Maximum password age"
if ($maxPwLine) {
    $maxPwAge = ($maxPwLine.ToString() -replace '\D','').Trim()
    if ($maxPwAge -match '^\d+$') {
        $maxDays = [int]$maxPwAge
        if ($maxDays -le 90)    { ok   "Max Password Age" "$maxDays days" }
        elseif ($maxDays -le 180) { warn "Max Password Age" "$maxDays days (recommend <= 90)" }
        else                    { fail "Max Password Age" "$maxDays days -- too long" }
    } else { info "Max Password Age" "Cannot parse" }
}

$minPwLine = $netAccts | Select-String "Minimum password length"
if ($minPwLine) {
    $minLen = ($minPwLine.ToString() -replace '\D','').Trim()
    if ($minLen -match '^\d+$') {
        $minL = [int]$minLen
        if ($minL -ge 12)     { ok   "Min Password Length" "$minL characters" }
        elseif ($minL -ge 8)  { warn "Min Password Length" "$minL characters (recommend >= 12)" }
        else                  { fail "Min Password Length" "$minL characters -- too short" }
    }
}

$lockLine = $netAccts | Select-String "Lockout threshold"
if ($lockLine) {
    $lockVal = ($lockLine.ToString() -replace '\D','').Trim()
    if ($lockVal -match '^\d+$' -and [int]$lockVal -gt 0) {
        ok "Account Lockout" "After $lockVal failed attempts"
    } else {
        fail "Account Lockout" "Not configured"
    }
}

# --- Audit Policy (logowanie zdarzen) ---
$auditLogon = auditpol /get /subcategory:"Logon" 2>$null
if ($auditLogon -match "Success and Failure|Failure") {
    ok "Audit: Logon Events" "Failure events logged"
} else {
    warn "Audit: Logon Events" "Logon failures not audited"
    Register-Fix "Audit: Logon Events" "Enable audit of failed logons" {
        auditpol /set /subcategory:"Logon" /failure:enable | Out-Null
    }
}

$auditPriv = auditpol /get /subcategory:"Sensitive Privilege Use" 2>$null
if ($auditPriv -match "Success and Failure|Success") {
    ok "Audit: Privilege Use" "Logged"
} else {
    warn "Audit: Privilege Use" "Sensitive privilege use not audited"
}

# --- Local Admins list ---
Write-Host ""
Write-Color "Local Administrator group members:" -Color Green
$admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
if ($admins) {
    $admins | ForEach-Object { Write-Host "  - $($_.Name)" }
    if (($admins | Measure-Object).Count -gt 2) {
        warn "Admin Count" "More than 2 local admins -- review above list"
    }
} else {
    Write-Host "  (cannot enumerate)"
}
Write-Host ""

if ($isAdmin) { info "Current Session" "Running as Administrator" }
else          { info "Current Session" "Running as standard user"  }

# ============================================================
# 7. STARTUP ITEMS & SCHEDULED TASKS
# ============================================================
Print-Section "7. Startup Items & Scheduled Tasks"

$startupKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)

$totalStartup = 0
foreach ($key in $startupKeys) {
    $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    if ($entries) {
        $props = $entries.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }
        $count = ($props | Measure-Object).Count
        if ($count -gt 0) {
            Write-Color "Registry: $key" -Color DarkGray
            $props | ForEach-Object { Write-Host "  $($_.Name) = $($_.Value)" }
            $totalStartup += $count
        }
    }
}

if ($totalStartup -gt 0) {
    warn "Registry Startup Items" "$totalStartup item(s) -- review list above"
} else {
    ok "Registry Startup Items" "None found in common Run keys"
}

$startupFolder = [System.Environment]::GetFolderPath('CommonStartup')
$startupFiles  = Get-ChildItem -Path $startupFolder -ErrorAction SilentlyContinue
if ($startupFiles) {
    $startupCount = ($startupFiles | Measure-Object).Count
    warn "Startup Folder" "$startupCount item(s) in $startupFolder"
    $startupFiles | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    ok "Startup Folder" "Empty"
}

# --- Scheduled Tasks (non-Microsoft) ---
$suspectTasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object {
        $_.TaskPath -notlike "\Microsoft\*" -and
        $_.State -ne 'Disabled' -and
        $_.TaskPath -ne "\"
    } |
    Select-Object -First 20

if ($suspectTasks) {
    $taskCount = ($suspectTasks | Measure-Object).Count
    Write-Host ""
    Write-Color "Non-Microsoft scheduled tasks (enabled):" -Color Green
    $suspectTasks | ForEach-Object { Write-Host "  [$($_.State)] $($_.TaskPath)$($_.TaskName)" }
    warn "Scheduled Tasks" "$taskCount non-Microsoft task(s) found -- review above"
} else {
    ok "Scheduled Tasks" "No non-Microsoft scheduled tasks found"
}

# ============================================================
# 8. SSH HARDENING
# ============================================================
Print-Section "8. SSH Hardening"

$sshd = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($sshd -and $sshd.Status -eq 'Running') {
    warn "OpenSSH Server (sshd)" "Running -- checking configuration..."

    $sshdConfig = "$env:ProgramData\ssh\sshd_config"
    if (Test-Path $sshdConfig) {
        $cfg = Get-Content $sshdConfig -ErrorAction SilentlyContinue

        $permitRootLine = $cfg | Select-String "^PermitRootLogin"
        $permitRoot     = if ($permitRootLine) { $permitRootLine.ToString().Trim() } else { "" }
        if ($permitRoot -match "no|prohibit-password") { ok "SSH: PermitRootLogin" $permitRoot }
        elseif ($permitRoot) { fail "SSH: PermitRootLogin" "$permitRoot (should be no)" }
        else { warn "SSH: PermitRootLogin" "Not set (check sshd_config)" }

        $passAuthLine = $cfg | Select-String "^PasswordAuthentication"
        $passAuth     = if ($passAuthLine) { $passAuthLine.ToString().Trim() } else { "" }
        if ($passAuth -match "no") { ok "SSH: PasswordAuthentication" "Disabled" }
        elseif ($passAuth -match "yes") {
            fail "SSH: PasswordAuthentication" "Enabled (use keys)"
            Register-Fix "SSH: PasswordAuthentication" "Disable SSH password login" {
                $c = Get-Content "$env:ProgramData\ssh\sshd_config"
                $c = $c -replace '^PasswordAuthentication yes','PasswordAuthentication no'
                $c | Set-Content "$env:ProgramData\ssh\sshd_config"
                Restart-Service sshd
            }
        } else { warn "SSH: PasswordAuthentication" "Not set (default: yes)" }

        $maxAuthLine = $cfg | Select-String "^MaxAuthTries"
        $maxAuth     = if ($maxAuthLine) { ($maxAuthLine.ToString() -replace '\D','').Trim() } else { "" }
        if ($maxAuth -match '^\d+$' -and [int]$maxAuth -le 4) { ok "SSH: MaxAuthTries" "$maxAuth" }
        elseif ($maxAuth -match '^\d+$') { warn "SSH: MaxAuthTries" "$maxAuth (recommend <= 4)" }
        else { warn "SSH: MaxAuthTries" "Not set (default: 6)" }

        $graceLine = $cfg | Select-String "^LoginGraceTime"
        $grace     = if ($graceLine) { $graceLine.ToString().Trim() } else { "" }
        if ($grace) { info "SSH: LoginGraceTime" $grace }
        else        { info "SSH: LoginGraceTime" "Not set (default: 2m)" }

        $allowLine = $cfg | Select-String "^AllowUsers"
        if ($allowLine) { info "SSH: AllowUsers" $allowLine.ToString().Trim() }
        else            { info "SSH: AllowUsers" "Not set (any user can connect)" }

    } else {
        warn "SSH" "sshd_config not found at $sshdConfig"
    }
} else {
    ok "OpenSSH Server (sshd)" "Not running / Not installed"
}

# ============================================================
# 9. INSTALLED SOFTWARE
# ============================================================
Print-Section "9. Installed Software"

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$allApps = $regPaths | ForEach-Object {
    Get-ItemProperty -Path $_ -ErrorAction SilentlyContinue
} | Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName

$appCount = ($allApps | Measure-Object).Count
info "Installed Applications" "$appCount applications found"

Write-Host ""
Write-Color "Installed software list:" -Color Green
$allApps | ForEach-Object {
    Write-Host ("  " + $_.DisplayName.PadRight(50) + " " + $_.DisplayVersion)
}
Write-Host ""

# Flag known risky/legacy software
$riskyApps = @("TeamViewer", "AnyDesk", "UltraVNC", "RealVNC", "LogMeIn", "Adobe Flash", "Java 6", "Java 7", "Java 8")
foreach ($rApp in $riskyApps) {
    $found = $allApps | Where-Object { $_.DisplayName -like "*$rApp*" }
    if ($found) {
        warn "Risky Software" "$($found.DisplayName) $($found.DisplayVersion) -- review necessity"
    }
}

# ============================================================
# 10. EVENT LOG HEALTH
# ============================================================
Print-Section "10. Event Log Health"

$logsToCheck = @("Security", "System", "Application")
foreach ($logName in $logsToCheck) {
    $log = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
    if ($log) {
        if ($log.IsEnabled) {
            $sizeMB = [math]::Round($log.FileSize / 1MB, 1)
            $maxMB  = [math]::Round($log.MaximumSizeInBytes / 1MB, 0)
            ok "Event Log: $logName" "Enabled ($sizeMB MB / $maxMB MB max)"
        } else {
            fail "Event Log: $logName" "Disabled"
            Register-Fix "Event Log: $logName" "Enable $logName event log" {
                $l = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration($logName)
                $l.IsEnabled = $true
                $l.SaveChanges()
            }
        }
    } else {
        info "Event Log: $logName" "Cannot query"
    }
}

# --- Recent failed logons ---
$failedLogons = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625 } `
    -MaxEvents 10 -ErrorAction SilentlyContinue
if ($failedLogons) {
    $failCount = ($failedLogons | Measure-Object).Count
    warn "Recent Failed Logons" "$failCount failed logon events in Security log (last 10)"
} else {
    ok "Recent Failed Logons" "No recent failed logon events found"
}

# ============================================================
# 11. SECURITY SCORE
# ============================================================
Print-Section "11. Security Score"

$total = $script:PASS_COUNT + $script:WARN_COUNT + $script:FAIL_COUNT
$score = if ($total -eq 0) { 0 } else { [int](($script:PASS_COUNT * 100 + $script:WARN_COUNT * 50) / $total) }

Write-Host ("Security Score".PadRight(36) + "$score/100")

$risk      = if ($score -ge 80) { "Low" } elseif ($score -ge 50) { "Medium" } else { "High" }
$riskColor = if ($score -ge 80) { [ConsoleColor]::Green } elseif ($score -ge 50) { [ConsoleColor]::Yellow } else { [ConsoleColor]::Red }

Write-Host -NoNewline "Risk Level:".PadRight(36)
Write-Color $risk -Color $riskColor
Write-Host ""
Write-Host ("Passed".PadRight(36)   + $script:PASS_COUNT)
Write-Host ("Warnings".PadRight(36) + $script:WARN_COUNT)
Write-Host ("Failures".PadRight(36) + $script:FAIL_COUNT)

# ============================================================
# REPORT GENERATION
# ============================================================
Write-Host ""
Write-Color "Generating reports..." -Color Cyan

$reportData = @()
if (Test-Path $DATA_FILE) {
    $reportData = Import-Csv -Path $DATA_FILE -Delimiter "`t" -Encoding UTF8
}

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
if (-not $scriptDir) { $scriptDir = $PWD.Path }

# --- JSON ---
$jsonPath = Join-Path $scriptDir "windows_security_report.json"
@{ 
    generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    score     = $score
    risk      = $risk
    passed    = $script:PASS_COUNT
    warnings  = $script:WARN_COUNT
    failures  = $script:FAIL_COUNT
    checks    = $reportData
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Color "  [OK] JSON: $jsonPath" -Color Green

# --- HTML ---
$htmlPath    = Join-Path $scriptDir "windows_security_report.html"
$riskClass   = if ($score -ge 80) { "low" } elseif ($score -ge 50) { "med" } else { "high" }
$genDate     = Get-Date -Format "yyyy-MM-dd HH:mm"

$rows = $reportData | ForEach-Object {
    $rowBg = switch ($_.status) {
        'OK'   { '#1a3326' }; 'WARN' { '#332d00' }; 'FAIL' { '#331a1a' }; default { '#1e1e1e' }
    }
    $badge = switch ($_.status) {
        'OK'   { '<span class="ok">OK</span>'     }
        'WARN' { '<span class="warn">WARN</span>' }
        'FAIL' { '<span class="fail">FAIL</span>' }
        default{ '<span class="info">INFO</span>' }
    }
    "<tr style='background:$rowBg'><td>$($_.label)</td><td>$badge</td><td>$($_.detail)</td></tr>"
}
$rowsHtml = $rows -join "`n"

@"
<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<title>Windows Security Report</title>
<style>
  *     { box-sizing:border-box; margin:0; padding:0; }
  body  { font-family:Consolas,'Courier New',monospace; background:#0d0d0d; color:#e0e0e0; padding:2rem; }
  h1    { color:#81d4fa; border-bottom:1px solid #333; padding-bottom:.5rem; margin-bottom:.5rem; }
  h2    { color:#ffeb3b; margin:1.5rem 0 .4rem; }
  p     { color:#aaa; font-size:.9rem; margin-bottom:.5rem; }
  table { border-collapse:collapse; width:100%; margin-top:.5rem; }
  th    { background:#1a1a1a; color:#81d4fa; padding:.5rem 1rem; text-align:left; border-bottom:2px solid #333; }
  td    { padding:.35rem 1rem; border-bottom:1px solid #222; font-size:.88rem; vertical-align:top; }
  .score-box { display:inline-block; margin:.5rem 0 1rem; }
  .score     { font-size:3rem; font-weight:bold; line-height:1; }
  .low       { color:#4caf50; }
  .med       { color:#ffeb3b; }
  .high      { color:#f44336; }
  .ok        { color:#4caf50; font-weight:bold; }
  .warn      { color:#ffeb3b; font-weight:bold; }
  .fail      { color:#f44336; font-weight:bold; }
  .info      { color:#9e9e9e; font-weight:bold; }
  .pills     { display:flex; gap:1.5rem; margin:.5rem 0 1rem; flex-wrap:wrap; }
  .pill      { padding:.3rem .8rem; border-radius:4px; font-weight:bold; font-size:.9rem; }
  .p-ok      { background:#1a3326; color:#4caf50; }
  .p-warn    { background:#332d00; color:#ffeb3b; }
  .p-fail    { background:#331a1a; color:#f44336; }
</style>
</head>
<body>
<h1>Windows Security / Audit Report</h1>
<p>$AUTHOR &nbsp;|&nbsp; $VERSION &nbsp;|&nbsp; $genDate</p>
<h2>Security Score</h2>
<div class="score-box">
  <div class="score $riskClass">$score<span style="font-size:1.5rem">/100</span></div>
  <div style="color:#aaa;font-size:.9rem;margin-top:.2rem">Risk Level: <span class="$riskClass">$risk</span></div>
</div>
<div class="pills">
  <span class="pill p-ok">Passed: $($script:PASS_COUNT)</span>
  <span class="pill p-warn">Warnings: $($script:WARN_COUNT)</span>
  <span class="pill p-fail">Failures: $($script:FAIL_COUNT)</span>
</div>
<h2>Detailed Results</h2>
<table>
<tr><th style="width:38%">Check</th><th style="width:8%">Status</th><th>Detail</th></tr>
$rowsHtml
</table>
</body>
</html>
"@ | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Color "  [OK] HTML: $htmlPath" -Color Green

# ============================================================
# AUTO-FIX
# ============================================================
Run-Fixes

# ============================================================
# END
# ============================================================
Write-Host ""
Write-Color $LINE -Color Cyan
Write-Color "Audit completed. Check report in: $scriptDir" -Color Cyan
Write-Color $LINE -Color Cyan
Write-Host ""

if (Test-Path $DATA_FILE) { Remove-Item $DATA_FILE -Force -ErrorAction SilentlyContinue }