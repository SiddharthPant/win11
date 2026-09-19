#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Wait-Winget

# Fresh Windows images can ship an older App Installer/winget client that fails on
# some current manifests. Treat "no applicable update" as success.
Invoke-NativeCommand `
    -Label "Updating App Installer / winget" `
    -FilePath winget `
    -ArgumentList @('upgrade', '--id', 'Microsoft.AppInstaller', '-e', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') `
    -AllowedExitCodes @(0, -1978335189, -1978335153) | Out-Null
