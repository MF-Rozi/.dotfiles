# Oh-My-Posh prompt theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# Environment variables
$env:EDITOR = "code"

# Unix-like aliases
Set-Alias -Name pwd -Value Get-Location

# Connect to Minecraft Console
Function mcconsole {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Server = "mc.mfrozi.xyz",
        
        [Parameter()]
        [string]$User = "mfrozi",
        
        [Parameter()]
        [string]$ScreenSession = "mcserver"
    )
    
    try {
        # Check if plink is available first
        if (-not (Get-Command plink -ErrorAction SilentlyContinue)) {
            Write-Error "plink not found. Please install PuTTY tools from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"
            return
        }
        
        $passwordencrypt = Read-Host -AsSecureString -Prompt "Enter SSH password for $User@${Server}"
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordencrypt))
        
        Write-Host "Connecting to $Server..." -ForegroundColor Cyan
        plink -t -ssh "$User@$Server" -pw $password screen -x $ScreenSession
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Connection failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to connect: $_"
    }
    finally {
        # Securely clear password from memory
        if ($password) { 
            $password = $null
            Remove-Variable password -ErrorAction SilentlyContinue
        }
        if ($passwordencrypt) {
            $passwordencrypt.Dispose()
        }
        [System.GC]::Collect()
    }
}
# Winget Upgrade with Admin Privileges
Function wingetupgrade {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [string[]]$Include,
        
        [Parameter()]
        [switch]$SkipIgnoreList
    )
    
    # --- Administrator Check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required. Launching in an elevated Windows Terminal..."
        
        $paramString = if ($Force) { "-Force" } else { "" }
        $commandToRun = ". '$PROFILE'; wingetupgrade $paramString"
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($commandToRun)
        $encodedCommand = [Convert]::ToBase64String($bytes)
        
        Start-Process wt -Verb RunAs -ArgumentList "-- powershell -NoExit -EncodedCommand $encodedCommand"
        return
    }
    
    # --- Main Logic ---
    Write-Host "Running with Administrator privileges." -ForegroundColor Green

    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget not found. Please install App Installer from Microsoft Store."
        return
    }

    $ignorelist = @(
        "LeNgocKhoa.Laragon",
        "Discord.Discord",
        "Initex.YogaDNS",
        "Spicetify.Spicetify"
    )

    try {
        Write-Host "Checking for updates..." -ForegroundColor Cyan
        $updatelist = winget upgrade --include-unknown 2>&1
    }
    catch {
        Write-Error "Failed to run 'winget upgrade': $_"
        return
    }

    # Parse package IDs from output
    $idlist = [System.Collections.Generic.List[string]]::new()
    $idPattern = '(?<id>[A-Za-z][A-Za-z0-9-]*\.[A-Za-z0-9\.-]+)'

    foreach ($line in $updatelist) {
        if ($line -match $idPattern) {
            $id = $Matches['id']
            
            # Skip if in ignore list (unless SkipIgnoreList is set)
            if (-not $SkipIgnoreList -and $id -in $ignorelist) {
                continue
            }
            
            # Add if not already in list
            if ($id -notin $idlist) {
                $idlist.Add($id)
            }
        }
    }

    # Add specific packages if requested
    if ($Include) {
        foreach ($pkg in $Include) {
            if ($pkg -notin $idlist) {
                $idlist.Add($pkg)
            }
        }
    }

    if ($idlist.Count -eq 0) {
        Write-Host "✓ No new software updates to install." -ForegroundColor Green
        return
    }

    Write-Host "`n--- The following $($idlist.Count) package(s) will be upgraded ---" -ForegroundColor Yellow
    $idlist | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }

    # Confirmation unless -Force is used
    if (-not $Force) {
        $confirm = Read-Host "`nProceed with upgrades? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') {
            Write-Host "Upgrade cancelled." -ForegroundColor Yellow
            return
        }
    }

    Write-Host "`n--- Starting Upgrades ---" -ForegroundColor Cyan
    $successCount = 0
    $failCount = 0
    $failedPackages = [System.Collections.Generic.List[string]]::new()

    foreach ($id in $idlist) {
        Write-Host "`n[$($idlist.IndexOf($id) + 1)/$($idlist.Count)] Upgrading $id..." -ForegroundColor Cyan
        
        $upgradeArgs = @(
            'upgrade'
            '--id', $id
            '--accept-package-agreements'
            '--accept-source-agreements'
            '--silent'
        )
        
        $result = & winget @upgradeArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $id upgraded successfully" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Warning "  ✗ Failed to upgrade $id (Exit code: $LASTEXITCODE)"
            $failCount++
            $failedPackages.Add($id)
        }
    }

    # Summary
    Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
    Write-Host "Upgrade Summary" -ForegroundColor Cyan
    Write-Host "$('=' * 50)" -ForegroundColor Cyan
    Write-Host "  Total packages: $($idlist.Count)" -ForegroundColor White
    Write-Host "  ✓ Success: $successCount" -ForegroundColor Green
    
    if ($failCount -gt 0) {
        Write-Host "  ✗ Failed: $failCount" -ForegroundColor Red
        Write-Host "`nFailed packages:" -ForegroundColor Yellow
        $failedPackages | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    }
    
    Write-Host "$('=' * 50)" -ForegroundColor Cyan
    
    # Log to file
    $logPath = "$env:TEMP\winget-upgrade-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $logContent = @"
Winget Upgrade Log - $(Get-Date)
Total: $($idlist.Count) | Success: $successCount | Failed: $failCount

Upgraded Packages:
$($idlist -join "`n")

$(if ($failedPackages.Count -gt 0) { "Failed Packages:`n$($failedPackages -join "`n")" })
"@
    $logContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Host "`nLog saved to: $logPath" -ForegroundColor Gray
}