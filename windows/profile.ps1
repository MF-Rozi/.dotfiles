# Oh-My-Posh prompt theme
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themeFile = if ($env:POSH_THEMES_PATH) {
        Join-Path $env:POSH_THEMES_PATH "jandedobbeleer.omp.json"
    } else {
        $null
    }

    if ($themeFile -and (Test-Path $themeFile)) {
        oh-my-posh init pwsh --config $themeFile | Invoke-Expression
    }
    else {
        Write-Warning "Theme file not found. Using built-in default."
        oh-my-posh init pwsh | Invoke-Expression
    }
}
else {
    Write-Warning "Oh-My-Posh not found. Install with: winget install JanDeDobbeleer.OhMyPosh"
}

# Environment variables
$env:EDITOR = "code"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Unix-like aliases
Set-Alias -Name pwd  -Value Get-Location
Set-Alias -Name ll   -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# PSReadLine enhancements
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 10240
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Connect to Minecraft Console
Function mcconsole {
    [CmdletBinding()]
    param(
        [Parameter()] [string]$Server = "mc.mfrozi.xyz",
        [Parameter()] [string]$User = "mfrozi",
        [Parameter()] [string]$ScreenSession = "mcserver"
    )

    try {
        # Prefer native OpenSSH (key-based, no password prompt if agent is configured)
        if (Get-Command ssh -ErrorAction SilentlyContinue) {
            Write-Host "Connecting via OpenSSH to $User@$Server..." -ForegroundColor Cyan
            & ssh -t "$User@$Server" "screen -x $ScreenSession"
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "ssh exited with code $LASTEXITCODE"
            }
            return
        }

        # Fallback to plink
        if (-not (Get-Command plink -ErrorAction SilentlyContinue)) {
            Write-Error "Neither ssh nor plink found. Install OpenSSH (Settings → Optional Features) or PuTTY."
            return
        }

        Write-Warning "OpenSSH not found — falling back to plink. Consider setting up SSH keys."

        $useKey = Read-Host "Use Pageant key agent? (Y/N)"
        if ($useKey -in @('Y', 'y')) {
            plink -t -ssh "$User@$Server" screen -x $ScreenSession
        }
        else {
            $securePass = Read-Host -AsSecureString -Prompt "Enter SSH password for $User@${Server}"
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
            try {
                $plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                plink -t -ssh "$User@$Server" -pw $plainPass screen -x $ScreenSession
            }
            finally {
                # Zero out the BSTR as soon as possible
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                if ($plainPass) {
                    Remove-Variable plainPass -Force -ErrorAction SilentlyContinue
                }
                $securePass.Dispose()
                [GC]::Collect()
            }
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Connection failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to connect: $_"
    }
}
# Winget Upgrade with Admin Privileges
Function wingetupgrade {
    [CmdletBinding()]
    param(
        [Parameter()] [switch]$Force,
        [Parameter()] [string[]]$Include,
        [Parameter()] [switch]$SkipIgnoreList,
        [Parameter()] [switch]$DryRun
    )

    # --- Administrator Check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required. Launching elevated…"

        # Reconstruct all parameters for the elevated session
        $paramParts = @()
        if ($Force)          { $paramParts += '-Force' }
        if ($SkipIgnoreList) { $paramParts += '-SkipIgnoreList' }
        if ($DryRun)         { $paramParts += '-DryRun' }
        if ($Include)        { $paramParts += "-Include @('$($Include -join "','")')" }
        $paramString = $paramParts -join ' '

        $commandToRun = ". '$PROFILE'; wingetupgrade $paramString"
        $bytes = [Text.Encoding]::Unicode.GetBytes($commandToRun)
        $encodedCommand = [Convert]::ToBase64String($bytes)

        # Use pwsh (PS 7) — change to 'powershell' if you only have 5.1
        Start-Process wt -Verb RunAs -ArgumentList "-- pwsh -NoExit -EncodedCommand $encodedCommand"
        return
    }

    Write-Host "Running with Administrator privileges." -ForegroundColor Green

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget not found. Install App Installer from the Microsoft Store."
        return
    }

    $ignorelist = @(
        "LeNgocKhoa.Laragon"
        "Discord.Discord"
        "Initex.YogaDNS"
        "Spicetify.Spicetify"
    )

    Write-Host "Checking for updates…" -ForegroundColor Cyan

    # --- Parse available upgrades ---
    $idlist = [Collections.Generic.List[string]]::new()

    try {
        # Attempt structured JSON output first (winget ≥ 1.6)
        $jsonOutput = & winget upgrade --include-unknown --accept-source-agreements --output json 2>$null
        if ($jsonOutput) {
            $items = $jsonOutput | ConvertFrom-Json
            foreach ($item in $items) {
                $id = $item.PackageIdentifier
                if (-not $SkipIgnoreList -and $id -in $ignorelist) { continue }
                if ($id -and $id -notin $idlist) { $idlist.Add($id) }
            }
        }
        else { throw "empty json" }
    }
    catch {
        # Fallback: text parsing
        $updatelist = winget upgrade --include-unknown 2>&1

        # Find header line to know where data starts
        $headerIndex = ($updatelist | ForEach-Object { $_.ToString() } |
            Select-String -Pattern '^-{3,}' |
            Select-Object -First 1).LineNumber

        $idPattern = '(?<id>[A-Za-z][A-Za-z0-9-]*\.[A-Za-z0-9\.\-]+)'
        foreach ($line in $updatelist[($headerIndex)..($updatelist.Count - 1)]) {
            if ($line -match $idPattern) {
                $id = $Matches['id']
                if (-not $SkipIgnoreList -and $id -in $ignorelist) { continue }
                if ($id -notin $idlist) { $idlist.Add($id) }
            }
        }
    }

    if ($Include) {
        foreach ($pkg in $Include) {
            if ($pkg -notin $idlist) { $idlist.Add($pkg) }
        }
    }

    if ($idlist.Count -eq 0) {
        Write-Host "✓ No new software updates to install." -ForegroundColor Green
        return
    }

    Write-Host "`n--- $($idlist.Count) package(s) will be upgraded ---" -ForegroundColor Yellow
    $idlist | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }

    if ($DryRun) {
        Write-Host "`n[DRY RUN] No changes made." -ForegroundColor Magenta
        return
    }

    if (-not $Force) {
        $confirm = Read-Host "`nProceed? (Y/N)"
        if ($confirm -notin @('Y', 'y')) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }

    # --- Upgrade loop ---
    Write-Host "`n--- Starting Upgrades ---" -ForegroundColor Cyan
    $successCount = 0
    $failedPackages = [Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $idlist.Count; $i++) {
        $id = $idlist[$i]
        $percent = [math]::Round((($i + 1) / $idlist.Count) * 100)
        Write-Progress -Activity "Upgrading Packages" -Status "Processing $id ($($i + 1)/$($idlist.Count))" -PercentComplete $percent
        Write-Host "`n[$($i + 1)/$($idlist.Count)] Upgrading $id…" -ForegroundColor Cyan

        & winget upgrade --id $id --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $id" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Warning "  ✗ $id (exit $LASTEXITCODE)"
            $failedPackages.Add($id)
        }
    }

    # --- Summary ---
    $failCount = $failedPackages.Count
    Write-Host "`n$('═' * 50)" -ForegroundColor Cyan
    Write-Host "  Total: $($idlist.Count)  ✓ $successCount  ✗ $failCount" -ForegroundColor White
    if ($failCount -gt 0) {
        $failedPackages | ForEach-Object { Write-Host "    • $_" -ForegroundColor Red }
    }
    Write-Host "$('═' * 50)" -ForegroundColor Cyan

    # Log
    $logPath = Join-Path $env:TEMP "winget-upgrade-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    @"
