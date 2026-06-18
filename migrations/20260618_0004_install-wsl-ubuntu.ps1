#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Invoke-NativeCommand `
    -Label "Installing WSL (Ubuntu)" `
    -FilePath wsl `
    -AllowedExitCodes @(0, 3010) `
    -ArgumentList @('--install', '--distribution', 'Ubuntu', '--no-launch') | Out-Null
