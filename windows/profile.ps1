# Oh-My-Posh prompt theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# Environment variables
$env:EDITOR = "code"

# Unix-like aliases
Set-Alias -Name pwd -Value Get-Location

# Connect to Minecraft Console
Function mcconsole(){
	try {
        $passwordencrypt = Read-Host -AsSecureString -Prompt 'Input the Password'
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordencrypt))
        
        # Check if plink is available
        if (-not (Get-Command plink -ErrorAction SilentlyContinue)) {
            Write-Error "plink not found. Please install PuTTY tools."
            return
        }
        
        plink -t -ssh mfrozi@mc.mfrozi.xyz -pw $password screen -x mcserver
    }
    catch {
        Write-Error "Failed to connect: $_"
    }
    finally {
        # Clear password from memory
        if ($password) { 
            Remove-Variable password -ErrorAction SilentlyContinue
        }
    }
}
# Winget Upgrade with Admin Privileges
Function wingetupgrade(){

  # --- Administrator Check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

  if (-not $isAdmin) {
    # Not Admin: Re-launch in a new, elevated Windows Terminal window
    Write-Warning "Administrator privileges required. Launching in an elevated Windows Terminal..."
        
    # Define the command to run in the new terminal.
    # Using single quotes around $PROFILE handles potential spaces in the path.
    $commandToRun = ". '$PROFILE'; wingetupgrade"
        
    # Convert the command to a Base64 string to avoid any command-line parsing errors.
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($commandToRun)
    $encodedCommand = [Convert]::ToBase64String($bytes)
        
    # Launch the new terminal using the -EncodedCommand parameter
     Start-Process wt -Verb RunAs -ArgumentList "-- powershell -NoExit -EncodedCommand $encodedCommand"
        
    return # Stop the current non-admin function
  }
    
  # --- Main Logic (runs only when admin) ---
  Write-Host "Running with Administrator privileges." -ForegroundColor Green


  $ignorelist = @(
    "LeNgocKhoa.Laragon",
    "Discord.Discord",
    "Initex.YogaDNS",
    "Spicetify.Spicetify" #this needed to run on non elevated mode
  )

  try {
      $updatelist = winget upgrade
  } catch {
    Write-Error "Failed to run 'winget upgrade'. Make sure winget is installed and working."
    return
  }
  $idlist = @()

  $idPattern = '[A-Za-z][A-Za-z0-9-]*\.[A-Za-z0-9\.-]+'

  foreach ($line in $updatelist) {

    $allMatches = $line | Select-String -Pattern $idPattern -AllMatches
      if($allMatches){
        $id = $allMatches.Matches[-1].Value
        
        if($id -in $ignorelist){
          continue
        }
        $idlist += $id
      }
  }

  if ($idlist.Count -eq 0) {
    Write-Host "No new software updates to install."
    return
  }

  Write-Host "--- The following packages will be upgraded ---"
  $idList

  Write-Host "--- Upgrading ---"
  foreach ($id in $idlist) {
    Write-Host "Upgrading $id..."
        winget upgrade --id $id --accept-package-agreements --accept-source-agreements --silent
  }
  Write-Host "--- All upgrades complete! ---" -ForegroundColor Green
}