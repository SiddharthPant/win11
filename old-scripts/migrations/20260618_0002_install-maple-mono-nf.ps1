#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Write-Information -MessageData "Installing Maple Mono NF font..." -InformationAction Continue

$release = Invoke-RestMethod `
    -Uri 'https://api.github.com/repos/subframe7536/maple-font/releases/latest' `
    -Headers @{ 'User-Agent' = 'win11-setup' }
$asset = $release.assets | Where-Object { $_.name -eq 'MapleMono-NF.zip' } | Select-Object -First 1

if (-not $asset) {
    throw "MapleMono-NF.zip not found in the latest maple-font release."
}

$zip = Join-Path $env:TEMP 'MapleMono-NF.zip'
$dir = Join-Path $env:TEMP 'MapleMono-NF'

if (Test-Path $dir) {
    Remove-Item $dir -Recurse -Force
}

Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $dir -Force

$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
Get-ChildItem -Path $dir -Recurse -Include *.ttf | ForEach-Object {
    $target = Join-Path $env:WINDIR "Fonts\$($_.Name)"
    if (-not (Test-Path $target)) {
        $fonts.CopyHere($_.FullName, 0x10)
    }
}
