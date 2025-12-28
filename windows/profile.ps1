# Oh-My-Posh prompt theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# Environment variables
$env:EDITOR = "code"

# Unix-like aliases
Set-Alias -Name pwd -Value Get-Location