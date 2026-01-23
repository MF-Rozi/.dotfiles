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
## Winget Upgrade with Admin Privileges
Function wingetupgrade() {
    # --- Administrator Check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Administrator privileges required. Launching in an elevated Windows Terminal..."
        
        $commandToRun = ". '$PROFILE'; wingetupgrade"
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
        $updatelist = winget upgrade 2>&1
    }
    catch {
        Write-Error "Failed to run 'winget upgrade': $_"
        return
    }

    $idlist = @()
    $idPattern = '[A-Za-z][A-Za-z0-9-]*\.[A-Za-z0-9\.-]+'

    foreach ($line in $updatelist) {
        $allMatches = $line | Select-String -Pattern $idPattern -AllMatches
        if ($allMatches) {
            $id = $allMatches.Matches[-1].Value
            
            if ($id -notin $ignorelist) {
                $idlist += $id
            }
        }
    }

    # Remove duplicates
    $idlist = $idlist | Select-Object -Unique

    if ($idlist.Count -eq 0) {
        Write-Host "✓ No new software updates to install." -ForegroundColor Green
        return
    }

    Write-Host "`n--- The following $($idlist.Count) package(s) will be upgraded ---" -ForegroundColor Yellow
    $idlist | ForEach-Object { Write-Host "  • $_" }

    Write-Host "`n--- Starting Upgrades ---" -ForegroundColor Cyan
    $successCount = 0
    $failCount = 0

    foreach ($id in $idlist) {
        Write-Host "`nUpgrading $id..." -ForegroundColor Cyan
        
        $result = winget upgrade --id $id --accept-package-agreements --accept-source-agreements --silent 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $id upgraded successfully" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Warning "  ✗ Failed to upgrade $id"
            $failCount++
        }
    }

    Write-Host "`n--- Upgrade Summary ---" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    if ($failCount -gt 0) {
        Write-Host "  Failed: $failCount" -ForegroundColor Red
    }
    Write-Host "--- All upgrades complete! ---" -ForegroundColor Green
}