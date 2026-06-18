#Requires -Version 5.1
#Requires -RunAsAdministrator

. (Join-Path $PSScriptRoot '_helpers.ps1')

function Get-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ($InputObject.PSObject.Properties.Name -notcontains $Name) {
        $InputObject | Add-Member -MemberType NoteProperty -Name $Name -Value ([pscustomobject]@{})
    }

    return $InputObject.$Name
}

function Write-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($InputObject.PSObject.Properties.Name -contains $Name) {
        $InputObject.$Name = $Value
    } else {
        $InputObject | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Read-TerminalSetting {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path $Path)) {
        return [pscustomobject][ordered]@{
            '$schema' = 'https://aka.ms/terminal-profiles-schema'
            profiles = [pscustomobject][ordered]@{
                defaults = [pscustomobject]@{}
                list = @()
            }
        }
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject][ordered]@{
            '$schema' = 'https://aka.ms/terminal-profiles-schema'
            profiles = [pscustomobject][ordered]@{
                defaults = [pscustomobject]@{}
                list = @()
            }
        }
    }

    try {
        return $raw | ConvertFrom-Json
    } catch {
        $withoutFullLineComments = ($raw -split "`r?`n" | Where-Object { -not $_.TrimStart().StartsWith('//') }) -join "`n"
        $withoutTrailingCommas = [regex]::Replace($withoutFullLineComments, ',(\s*[}\]])', '$1')

        try {
            return $withoutTrailingCommas | ConvertFrom-Json
        } catch {
            $backupPath = "$Path.unparsed.$((Get-Date).ToString('yyyyMMddHHmmss')).bak"
            Copy-Item -LiteralPath $Path -Destination $backupPath -Force
            throw "Unable to parse Windows Terminal settings JSON. Backed it up to $backupPath. Error: $($_.Exception.Message)"
        }
    }
}

$terminalPackageNames = @(
    'Microsoft.WindowsTerminal_8wekyb3d8bbwe',
    'Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe'
)

$localAppData = $env:LOCALAPPDATA
if ([string]::IsNullOrWhiteSpace($localAppData)) {
    throw "LOCALAPPDATA is not set."
}

$settingsPath = $null
foreach ($packageName in $terminalPackageNames) {
    $candidateDir = Join-Path $localAppData "Packages\$packageName\LocalState"
    if (Test-Path (Split-Path -Parent $candidateDir)) {
        New-Item -ItemType Directory -Path $candidateDir -Force | Out-Null
        $settingsPath = Join-Path $candidateDir 'settings.json'
        break
    }
}

if (-not $settingsPath) {
    $candidateDir = Join-Path $localAppData 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
    New-Item -ItemType Directory -Path $candidateDir -Force | Out-Null
    $settingsPath = Join-Path $candidateDir 'settings.json'
}

$settings = Read-TerminalSetting -Path $settingsPath
$profiles = Get-ObjectProperty -InputObject $settings -Name 'profiles'
$defaults = Get-ObjectProperty -InputObject $profiles -Name 'defaults'
$font = Get-ObjectProperty -InputObject $defaults -Name 'font'

Write-ObjectProperty -InputObject $font -Name 'face' -Value 'Maple Mono NF'
Write-ObjectProperty -InputObject $font -Name 'size' -Value 11
Write-ObjectProperty -InputObject $settings -Name 'defaultProfile' -Value '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
Write-ObjectProperty -InputObject $settings -Name 'copyOnSelect' -Value $false
Write-ObjectProperty -InputObject $settings -Name 'copyFormatting' -Value $false

$profileList = @($profiles.list | Where-Object { $null -ne $_ })
$powershellProfile = $profileList | Where-Object { $_.guid -eq '{574e775e-4f2a-5b96-ac1e-a2962a402336}' } | Select-Object -First 1
if ($powershellProfile) {
    Write-ObjectProperty -InputObject $powershellProfile -Name 'name' -Value 'PowerShell'
    Write-ObjectProperty -InputObject $powershellProfile -Name 'source' -Value 'Windows.Terminal.PowershellCore'
} else {
    $profileList += [pscustomobject][ordered]@{
        guid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
        name = 'PowerShell'
        source = 'Windows.Terminal.PowershellCore'
    }
}
Write-ObjectProperty -InputObject $profiles -Name 'list' -Value @($profileList)

if (Test-Path $settingsPath) {
    $currentJson = Get-Content -LiteralPath $settingsPath -Raw
} else {
    $currentJson = ''
}

$newJson = $settings | ConvertTo-Json -Depth 32

if ($currentJson.TrimEnd("`r", "`n") -eq $newJson.TrimEnd("`r", "`n")) {
    Write-Information -MessageData "Windows Terminal settings already match desired state; skipping write." -InformationAction Continue
    return
}

if (Test-Path $settingsPath) {
    Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak" -Force
}

$newJson | Set-Content -LiteralPath $settingsPath -Encoding UTF8

Write-Information -MessageData "Windows Terminal configured at $settingsPath." -InformationAction Continue
