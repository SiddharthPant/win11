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
    Install-WingetPackage -Id $id
}
