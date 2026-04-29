<#
.SYNOPSIS
    GitHub-ZH V30 + Auto-Elevation V6 (Fortified Merged Edition)
    Automated Native Extension Deployment with Advanced Elevation & Dynamic Path Resolution
    Author: Lightspeed Sharing (YT) | Project: Cotton059/Light-Help | Developer: Lightspeed Sharing (YT) | Project : Light-Help (GitHub)
#>

# ==========================================
# [Phase 1: Process Mutex & Execution Guard]
# ==========================================
if ($env:__LIGHTHELP_RUNNING -eq "1" -or $env:__ELEVATED -eq "1") {
    # Skip if already running or currently elevating
} else {
    $env:__LIGHTHELP_RUNNING = "1"
}

if ($Host.Name -ne "ConsoleHost") {
    Write-Host "[!] WARNING: Non-standard Host Environment ($($Host.Name)). Continuing..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

# ==========================================
# [Phase 2: Advanced Auto-Elevation Engine]
# ==========================================
function Write-ElevLog {
    param ([string]$Message)
    try {
        $logPath = Join-Path $env:TEMP "github_zh_elevation.log"
        $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $logPath -Value "[$time] $Message"
    } catch {}
}

function Get-CurrentShell {
    try { if ($PSVersionTable.PSEdition -eq "Core") { "pwsh" } else { "powershell" } } catch { "powershell" }
}

$isAdmin = try {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { $false }

if (-not $isAdmin) {
    Write-ElevLog "User is not elevated. Initiating elevation sequence."
    
    $ScriptPath = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($ScriptPath)) { $ScriptPath = $MyInvocation.MyCommand.Path }

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        Write-Host "[!] FATAL: Memory execution detected or path unknown." -ForegroundColor Red
        Write-Host "[!] ACTION REQUIRED: Please save as .ps1 and run." -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit
    }

    $shell = Get-CurrentShell
    $exe = if ($shell -eq "pwsh") { "pwsh.exe" } else { "powershell.exe" }

    if ($exe -eq "pwsh.exe" -and -not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
        $exe = "powershell.exe"
        Write-ElevLog "Fallback to powershell.exe triggered."
    }

    Write-Host "[*] Requesting Administrator privileges for system-wide installation..." -ForegroundColor Yellow
    
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"")
    $env:__ELEVATED = "1"
    $env:__LIGHTHELP_RUNNING = "0" # Clear mutex for the new process

    try {
        Start-Process -FilePath $exe -ArgumentList $argList -Verb RunAs -WorkingDirectory (Get-Location)
        Write-ElevLog "Elevation process launched successfully."
    } catch {
        Write-ElevLog "Elevation failed or cancelled by user: $_"
        Write-Host "`n[!] Elevation Cancelled or Failed. Administrator rights are required for HKLM registry modifications." -ForegroundColor Red
    }
    
    Write-Host "`n[INFO] Relaunching as Administrator..." -ForegroundColor Cyan
    Read-Host "Press Enter to close this window..."
    exit # Exit the non-elevated script immediately
} else {
    Write-ElevLog "Running with Administrator privileges."
}

