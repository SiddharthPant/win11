<#
  Applies pending setup migrations from the migrations/ directory.

  This intentionally mirrors the useful part of Omarchy's migration pattern:
  scripts are ordered by filename, successful runs are recorded, and there is no
  rollback path. Keep individual migrations small and safe to re-run after a
  partial failure.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string] $MigrationPath = (Join-Path $PSScriptRoot 'migrations'),
    [string] $StatePath = (Join-Path $env:ProgramData 'Win11Setup\migrations.json'),
    [switch] $List
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-EmptyState {
    [pscustomobject]@{
        version = 1
        applied = @()
    }
}

function Read-MigrationState {
    param([string] $Path)

    if (-not (Test-Path $Path)) {
        return Get-EmptyState
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return Get-EmptyState
    }

    $state = $raw | ConvertFrom-Json
    if (-not ($state.PSObject.Properties.Name -contains 'version')) {
        $state | Add-Member -NotePropertyName version -NotePropertyValue 1
    }
    if (-not ($state.PSObject.Properties.Name -contains 'applied')) {
        $state | Add-Member -NotePropertyName applied -NotePropertyValue @()
    }
    if ($null -eq $state.applied) {
        $state.applied = @()
    }

    return $state
}

function Save-MigrationState {
    param(
        [Parameter(Mandatory = $true)]
        $State,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $dir = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $tmp = "$Path.tmp"
    $State | ConvertTo-Json -Depth 6 | Set-Content -Path $tmp -Encoding UTF8
    Move-Item -Path $tmp -Destination $Path -Force
}

function Get-AppliedMap {
    param($State)

    $map = @{}
    foreach ($entry in @($State.applied)) {
        if ($entry.PSObject.Properties.Name -contains 'name') {
            $map[$entry.name] = $entry
        }
    }

    return $map
}

if (-not (Test-Path $MigrationPath)) {
    New-Item -ItemType Directory -Path $MigrationPath -Force | Out-Null
}

$state = Read-MigrationState -Path $StatePath
$applied = Get-AppliedMap -State $state
$migrations = Get-ChildItem -Path $MigrationPath -File -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '_*' } |
    Sort-Object Name

if ($List) {
    foreach ($migration in $migrations) {
        $status = if ($applied.ContainsKey($migration.Name)) { 'applied' } else { 'pending' }
        Write-Information -MessageData ("{0,-8} {1}" -f $status, $migration.Name) -InformationAction Continue
    }
    return
}

if (-not $migrations) {
    Write-Information -MessageData "No migrations found in $MigrationPath." -InformationAction Continue
    Save-MigrationState -State $state -Path $StatePath
    return
}

$powershellCommand = Get-Command powershell.exe -ErrorAction SilentlyContinue
$powershellExe = if ($powershellCommand) { $powershellCommand.Source } else { (Get-Process -Id $PID).Path }

foreach ($migration in $migrations) {
    $hash = (Get-FileHash -Algorithm SHA256 -Path $migration.FullName).Hash.ToLowerInvariant()

    if ($applied.ContainsKey($migration.Name)) {
        $entry = $applied[$migration.Name]
        if (($entry.PSObject.Properties.Name -contains 'sha256') -and $entry.sha256 -and ($entry.sha256 -ne $hash)) {
            Write-Warning "Applied migration changed on disk: $($migration.Name)"
        }
        continue
    }

    Write-Information -MessageData "`nRunning migration $($migration.BaseName)..." -InformationAction Continue
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $migration.FullName
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    $timer.Stop()

    if ($exitCode -ne 0) {
        throw "Migration $($migration.Name) failed with exit code $exitCode."
    }

    $state.applied = @($state.applied) + [pscustomobject]@{
        name = $migration.Name
        sha256 = $hash
        appliedAt = (Get-Date).ToUniversalTime().ToString('o')
        durationSeconds = [math]::Round($timer.Elapsed.TotalSeconds, 3)
    }
    Save-MigrationState -State $state -Path $StatePath
    $applied = Get-AppliedMap -State $state

    Write-Information -MessageData "Applied $($migration.Name)." -InformationAction Continue
}

Write-Information -MessageData "`nMigrations complete. State: $StatePath" -InformationAction Continue
