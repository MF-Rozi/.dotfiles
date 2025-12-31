# PowerShell Profile Installation Script
# This script installs the PowerShell profile and its dependencies

param(
    [switch]$SkipOhMyPosh,
    [switch]$SkipBackup,
    [switch]$InstallTerminalIcons,
    [switch]$InstallPSReadLine,
    [switch]$NoPrompt,
    [string]$ProfileSource = "",
    [switch]$Help
)

# Show help
if ($Help) {
    Write-Host @"
PowerShell Profile Installation Script

Usage: .\install-profile.ps1 [options]

Options:
  -SkipOhMyPosh          Skip Oh-My-Posh installation
  -SkipBackup            Skip backing up existing profile
  -InstallTerminalIcons  Install Terminal-Icons module
  -InstallPSReadLine     Install/Update PSReadLine module
  -NoPrompt              Install without prompting for optional modules
  -ProfileSource <path>  Specify custom profile.ps1 path
  -Help                  Show this help message

Examples:
  .\install-profile.ps1
  .\install-profile.ps1 -NoPrompt -InstallTerminalIcons
  .\install-profile.ps1 -SkipOhMyPosh -SkipBackup
"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "Installing PowerShell Profile..." -ForegroundColor Cyan

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine source profile path
if ($ProfileSource) {
    $sourceProfile = $ProfileSource
} else {
    $sourceProfile = Join-Path $scriptDir "profile.ps1"
}

# Check if source profile exists
if (-not (Test-Path $sourceProfile)) {
    Write-Host "Error: profile.ps1 not found at $sourceProfile" -ForegroundColor Red
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
if ((Test-Path $profilePath) -and -not $SkipBackup) {
    $backupPath = "$profilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing profile to: $backupPath" -ForegroundColor Yellow
    Copy-Item $profilePath $backupPath
} elseif ((Test-Path $profilePath) -and $SkipBackup) {
    Write-Host "Skipping backup (as requested)" -ForegroundColor Yellow
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
if (-not $SkipOhMyPosh) {
    Write-Host "`nInstalling Oh-My-Posh..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install JanDeLobbeleer.OhMyPosh -s winget
    } else {
        Write-Host "winget not found. Installing via PowerShell module..." -ForegroundColor Yellow
        Install-Module oh-my-posh -Scope CurrentUser -Force
    }
} else {
    Write-Host "`nSkipping Oh-My-Posh installation (as requested)" -ForegroundColor Yellow
    Write-Host "winget not found. Installing via PowerShell module..." -ForegroundColor Yellow
if ($InstallTerminalIcons) {
    Write-Host "`nInstalling Terminal-Icons..." -ForegroundColor Yellow
    Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
    Write-Host "Terminal-Icons installed" -ForegroundColor Green
} elseif (-not $NoPrompt) {
    Write-Host "`nDo you want to install Terminal-Icons module? (Y/N)" -ForegroundColor Cyan
    $response = Read-Host
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Installing Terminal-Icons..." -ForegroundColor Yellow
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
        Write-Host "Terminal-Icons installed" -ForegroundColor Green
    }
}

# Optional: Install PSReadLine
if ($InstallPSReadLine) {
    Write-Host "`nInstalling PSReadLine..." -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Repository PSGallery -Scope CurrentUser -Force -AllowPrerelease
    Write-Host "PSReadLine installed" -ForegroundColor Green
} elseif (-not $NoPrompt) {
    Write-Host "`nDo you want to update PSReadLine module? (Y/N)" -ForegroundColor Cyan
    $response = Read-Host
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Installing PSReadLine..." -ForegroundColor Yellow
        Install-Module -Name PSReadLine -Repository PSGallery -Scope CurrentUser -Force -AllowPrerelease
        Write-Host "PSReadLine installed" -ForegroundColor Green
    }
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "Installing PSReadLine..." -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Repository PSGallery -Scope CurrentUser -Force -AllowPrerelease
    Write-Host "PSReadLine installed" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "PowerShell Profile Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "`nPlease restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
