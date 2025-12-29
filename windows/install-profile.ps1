# PowerShell Profile Installation Script
# This script installs the PowerShell profile and its dependencies

Write-Host "Installing PowerShell Profile..." -ForegroundColor Cyan

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceProfile = Join-Path $scriptDir "profile.ps1"

# Check if source profile exists
if (-not (Test-Path $sourceProfile)) {
    Write-Host "Error: profile.ps1 not found in $scriptDir" -ForegroundColor Red
    exit 1
}

# Get profile path
$profilePath = $PROFILE
Write-Host "Profile location: $profilePath" -ForegroundColor Yellow

# Create profile directory if it doesn't exist
$profileDir = Split-Path $profilePath
if (-not (Test-Path $profileDir)) {
    Write-Host "Creating profile directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Backup existing profile if it exists
if (Test-Path $profilePath) {
    $backupPath = "$profilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing profile to: $backupPath" -ForegroundColor Yellow
    Copy-Item $profilePath $backupPath
}

# Copy profile
Write-Host "Installing profile..." -ForegroundColor Yellow
Copy-Item $sourceProfile $profilePath -Force

# Set execution policy
Write-Host "Setting execution policy..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "Execution policy set successfully" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set execution policy. You may need to run this as Administrator." -ForegroundColor Yellow
}

# Install Oh-My-Posh
Write-Host "`nInstalling Oh-My-Posh..." -ForegroundColor Yellow
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install JanDeLobbeleer.OhMyPosh -s winget
} else {
    Write-Host "winget not found. Installing via PowerShell module..." -ForegroundColor Yellow
    Install-Module oh-my-posh -Scope CurrentUser -Force
}

# Optional: Install Terminal-Icons
Write-Host "`nDo you want to install Terminal-Icons module? (Y/N)" -ForegroundColor Cyan
$response = Read-Host
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "Installing Terminal-Icons..." -ForegroundColor Yellow
    Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
    Write-Host "Terminal-Icons installed" -ForegroundColor Green
}

# Optional: Install PSReadLine
Write-Host "`nDo you want to update PSReadLine module? (Y/N)" -ForegroundColor Cyan
$response = Read-Host
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "Installing PSReadLine..." -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Repository PSGallery -Scope CurrentUser -Force -AllowPrerelease
    Write-Host "PSReadLine installed" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "PowerShell Profile Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "`nPlease restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
