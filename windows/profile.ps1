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

# Import additional modules if available
$modules = @('posh-git')
foreach ($module in $modules) {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module $module -ErrorAction SilentlyContinue
    }
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

# Register tab completion for mcconsole
Register-ArgumentCompleter -CommandName mcconsole -ParameterName Server -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    @('mc.mfrozi.xyz', 'localhost') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Winget Upgrade with Admin Privileges
Function wingetupgrade {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()] [switch]$Force,
        [Parameter()] [string[]]$Include,
        [Parameter()] [switch]$SkipIgnoreList,
        [Parameter()] [switch]$DryRun
    )

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required. Launching elevated…"

        $paramParts = @()
        if ($Force)          { $paramParts += '-Force' }
        if ($SkipIgnoreList) { $paramParts += '-SkipIgnoreList' }
        if ($DryRun)         { $paramParts += '-DryRun' }
        if ($Include)        { $paramParts += "-Include @('$($Include -join "','")')" }
        $paramString = $paramParts -join ' '

        $commandToRun = ". '$PROFILE'; wingetupgrade $paramString"
        $bytes = [Text.Encoding]::Unicode.GetBytes($commandToRun)
        $encodedCommand = [Convert]::ToBase64String($bytes)

        Start-Process wt -Verb RunAs -ArgumentList "-- pwsh -NoExit -EncodedCommand $encodedCommand"
        return
    }

    Write-Host "Running with Administrator privileges." -ForegroundColor Green

    if (-not $PSCmdlet.ShouldProcess("System", "Check and upgrade winget packages")) {
        return
    }

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

    $packages = [System.Collections.Generic.List[object]]::new()

    try {
        $jsonOutput = & winget upgrade --include-unknown --accept-source-agreements --output json 2>$null
        if ($jsonOutput) {
            $items = $jsonOutput | ConvertFrom-Json
            foreach ($item in $items) {
                $id = $item.PackageIdentifier
                if (-not $id) { continue }
                if (-not $SkipIgnoreList -and $id -in $ignorelist) { continue }

                $packages.Add([pscustomobject]@{
                    Name              = $item.PackageName
                    Id                = $id
                    InstalledVersion  = $item.InstalledVersion
                    AvailableVersion  = $item.AvailableVersion
                    Source            = $item.Source
                    Status            = "Pending"
                    ExitCode          = $null
                })
            }
        }
        else {
            throw "empty json"
        }
    }
    catch {
        $updatelist = winget upgrade --include-unknown 2>&1

        $headerIndex = ($updatelist | ForEach-Object { $_.ToString() } |
            Select-String -Pattern '^-{3,}' |
            Select-Object -First 1).LineNumber

        $idPattern = '(?<id>[A-Za-z][A-Za-z0-9-]*\.[A-Za-z0-9\.\-]+)'

        foreach ($line in $updatelist[($headerIndex)..($updatelist.Count - 1)]) {
            if ($line -match $idPattern) {
                $id = $Matches['id']
                if (-not $SkipIgnoreList -and $id -in $ignorelist) { continue }

                $packages.Add([pscustomobject]@{
                    Name              = $id
                    Id                = $id
                    InstalledVersion  = $null
                    AvailableVersion  = $null
                    Source            = $null
                    Status            = "Pending"
                    ExitCode          = $null
                })
            }
        }
    }

    if ($Include) {
        foreach ($pkg in $Include) {
            if ($pkg -notin $packages.Id) {
                $packages.Add([pscustomobject]@{
                    Name              = $pkg
                    Id                = $pkg
                    InstalledVersion  = $null
                    AvailableVersion  = $null
                    Source            = $null
                    Status            = "Pending"
                    ExitCode          = $null
                })
            }
        }
    }

    if ($packages.Count -eq 0) {
        Write-Host "✓ No new software updates to install." -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "Packages found:" -ForegroundColor Yellow
    $packages | Sort-Object Name | Format-Table `
        @{Label="Name"; Expression={$_.Name}; Width=28}, `
        @{Label="Id"; Expression={$_.Id}; Width=35}, `
        @{Label="Installed"; Expression={ if ($_.InstalledVersion) { $_.InstalledVersion } else { "-" } }; Width=14}, `
        @{Label="Available"; Expression={ if ($_.AvailableVersion) { $_.AvailableVersion } else { "-" } }; Width=14}, `
        @{Label="Source"; Expression={ if ($_.Source) { $_.Source } else { "-" } }; Width=10} `
        -AutoSize

    if ($DryRun) {
        Write-Host ""
        Write-Host "[DRY RUN] No changes made." -ForegroundColor Magenta
        return
    }

    if (-not $Force) {
        $confirm = Read-Host "`nProceed with these upgrades? (Y/N)"
        if ($confirm -notin @('Y', 'y')) {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }

    Write-Host ""
    Write-Host "Starting upgrades…" -ForegroundColor Cyan

    $successCount = 0
    $failedPackages = [Collections.Generic.List[object]]::new()

    for ($i = 0; $i -lt $packages.Count; $i++) {
        $pkg = $packages[$i]
        $percent = [math]::Round((($i + 1) / $packages.Count) * 100)

        Write-Progress -Activity "Upgrading Packages" -Status "Processing $($pkg.Id) ($($i + 1)/$($packages.Count))" -PercentComplete $percent
        Write-Host ""
        Write-Host "[$($i + 1)/$($packages.Count)] Upgrading $($pkg.Name) [$($pkg.Id)]" -ForegroundColor Cyan

        & winget upgrade --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
        $pkg.ExitCode = $LASTEXITCODE

        if ($LASTEXITCODE -eq 0) {
            $pkg.Status = "Success"
            Write-Host "  OK" -ForegroundColor Green
            $successCount++
        }
        else {
            $pkg.Status = "Failed"
            Write-Warning "  Failed with exit code $LASTEXITCODE"
            $failedPackages.Add($pkg)
        }
    }

    Write-Progress -Activity "Upgrading Packages" -Completed

    $failCount = $failedPackages.Count

    Write-Host ""
    Write-Host "Summary" -ForegroundColor Cyan
    Write-Host "  Total packages   : $($packages.Count)" -ForegroundColor White
    Write-Host "  Successful       : $successCount" -ForegroundColor Green
    Write-Host "  Failed           : $failCount" -ForegroundColor Red

    if ($failCount -gt 0) {
        Write-Host ""
        Write-Host "Failed packages:" -ForegroundColor Red
        $failedPackages | ForEach-Object {
            Write-Host "  - $($_.Name) [$($_.Id)] (exit $($_.ExitCode))" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Detailed results:" -ForegroundColor Yellow
    $packages | Select-Object Name, Id, InstalledVersion, AvailableVersion, Status | Format-Table -AutoSize

    $logPath = Join-Path $env:TEMP "winget-upgrade-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    @"
Winget Upgrade - $(Get-Date)
Total packages: $($packages.Count)
Successful: $successCount
Failed: $failCount

Results:
$($packages | ForEach-Object { "$($_.Status) | $($_.Name) | $($_.Id) | $($_.InstalledVersion) -> $($_.AvailableVersion) | Exit: $($_.ExitCode)" } | Out-String)
"@ | Set-Content $logPath -Encoding UTF8

    Write-Host "Log saved to: $logPath" -ForegroundColor Gray
}
# Helper function to check for profile updates
Function Update-Profile {
    [CmdletBinding()]
    param(
        [string]$ProfileUrl = "https://raw.githubusercontent.com/MF-Rozi/.dotfiles/main/windows/profile.ps1",
        [switch]$Force
    )

    $cacheFile = Join-Path $env:TEMP "profile-check.txt"
    $cacheExpiry = (Get-Date).AddHours(-24)
    
    if (-not $Force -and (Test-Path $cacheFile)) {
        $lastCheck = Get-Item $cacheFile | Select-Object -ExpandProperty LastWriteTime
        if ($lastCheck -gt $cacheExpiry) {
            Write-Verbose "Profile check skipped (last checked: $lastCheck). Use -Force to override."
            return
        }
    }

    try {
        $webContent = Invoke-RestMethod -Uri $ProfileUrl -TimeoutSec 5 -ErrorAction Stop
        "checked" | Set-Content $cacheFile -Force

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
