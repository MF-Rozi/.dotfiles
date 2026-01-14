# Oh-My-Posh prompt theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# Environment variables
$env:EDITOR = "code"

# Unix-like aliases
Set-Alias -Name pwd -Value Get-Location

# Connect to Minecraft Console
Function mcconsole(){
	$passwordencrypt = Read-Host –AsSecureString -Prompt 'Input the Password'
	$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordencrypt))
	plink -t -ssh mfrozi@mc.mfrozi.xyz -pw $password screen -x mcserver
}