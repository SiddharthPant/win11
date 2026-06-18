#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Wait-Winget
Invoke-NativeCommand `
    -Label "Updating winget sources" `
    -FilePath winget `
    -ArgumentList @('source', 'update', '--disable-interactivity') | Out-Null

$wingetApps = @(
    'Google.Chrome',
    'Spotify.Spotify',
    'Notion.Notion',
    'Git.Git',
    'Microsoft.VisualStudioCode',
    'Microsoft.PowerShell',
    'Docker.DockerDesktop',
    'Microsoft.PowerToys',
    'voidtools.Everything',
    'M2Team.NanaZip',
    'SumatraPDF.SumatraPDF',
    'ShareX.ShareX'
)

foreach ($id in $wingetApps) {
    Invoke-NativeCommand `
        -Label "Installing $id" `
        -FilePath winget `
        -ArgumentList @('install', '--id', $id, '-e', '--source', 'winget', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity') | Out-Null
}
