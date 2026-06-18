#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

Write-Information -MessageData "Setting Chrome as default browser..." -InformationAction Continue

$ftaZip = Join-Path $env:TEMP 'SetUserFTA.zip'
$ftaDir = Join-Path $env:TEMP 'SetUserFTA'
$ftaConfig = Join-Path $ftaDir 'chrome-default.fta'

if (Test-Path $ftaDir) {
    Remove-Item $ftaDir -Recurse -Force
}

Invoke-WebRequest -Uri 'https://setuserfta.com/SetUserFTA.zip' -OutFile $ftaZip -UseBasicParsing
Expand-Archive -Path $ftaZip -DestinationPath $ftaDir -Force

$fta = Get-ChildItem -Path $ftaDir -Recurse -Filter SetUserFTA.exe | Select-Object -First 1
if (-not $fta) {
    throw "SetUserFTA.exe not found in downloaded archive."
}

@(
    'http, ChromeHTML'
    'https, ChromeHTML'
    '.htm, ChromeHTML'
    '.html, ChromeHTML'
) | Set-Content -Path $ftaConfig -Encoding ascii

Invoke-NativeCommand `
    -Label "Applying Chrome default associations" `
    -FilePath $fta.FullName `
    -ArgumentList @($ftaConfig) | Out-Null
