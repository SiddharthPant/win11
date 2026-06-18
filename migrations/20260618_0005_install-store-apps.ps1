#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Wait-Winget

$storeApps = @(
    @{ id = '9NKSQGP7F2NH'; name = 'WhatsApp' },
    @{ id = '9WZDNCRFJ3TJ'; name = 'Netflix' }
)

foreach ($app in $storeApps) {
    Install-WingetPackage -Id $app.id -Source 'msstore' -Name "$($app.name) (Store)"
}
