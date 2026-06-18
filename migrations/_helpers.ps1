# Shared helpers for setup migrations.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [string[]] $ArgumentList = @(),

        [int[]] $AllowedExitCodes = @(0),

        [string] $Label,

        [switch] $ContinueOnError
    )

    if ($Label) {
        Write-Information -MessageData "$Label ..." -InformationAction Continue
    }

    & $FilePath @ArgumentList
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

    if ($AllowedExitCodes -notcontains $exitCode) {
        $displayName = if ($Label) { $Label } else { $FilePath }
        $message = "$displayName failed with exit code $exitCode."
        if ($ContinueOnError) {
            Write-Information -MessageData $message -InformationAction Continue
        } else {
            throw $message
        }
    }

    return $exitCode
}

function Wait-Winget {
    param(
        [int] $Attempts = 30,
        [int] $DelaySeconds = 10
    )

    Write-Information -MessageData "Waiting for winget to become available..." -InformationAction Continue
    for ($i = 0; $i -lt $Attempts; $i++) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            return
        }

        Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "winget is unavailable. Open Microsoft Store, let App Installer update, then re-run migrations."
}