# ==========================================
# [Phase 3: Core Deployment & Terminal UI]
# ==========================================
try {
    $exitScript = $false
    while (-not $exitScript) {
        
        [Console]::ForegroundColor = "Cyan"
        [Console]::BackgroundColor = "Black"
        Clear-Host

        Write-Host " +----------------------------------------------------------+"
        Write-Host " |                                                          |"
        Write-Host " |       >>> GITHUB-ZH AUTOMATION (V1.3 STABLE) <<<         |"
        Write-Host " |               [Elevated Admin Mode]                      |"
        Write-Host " +----------------------------------------------------------+"
        Write-Host " |  Author: Lightspeed Sharing (YT)                         |"
        Write-Host " |  Project: Cotton059/Light-Help                           |"
        Write-Host " |  Function: GitHub Chinese Plugin Quick Setup             |"
        Write-Host " +----------------------------------------------------------+"
        Write-Host ""

        # [Core Parameters - Extension Configs]
        $ChromeExtID = "emoeojemgbjcogiodobkpeohoailphgg"
        $ChromeStoreUrl = "https://chromewebstore.google.com/detail/github-%E4%B8%AD%E6%96%87%E6%B1%89%E5%8C%96%E6%8F%92%E4%BB%B6/$ChromeExtID"
        $ChromePayload = "$ChromeExtID;https://clients2.google.com/service/update2/crx"
        
        $EdgeExtID = "onlodfoebaobhmlhgcbddjngjbkdbfaj"
        $EdgeStoreUrl = "https://microsoftedge.microsoft.com/addons/detail/githubcn/$EdgeExtID"
        $EdgePayload = "$EdgeExtID;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
        
        # Standard Native Paths
        $RegChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
        $RegEdge   = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
        $RegOpera  = "HKLM:\SOFTWARE\Policies\Opera Software\Opera Stable\ExtensionInstallForcelist"
        $RegQQ     = "HKLM:\SOFTWARE\Policies\Tencent\QQBrowser\ExtensionInstallForcelist"
        $RegSogou  = "HKLM:\SOFTWARE\Policies\SogouExplorer\ExtensionInstallForcelist"
        $Reg360    = "HKLM:\SOFTWARE\Policies\360se6\ExtensionInstallForcelist"

        function Get-BrowserPath ($ExeName, $FallbackPath) {
            $RegAppPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName"
            if (Test-Path $RegAppPath) {
                try {
                    $item = Get-ItemProperty -Path $RegAppPath -ErrorAction Stop
                    $Path = $item.'(default)'
                    if ([System.IO.File]::Exists($Path)) { return $Path }
                } catch { }
            }
            $ExpandedFallback = [Environment]::ExpandEnvironmentVariables($FallbackPath)
            if ([System.IO.File]::Exists($ExpandedFallback)) { return $ExpandedFallback }
            return $null
        }

        function Install-ChromiumPolicy ($RegPath, $Payload) {
            if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
            $existing = Get-Item $RegPath
            $nextId = 1
            if ($existing -and $existing.Property -and $existing.Property.Count -gt 0) {
                $ids = $existing.Property | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
                if ($ids) { $nextId = ($ids | Measure-Object -Maximum).Maximum + 1 }
            }
            New-ItemProperty -Path $RegPath -Name $nextId.ToString() -Value $Payload -PropertyType String -Force | Out-Null
            Write-Host "[+] Registry injected successfully (Policy Path: $RegPath | ID: $nextId)" -ForegroundColor Green
        }

        function Deploy-Target ($Name, $ExeName, $FallbackPath, $RegPath, $Payload, $StoreUrl) {
            Write-Host "`n[>>> TARGET: $Name <<<]" -ForegroundColor Magenta
            $PhysicalPath = Get-BrowserPath -ExeName $ExeName -FallbackPath $FallbackPath
            if (-not $PhysicalPath) {
                Write-Host "[!] $Name not found on this system. Skipping..." -ForegroundColor DarkYellow
                return
            }
            Write-Host "[*] Located physical path: $PhysicalPath" -ForegroundColor DarkCyan
            Install-ChromiumPolicy -RegPath $RegPath -Payload $Payload
            Write-Host "[*] Triggering $Name to verify extension installation..." -ForegroundColor Cyan
            Start-Process -FilePath $PhysicalPath -ArgumentList $StoreUrl -ErrorAction SilentlyContinue
        }

        function Uninstall-GitHubExtensions {
            Write-Host "`n[*] Initiating Dual-Layer Registry Cleanup..." -ForegroundColor Cyan
            
            $targetIDs = @($ChromeExtID, $EdgeExtID)
            $Roots = @("HKLM:\SOFTWARE\Policies", "HKCU:\SOFTWARE\Policies")
            
            $BrowserSubKeys = @(
                "Google\Chrome",
                "Microsoft\Edge",
                "Opera Software\Opera Stable",
                "Tencent\QQBrowser",
                "SogouExplorer",
                "360se6",
                "BraveSoftware\Brave",
                "Vivaldi",
                "Opera",
                "Chromium"
            )

            $cleanupCount = 0

            foreach ($root in $Roots) {
                foreach ($subKey in $BrowserSubKeys) {
                    $basePath = "$root\$subKey"
                    
                    # Layer 1 Cleanup: ExtensionSettings Payload
                    if (Test-Path $basePath) {
                        $settings = Get-ItemProperty -Path $basePath -Name "ExtensionSettings" -ErrorAction SilentlyContinue
                        if ($settings -and $settings.ExtensionSettings) {
                            foreach ($id in $targetIDs) {
                                if ($settings.ExtensionSettings -match $id) {
                                    Remove-ItemProperty -Path $basePath -Name "ExtensionSettings" -Force -ErrorAction SilentlyContinue
                                    Write-Host "  -> [Cleaned] Layer 1 (Settings) in $subKey" -ForegroundColor DarkCyan
                                    $cleanupCount++
                                }
                            }
                        }
                    }

                    # Layer 2 Cleanup: ExtensionInstallForcelist
                    $forcePath = "$basePath\ExtensionInstallForcelist"
                    if (Test-Path $forcePath) {
                        $props = Get-ItemProperty -Path $forcePath -ErrorAction SilentlyContinue
                        if ($props) {
                            foreach ($prop in $props.psobject.properties) {
                                if ($prop.Name -match '^\d+$') {
                                    foreach ($id in $targetIDs) {
                                        if ($prop.Value -match $id) {
                                            Remove-ItemProperty -Path $forcePath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                            Write-Host "  -> [Cleaned] Layer 2 (Forcelist ID: $($prop.Name)) in $subKey" -ForegroundColor DarkCyan
                                            $cleanupCount++
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if ($cleanupCount -gt 0) {
                Write-Host "[+] Registry Cleanup Complete. Removed $cleanupCount policies." -ForegroundColor Green
            } else {
                Write-Host "[-] No GitHub translation extension policies found to clean." -ForegroundColor DarkGray
            }
        }

        $AvailableBrowsers = @{}
        $menuIndex = 1

        $hasEdge = Get-BrowserPath "msedge.exe" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
        $hasChrome = Get-BrowserPath "chrome.exe" "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
        $hasQQ = Get-BrowserPath "QQBrowser.exe" "%ProgramFiles%\Tencent\QQBrowser\QQBrowser.exe"
        $hasSogou = Get-BrowserPath "SogouExplorer.exe" "%ProgramFiles%\Sogou\SogouExplorer\SogouExplorer.exe"
        $hasOpera = Get-BrowserPath "opera.exe" "%LocalAppData%\Programs\Opera\opera.exe"
        $has360 = Get-BrowserPath "360se.exe" "%AppData%\360se6\Application\360se.exe"

        Write-Host "Select target environment (Detected Browsers Only):"

        if ($hasEdge) { Write-Host "$menuIndex. Microsoft Edge"; $AvailableBrowsers[$menuIndex.ToString()] = "Edge"; $menuIndex++ }
        if ($hasChrome) { Write-Host "$menuIndex. Google Chrome"; $AvailableBrowsers[$menuIndex.ToString()] = "Chrome"; $menuIndex++ }
        if ($hasQQ) { Write-Host "$menuIndex. QQ Browser"; $AvailableBrowsers[$menuIndex.ToString()] = "QQ"; $menuIndex++ }
        if ($hasSogou) { Write-Host "$menuIndex. Sogou Explorer"; $AvailableBrowsers[$menuIndex.ToString()] = "Sogou"; $menuIndex++ }
        if ($hasOpera) { Write-Host "$menuIndex. Opera Browser"; $AvailableBrowsers[$menuIndex.ToString()] = "Opera"; $menuIndex++ }
        if ($has360) { Write-Host "$menuIndex. 360 Safe Browser"; $AvailableBrowsers[$menuIndex.ToString()] = "360"; $menuIndex++ }

        if ($AvailableBrowsers.Count -eq 0) {
            Write-Host "[!] No supported browsers detected on this system." -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            $exitScript = $true
            continue
        }

        # --- Core Logic Adjustment Section (Restore Uninstall Menu, Hide One-Click Install) ---
        $allOption = $menuIndex 
        # Write-Host "$allOption. Deploy to ALL Detected Browsers" # Keep Hidden
        
        Write-Host "U. Uninstall Extension (Dual-Layer Clean)" -ForegroundColor Yellow
        
        $exitOption = $menuIndex 
        Write-Host "$exitOption. Exit"
        Write-Host ""
        
        $choice = Read-Host "Enter your routing choice (1-$($menuIndex - 1), U, or $exitOption)"
        Write-Host "================================================================"

        if ([string]::IsNullOrWhiteSpace($choice)) { continue }

        if ($choice -eq $exitOption.ToString()) { $exitScript = $true; continue }

        if ($choice.ToUpper() -eq "U") {
            Uninstall-GitHubExtensions
            Read-Host "`nPress Enter to return to menu..."
            continue
        }

        $isAll = $false # Force Disable One-Click Deployment Logic
        $targetID = $null
        if ($AvailableBrowsers.ContainsKey($choice)) {
            $targetID = $AvailableBrowsers[$choice]
        }
        # --- End of Logic Adjustments ---

        if ($targetID -eq "Edge") { Deploy-Target "Microsoft Edge" "msedge.exe" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" $RegEdge $EdgePayload $EdgeStoreUrl }
        if ($targetID -eq "Chrome") { Deploy-Target "Google Chrome" "chrome.exe" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" $RegChrome $ChromePayload $ChromeStoreUrl }
        if ($targetID -eq "QQ") { Install-ChromiumPolicy -RegPath $RegQQ -Payload $ChromePayload; Deploy-Target "QQ Browser" "QQBrowser.exe" "%ProgramFiles%\Tencent\QQBrowser\QQBrowser.exe" $RegChrome $ChromePayload $ChromeStoreUrl }
        if ($targetID -eq "Sogou") { Install-ChromiumPolicy -RegPath $RegSogou -Payload $ChromePayload; Deploy-Target "Sogou Explorer" "SogouExplorer.exe" "%ProgramFiles%\Sogou\SogouExplorer\SogouExplorer.exe" $RegChrome $ChromePayload $ChromeStoreUrl }
        if ($targetID -eq "Opera") { Deploy-Target "Opera Browser" "opera.exe" "%LocalAppData%\Programs\Opera\opera.exe" $RegOpera $ChromePayload $ChromeStoreUrl }
        if ($targetID -eq "360") { Install-ChromiumPolicy -RegPath $Reg360 -Payload $ChromePayload; Deploy-Target "360 Safe Browser" "360se.exe" "%AppData%\360se6\Application\360se.exe" $RegChrome $ChromePayload $ChromeStoreUrl }

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -lt $exitOption) {
            Write-Host "`n[SYSTEM] Deployment execution completed." -ForegroundColor Green
            Write-Host "=======================================================" -ForegroundColor DarkGray
            Write-Host " [OK] TASK COMPLETED!" -ForegroundColor Green
            Read-Host "Press Enter to return to menu..."
        }
    }

} catch {
    Write-Host "`n[FATAL ERROR TRAPPED]" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-ElevLog "Crash: $($_.Exception.Message)"
    Read-Host "Press Enter to exit..."
} finally {
    if ($exitScript) {
        Write-Host "`nPress any key to safely close terminal..." -ForegroundColor Cyan
        try {
            if ($Host.Name -eq "ConsoleHost") { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } else { Read-Host "Press Enter to exit" }
        } catch { Start-Sleep -Seconds 2 }
    }
    [Console]::ResetColor()
}