Winget Upgrade — $(Get-Date)
Total: $($idlist.Count) | OK: $successCount | Failed: $failCount
$($idlist -join "`n")
$(if ($failCount) { "`nFailed:`n$($failedPackages -join "`n")" })
"@ | Set-Content $logPath -Encoding UTF8
    Write-Host "Log: $logPath" -ForegroundColor Gray
}
# Helper function to check for profile updates
Function Update-Profile {
    [CmdletBinding()]
    param(
        [string]$ProfileUrl = "https://raw.githubusercontent.com/MF-Rozi/.dotfiles/main/windows/profile.ps1"
    )

    try {
        $webContent = Invoke-RestMethod -Uri $ProfileUrl -ErrorAction Stop

        # Ensure $PROFILE file exists for comparison
        $currentContent = if (Test-Path $PROFILE) {
            Get-Content $PROFILE -Raw -Encoding UTF8
        } else { "" }

        # Normalize line endings for reliable comparison
        $normalize = { param($s) $s.Trim() -replace '\r\n', "`n" }
        $remoteNorm = & $normalize $webContent
        $localNorm  = & $normalize $currentContent

        if ($remoteNorm -eq $localNorm) {
            Write-Host "Profile is up to date." -ForegroundColor Green
            return
        }

        Write-Host "Profile update available!" -ForegroundColor Yellow
        $update = Read-Host "Update profile? (Y/N)"
        if ($update -in @('Y', 'y')) {
            # Back up current profile
            if (Test-Path $PROFILE) {
                $backupPath = "$PROFILE.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $PROFILE $backupPath
                Write-Host "Backup saved to: $backupPath" -ForegroundColor Gray
            }
            $webContent | Set-Content $PROFILE -Force -Encoding UTF8
            Write-Host "Profile updated. Please restart PowerShell." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to check for updates: $_"
    }
}
