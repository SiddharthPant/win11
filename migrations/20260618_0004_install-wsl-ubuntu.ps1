#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

$installedDistributions = @(
    & wsl --list --quiet 2>$null |
        ForEach-Object { ($_ -replace "`0", '').Trim() } |
        Where-Object { $_ }
)

if ($installedDistributions | Where-Object { $_ -like 'Ubuntu*' } | Select-Object -First 1) {
    Write-Information -MessageData "Ubuntu WSL distribution is already installed; skipping." -InformationAction Continue
    return
}

Invoke-NativeCommand `
    -Label "Installing WSL (Ubuntu)" `
    -FilePath wsl `
    -AllowedExitCodes @(0, 3010) `
    -ArgumentList @('--install', '--distribution', 'Ubuntu', '--no-launch') | Out-Null
