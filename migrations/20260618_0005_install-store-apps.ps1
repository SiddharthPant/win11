#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Wait-Winget

$storeApps = @(
    @{ id = '9NKSQGP7F2NH'; name = 'WhatsApp' },
    @{ id = '9WZDNCRFJ3TJ'; name = 'Netflix' }
)

foreach ($app in $storeApps) {
    Invoke-NativeCommand `
        -Label "Installing $($app.name) (Store)" `
        -FilePath winget `
        -ArgumentList @('install', '--id', $app.id, '--source', 'msstore', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') | Out-Null
}
